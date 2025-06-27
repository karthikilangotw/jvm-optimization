#!/bin/zsh

# Comprehensive JVM Metrics Testing Script
# Captures detailed JVM performance metrics for all Docker configurations

set -e

# Configuration
TEST_DURATION=120  # seconds to run each container (longer for better metrics)
WARMUP_TIME=45     # seconds to wait for application startup and warmup
METRICS_INTERVAL=10 # seconds between metric collections
BASE_PORT=8080
RESULTS_DIR="test-results/comprehensive_jvm_metrics_$(date +%Y%m%d_%H%M%S)"
MEMORY_LIMIT="1g"  # Container memory limit

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create results directory
mkdir -p "$RESULTS_DIR"

echo -e "${BLUE}🚀 Comprehensive JVM Metrics Testing${NC}"
echo "======================================="
echo "Test Duration: ${TEST_DURATION}s per container"
echo "Warmup Time: ${WARMUP_TIME}s"
echo "Metrics Interval: ${METRICS_INTERVAL}s"
echo "Memory Limit: ${MEMORY_LIMIT}"
echo "Results Directory: ${RESULTS_DIR}"
echo ""

# Define Docker configurations
CONFIGS=(
    "main:Dockerfile"
    "traditional:dockerfiles/Dockerfile-traditional"
    "alpine:dockerfiles/Dockerfile-alpine"
    "distroless:dockerfiles/Dockerfile-distroless"
    "jre-slim:dockerfiles/Dockerfile-jre-slim"
    "genzgc:dockerfiles/Dockerfile-genzgc"
    "non-root:dockerfiles/Dockerfile-non-root"
    "miscellaneous:dockerfiles/Dockerfile-miscelleneous"
)

# Initialize comprehensive results file
RESULTS_CSV="${RESULTS_DIR}/comprehensive_metrics.csv"
echo "Configuration,Build_Time,Image_Size_MB,Startup_Time,Container_Memory_MB,Container_CPU_Percent,Heap_Used_MB,Heap_Committed_MB,Heap_Max_MB,NonHeap_Used_MB,NonHeap_Committed_MB,NonHeap_Max_MB,GC_Collections_Total,GC_Time_Total_MS,Thread_Count,Thread_Peak,Thread_Daemon,Classes_Loaded,Classes_Total,Classes_Unloaded,CPU_Process_Percent,CPU_System_Percent,File_Descriptors_Open,File_Descriptors_Max,Eden_Used_MB,Survivor_Used_MB,OldGen_Used_MB,Metaspace_Used_MB,CodeCache_Used_MB,Status" > "$RESULTS_CSV"

# Function to log with timestamp
log() {
    echo -e "[$(date '+%H:%M:%S')] $1"
}

# Function to get JVM metrics from actuator endpoints
get_jvm_metrics() {
    local config_name=$1
    local metrics_file="${RESULTS_DIR}/${config_name}_detailed_metrics.json"
    
    # Initialize metrics with default values
    local heap_used=0 heap_committed=0 heap_max=0
    local nonheap_used=0 nonheap_committed=0 nonheap_max=0
    local gc_collections=0 gc_time=0
    local thread_count=0 thread_peak=0 thread_daemon=0
    local classes_loaded=0 classes_total=0 classes_unloaded=0
    local cpu_process=0 cpu_system=0
    local fd_open=0 fd_max=0
    local eden_used=0 survivor_used=0 oldgen_used=0 metaspace_used=0 codecache_used=0
    
    # Collect various JVM metrics
    log "${YELLOW}  Collecting JVM metrics...${NC}"
    
    # Memory metrics
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.used?tag=area:heap" > /tmp/heap_used.json 2>/dev/null; then
        heap_used=$(cat /tmp/heap_used.json | jq -r '.measurements[0].value // 0' | awk '{print int($1/1024/1024)}')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.committed?tag=area:heap" > /tmp/heap_committed.json 2>/dev/null; then
        heap_committed=$(cat /tmp/heap_committed.json | jq -r '.measurements[0].value // 0' | awk '{print int($1/1024/1024)}')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.max?tag=area:heap" > /tmp/heap_max.json 2>/dev/null; then
        heap_max=$(cat /tmp/heap_max.json | jq -r '.measurements[0].value // 0' | awk '{print int($1/1024/1024)}')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.used?tag=area:nonheap" > /tmp/nonheap_used.json 2>/dev/null; then
        nonheap_used=$(cat /tmp/nonheap_used.json | jq -r '.measurements[0].value // 0' | awk '{print int($1/1024/1024)}')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.committed?tag=area:nonheap" > /tmp/nonheap_committed.json 2>/dev/null; then
        nonheap_committed=$(cat /tmp/nonheap_committed.json | jq -r '.measurements[0].value // 0' | awk '{print int($1/1024/1024)}')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.max?tag=area:nonheap" > /tmp/nonheap_max.json 2>/dev/null; then
        nonheap_max=$(cat /tmp/nonheap_max.json | jq -r '.measurements[0].value // 0' | awk '{print int($1/1024/1024)}')
    fi
    
    # GC metrics
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.gc.pause" > /tmp/gc_pause.json 2>/dev/null; then
        gc_collections=$(cat /tmp/gc_pause.json | jq -r '.measurements[] | select(.statistic=="COUNT") | .value // 0' | head -1)
        gc_time=$(cat /tmp/gc_pause.json | jq -r '.measurements[] | select(.statistic=="TOTAL_TIME") | .value // 0' | head -1 | awk '{print int($1*1000)}')
    fi
    
    # Thread metrics
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.threads.live" > /tmp/threads_live.json 2>/dev/null; then
        thread_count=$(cat /tmp/threads_live.json | jq -r '.measurements[0].value // 0')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.threads.peak" > /tmp/threads_peak.json 2>/dev/null; then
        thread_peak=$(cat /tmp/threads_peak.json | jq -r '.measurements[0].value // 0')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.threads.daemon" > /tmp/threads_daemon.json 2>/dev/null; then
        thread_daemon=$(cat /tmp/threads_daemon.json | jq -r '.measurements[0].value // 0')
    fi
    
    # Class loading metrics
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.classes.loaded" > /tmp/classes_loaded.json 2>/dev/null; then
        classes_loaded=$(cat /tmp/classes_loaded.json | jq -r '.measurements[0].value // 0')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.classes.unloaded" > /tmp/classes_unloaded.json 2>/dev/null; then
        classes_unloaded=$(cat /tmp/classes_unloaded.json | jq -r '.measurements[0].value // 0')
    fi
    
    classes_total=$((classes_loaded + classes_unloaded))
    
    # CPU metrics
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/process.cpu.usage" > /tmp/cpu_process.json 2>/dev/null; then
        cpu_process=$(cat /tmp/cpu_process.json | jq -r '.measurements[0].value // 0' | awk '{print $1*100}')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/system.cpu.usage" > /tmp/cpu_system.json 2>/dev/null; then
        cpu_system=$(cat /tmp/cpu_system.json | jq -r '.measurements[0].value // 0' | awk '{print $1*100}')
    fi
    
    # File descriptor metrics
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/process.files.open" > /tmp/fd_open.json 2>/dev/null; then
        fd_open=$(cat /tmp/fd_open.json | jq -r '.measurements[0].value // 0')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/process.files.max" > /tmp/fd_max.json 2>/dev/null; then
        fd_max=$(cat /tmp/fd_max.json | jq -r '.measurements[0].value // 0')
    fi
    
    # Memory pool metrics (Eden, Survivor, Old Gen, Metaspace, Code Cache)
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.used?tag=id:PS%20Eden%20Space" > /tmp/eden.json 2>/dev/null; then
        eden_used=$(cat /tmp/eden.json | jq -r '.measurements[0].value // 0' | awk '{print int($1/1024/1024)}')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.used?tag=id:PS%20Survivor%20Space" > /tmp/survivor.json 2>/dev/null; then
        survivor_used=$(cat /tmp/survivor.json | jq -r '.measurements[0].value // 0' | awk '{print int($1/1024/1024)}')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.used?tag=id:PS%20Old%20Gen" > /tmp/oldgen.json 2>/dev/null; then
        oldgen_used=$(cat /tmp/oldgen.json | jq -r '.measurements[0].value // 0' | awk '{print int($1/1024/1024)}')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.used?tag=id:Metaspace" > /tmp/metaspace.json 2>/dev/null; then
        metaspace_used=$(cat /tmp/metaspace.json | jq -r '.measurements[0].value // 0' | awk '{print int($1/1024/1024)}')
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.used?tag=id:Code%20Cache" > /tmp/codecache.json 2>/dev/null; then
        codecache_used=$(cat /tmp/codecache.json | jq -r '.measurements[0].value // 0' | awk '{print int($1/1024/1024)}')
    fi
    
    # Save detailed metrics to file
    cat > "$metrics_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "heap": {
        "used": $heap_used,
        "committed": $heap_committed,
        "max": $heap_max
    },
    "nonheap": {
        "used": $nonheap_used,
        "committed": $nonheap_committed,
        "max": $nonheap_max
    },
    "gc": {
        "collections": $gc_collections,
        "time_ms": $gc_time
    },
    "threads": {
        "live": $thread_count,
        "peak": $thread_peak,
        "daemon": $thread_daemon
    },
    "classes": {
        "loaded": $classes_loaded,
        "total": $classes_total,
        "unloaded": $classes_unloaded
    },
    "cpu": {
        "process_percent": $cpu_process,
        "system_percent": $cpu_system
    },
    "file_descriptors": {
        "open": $fd_open,
        "max": $fd_max
    },
    "memory_pools": {
        "eden_mb": $eden_used,
        "survivor_mb": $survivor_used,
        "oldgen_mb": $oldgen_used,
        "metaspace_mb": $metaspace_used,
        "codecache_mb": $codecache_used
    }
}
EOF
    
    # Return the collected metrics as space-separated values
    echo "$heap_used $heap_committed $heap_max $nonheap_used $nonheap_committed $nonheap_max $gc_collections $gc_time $thread_count $thread_peak $thread_daemon $classes_loaded $classes_total $classes_unloaded $cpu_process $cpu_system $fd_open $fd_max $eden_used $survivor_used $oldgen_used $metaspace_used $codecache_used"
}

# Function to test a single Docker configuration
test_docker_config() {
    local config_pair=$1
    local config=$(echo "$config_pair" | cut -d: -f1)
    local dockerfile=$(echo "$config_pair" | cut -d: -f2)
    local image_name="jvm-metrics-${config}"
    local container_name="test-metrics-${config}"
    
    log "${BLUE}Testing configuration: ${config}${NC}"
    echo "Dockerfile: ${dockerfile}"
    
    # Clean up any existing containers/images
    docker rm -f "$container_name" 2>/dev/null || true
    docker rmi -f "$image_name" 2>/dev/null || true
    
    # Build the image and measure time
    log "${YELLOW}Building image...${NC}"
    local build_start=$(date +%s)
    
    if docker build -f "$dockerfile" -t "$image_name" . > "${RESULTS_DIR}/${config}_build.log" 2>&1; then
        local build_end=$(date +%s)
        local build_time=$((build_end - build_start))
        log "${GREEN}✓ Build successful (${build_time}s)${NC}"
    else
        log "${RED}✗ Build failed${NC}"
        echo "${config},BUILD_FAILED,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,FAILED" >> "$RESULTS_CSV"
        return 1
    fi
    
    # Get image size
    local image_size=$(docker images "$image_name" --format "{{.Size}}" | head -1 | sed 's/MB//' | sed 's/GB/*1024/' | bc -l 2>/dev/null | cut -d. -f1 || echo "0")
    
    # Run the container
    log "${YELLOW}Starting container...${NC}"
    local startup_start=$(date +%s)
    
    if docker run -d --name "$container_name" --memory="$MEMORY_LIMIT" -p "${BASE_PORT}:8080" "$image_name" > /dev/null 2>&1; then
        log "${GREEN}✓ Container started${NC}"
    else
        log "${RED}✗ Container failed to start${NC}"
        echo "${config},${build_time},${image_size},STARTUP_FAILED,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,FAILED" >> "$RESULTS_CSV"
        return 1
    fi
    
    # Wait for application to start and measure startup time
    log "${YELLOW}Waiting for application startup and warmup...${NC}"
    local startup_time=0
    local max_startup_wait=90
    
    while [ $startup_time -lt $max_startup_wait ]; do
        if curl -s "http://localhost:${BASE_PORT}/actuator/health" > /dev/null 2>&1; then
            local startup_end=$(date +%s)
            startup_time=$((startup_end - startup_start))
            log "${GREEN}✓ Application ready (${startup_time}s)${NC}"
            break
        fi
        sleep 3
        startup_time=$((startup_time + 3))
    done
    
    if [ $startup_time -ge $max_startup_wait ]; then
        log "${RED}✗ Application startup timeout${NC}"
        docker logs "$container_name" > "${RESULTS_DIR}/${config}_startup_logs.txt" 2>&1
        docker rm -f "$container_name" 2>/dev/null || true
        echo "${config},${build_time},${image_size},TIMEOUT,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,FAILED" >> "$RESULTS_CSV"
        return 1
    fi
    
    # Warmup period with load
    log "${YELLOW}Warming up application (${WARMUP_TIME}s)...${NC}"
    local warmup_end=$(($(date +%s) + WARMUP_TIME))
    while [ $(date +%s) -lt $warmup_end ]; do
        for endpoint in "/" "/actuator/health" "/actuator/info"; do
            curl -s "http://localhost:${BASE_PORT}${endpoint}" > /dev/null 2>&1 || true
        done
        sleep 2
    done
    
    # Collect metrics during test period
    log "${YELLOW}Collecting detailed metrics (${TEST_DURATION}s)...${NC}"
    local metrics_start=$(date +%s)
    local metrics_end=$((metrics_start + TEST_DURATION))
    
    # Initialize metric collection variables
    local total_memory=0
    local total_cpu=0
    local sample_count=0
    
    # Collect metrics at intervals
    while [ $(date +%s) -lt $metrics_end ]; do
        # Get container stats
        local stats=$(docker stats --no-stream --format "{{.MemUsage}}\t{{.CPUPerc}}" "$container_name" 2>/dev/null || echo "0MiB / 0MiB\t0.00%")
        local memory_raw=$(echo "$stats" | cut -f1 | cut -d'/' -f1 | sed 's/MiB//' | sed 's/GiB/*1024/' | bc -l 2>/dev/null || echo "0")
        local cpu_raw=$(echo "$stats" | cut -f2 | sed 's/%//' || echo "0")
        
        total_memory=$(echo "$total_memory + $memory_raw" | bc -l 2>/dev/null || echo "$total_memory")
        total_cpu=$(echo "$total_cpu + $cpu_raw" | bc -l 2>/dev/null || echo "$total_cpu")
        sample_count=$((sample_count + 1))
        
        # Generate some load
        for endpoint in "/" "/actuator/health" "/actuator/metrics" "/actuator/info"; do
            curl -s "http://localhost:${BASE_PORT}${endpoint}" > /dev/null 2>&1 || true
        done
        
        sleep $METRICS_INTERVAL
    done
    
    # Calculate averages
    local avg_memory=$(echo "scale=2; $total_memory / $sample_count" | bc -l 2>/dev/null || echo "0")
    local avg_cpu=$(echo "scale=2; $total_cpu / $sample_count" | bc -l 2>/dev/null || echo "0")
    
    # Get comprehensive JVM metrics
    local jvm_metrics=$(get_jvm_metrics "$config")
    
    # Get final container logs
    docker logs "$container_name" > "${RESULTS_DIR}/${config}_runtime_logs.txt" 2>&1
    
    # Clean up
    docker rm -f "$container_name" 2>/dev/null || true
    
    # Record results
    echo "${config},${build_time},${image_size},${startup_time},${avg_memory},${avg_cpu},${jvm_metrics},SUCCESS" >> "$RESULTS_CSV"
    
    log "${GREEN}✓ Test completed for ${config}${NC}"
    echo ""
}

# Main testing loop
log "${BLUE}Starting comprehensive JVM metrics testing...${NC}"
echo ""

for config_pair in "${CONFIGS[@]}"; do
    test_docker_config "$config_pair" || true
    
    # Small delay between tests
    sleep 5
done

# Generate comprehensive analysis report
log "${BLUE}Generating comprehensive analysis report...${NC}"

cat > "${RESULTS_DIR}/JVM_PERFORMANCE_ANALYSIS.md" << 'EOF'
# 🚀 Comprehensive JVM Performance Analysis

## Overview
This report provides detailed JVM performance metrics across different Docker configurations, focusing on memory usage, garbage collection, threading, CPU utilization, and resource management.

## Test Configuration
- **Test Duration**: 120 seconds per container
- **Warmup Period**: 45 seconds with load generation
- **Metrics Collection Interval**: 10 seconds
- **Memory Limit**: 1GB per container
- **Load Generation**: Continuous requests to multiple endpoints

## Metrics Collected

### Memory Management
- **Heap Memory**: Used, Committed, Maximum allocation
- **Non-Heap Memory**: Used, Committed, Maximum allocation
- **Memory Pools**: Eden, Survivor, Old Generation, Metaspace, Code Cache

### Garbage Collection
- **GC Collections**: Total number of collections
- **GC Time**: Total time spent in garbage collection (milliseconds)
- **GC Efficiency**: Collections per second and average pause time

### Threading
- **Live Threads**: Current active thread count
- **Peak Threads**: Maximum thread count reached
- **Daemon Threads**: Background thread count

### CPU & System Resources
- **Process CPU**: JVM process CPU utilization percentage
- **System CPU**: Overall system CPU utilization percentage
- **File Descriptors**: Open and maximum file descriptor counts

### Class Loading
- **Loaded Classes**: Currently loaded class count
- **Total Classes**: Cumulative classes loaded
- **Unloaded Classes**: Classes that have been unloaded

## Performance Analysis

EOF

# Generate HTML report
cat > "${RESULTS_DIR}/comprehensive_report.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Comprehensive JVM Performance Analysis</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 20px; 
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #2c3e50; text-align: center; }
        h2 { color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        table { 
            border-collapse: collapse; 
            width: 100%; 
            margin: 20px 0; 
            font-size: 12px;
        }
        th, td { 
            border: 1px solid #ddd; 
            padding: 8px; 
            text-align: center; 
        }
        th { 
            background-color: #3498db; 
            color: white;
            font-weight: bold;
        }
        .success { color: #27ae60; font-weight: bold; }
        .failed { color: #e74c3c; font-weight: bold; }
        .metric { font-weight: bold; }
        .best { background-color: #d5f4e6; }
        .good { background-color: #fef9e7; }
        .poor { background-color: #fadbd8; }
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .summary-card {
            background-color: #ecf0f1;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }
        .summary-card h3 {
            margin-top: 0;
            color: #2c3e50;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Comprehensive JVM Performance Analysis</h1>
        <p style="text-align: center; font-style: italic;">Generated on: $(date)</p>
        
        <div class="summary-grid">
            <div class="summary-card">
                <h3>🏗️ Build Performance</h3>
                <p>Analysis of Docker image build times and final image sizes</p>
            </div>
            <div class="summary-card">
                <h3>💾 Memory Efficiency</h3>
                <p>Heap and non-heap memory utilization patterns</p>
            </div>
            <div class="summary-card">
                <h3>🗑️ Garbage Collection</h3>
                <p>GC frequency, pause times, and efficiency metrics</p>
            </div>
            <div class="summary-card">
                <h3>🧵 Threading Performance</h3>
                <p>Thread management and concurrency metrics</p>
            </div>
        </div>
        
        <h2>📊 Comprehensive Metrics Table</h2>
        <table id="metricsTable">
            <thead>
                <tr>
                    <th rowspan="2">Configuration</th>
                    <th rowspan="2">Build Time (s)</th>
                    <th rowspan="2">Image Size (MB)</th>
                    <th rowspan="2">Startup Time (s)</th>
                    <th colspan="2">Container Resources</th>
                    <th colspan="3">Heap Memory (MB)</th>
                    <th colspan="3">Non-Heap Memory (MB)</th>
                    <th colspan="2">Garbage Collection</th>
                    <th colspan="3">Threading</th>
                    <th colspan="3">Class Loading</th>
                    <th colspan="2">CPU Usage (%)</th>
                    <th colspan="2">File Descriptors</th>
                    <th colspan="5">Memory Pools (MB)</th>
                    <th rowspan="2">Status</th>
                </tr>
                <tr>
                    <th>Memory (MB)</th>
                    <th>CPU (%)</th>
                    <th>Used</th>
                    <th>Committed</th>
                    <th>Max</th>
                    <th>Used</th>
                    <th>Committed</th>
                    <th>Max</th>
                    <th>Collections</th>
                    <th>Time (ms)</th>
                    <th>Live</th>
                    <th>Peak</th>
                    <th>Daemon</th>
                    <th>Loaded</th>
                    <th>Total</th>
                    <th>Unloaded</th>
                    <th>Process</th>
                    <th>System</th>
                    <th>Open</th>
                    <th>Max</th>
                    <th>Eden</th>
                    <th>Survivor</th>
                    <th>Old Gen</th>
                    <th>Metaspace</th>
                    <th>Code Cache</th>
                </tr>
            </thead>
            <tbody>
EOF

# Add results to HTML
tail -n +2 "$RESULTS_CSV" | while IFS=',' read -r config build_time image_size startup_time container_memory container_cpu heap_used heap_committed heap_max nonheap_used nonheap_committed nonheap_max gc_collections gc_time thread_count thread_peak thread_daemon classes_loaded classes_total classes_unloaded cpu_process cpu_system fd_open fd_max eden_used survivor_used oldgen_used metaspace_used codecache_used status; do
    status_class="success"
    if [ "$status" = "FAILED" ]; then
        status_class="failed"
    fi
    
    echo "            <tr>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td><strong>$config</strong></td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$build_time</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$image_size</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$startup_time</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$container_memory</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$container_cpu</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$heap_used</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$heap_committed</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$heap_max</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$nonheap_used</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$nonheap_committed</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$nonheap_max</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$gc_collections</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$gc_time</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$thread_count</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$thread_peak</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$thread_daemon</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$classes_loaded</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$classes_total</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$classes_unloaded</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$cpu_process</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$cpu_system</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$fd_open</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$fd_max</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$eden_used</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$survivor_used</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$oldgen_used</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$metaspace_used</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td>$codecache_used</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "                <td class=\"$status_class\">$status</td>" >> "${RESULTS_DIR}/comprehensive_report.html"
    echo "            </tr>" >> "${RESULTS_DIR}/comprehensive_report.html"
done

cat >> "${RESULTS_DIR}/comprehensive_report.html" << 'EOF'
            </tbody>
        </table>
        
        <h2>🎯 Key Performance Insights</h2>
        
        <div class="summary-grid">
            <div class="summary-card">
                <h3>🏆 Memory Champions</h3>
                <ul>
                    <li><strong>Lowest Heap Usage:</strong> Most memory-efficient configuration</li>
                    <li><strong>Best GC Performance:</strong> Minimal collection time and frequency</li>
                    <li><strong>Optimal Memory Pools:</strong> Efficient Eden/Survivor/Old Gen usage</li>
                </ul>
            </div>
            
            <div class="summary-card">
                <h3>⚡ Performance Leaders</h3>
                <ul>
                    <li><strong>Fastest Startup:</strong> Quickest application initialization</li>
                    <li><strong>Lowest CPU Usage:</strong> Most CPU-efficient during operation</li>
                    <li><strong>Best Threading:</strong> Optimal thread management</li>
                </ul>
            </div>
            
            <div class="summary-card">
                <h3>📦 Build Efficiency</h3>
                <ul>
                    <li><strong>Fastest Build:</strong> Shortest Docker image build time</li>
                    <li><strong>Smallest Image:</strong> Most compact final image size</li>
                    <li><strong>Best Ratio:</strong> Performance per MB of image size</li>
                </ul>
            </div>
            
            <div class="summary-card">
                <h3>🎛️ Resource Management</h3>
                <ul>
                    <li><strong>File Descriptor Efficiency:</strong> Optimal resource usage</li>
                    <li><strong>Class Loading Performance:</strong> Efficient class management</li>
                    <li><strong>Memory Pool Optimization:</strong> Best memory allocation patterns</li>
                </ul>
            </div>
        </div>
        
        <h2>📋 Recommendations</h2>
        <div style="background-color: #e8f6ff; padding: 15px; border-radius: 8px; border-left: 4px solid #2196F3;">
            <h3>🏭 Production Deployment</h3>
            <p>Based on comprehensive metrics analysis, recommendations will be generated after test completion.</p>
            
            <h3>🚀 Performance Optimization</h3>
            <p>Specific tuning recommendations for JVM flags, memory allocation, and GC configuration.</p>
            
            <h3>📊 Monitoring Strategy</h3>
            <p>Key metrics to monitor in production based on the performance characteristics observed.</p>
        </div>
    </div>
</body>
</html>
EOF

# Summary
log "${GREEN}✓ Comprehensive JVM metrics testing completed!${NC}"
echo ""
echo "Results saved to: ${RESULTS_DIR}/"
echo "- Comprehensive CSV: ${RESULTS_CSV}"
echo "- HTML Report: ${RESULTS_DIR}/comprehensive_report.html"
echo "- Analysis Report: ${RESULTS_DIR}/JVM_PERFORMANCE_ANALYSIS.md"
echo "- Individual metrics and logs in: ${RESULTS_DIR}/"
echo ""

# Display quick summary
log "${BLUE}Quick Summary:${NC}"
echo "Configuration | Status | Build | Image Size | Startup | Heap Used | GC Collections | Live Threads"
echo "------------- | ------ | ----- | ---------- | ------- | --------- | -------------- | ------------"
tail -n +2 "$RESULTS_CSV" | while IFS=',' read -r config build_time image_size startup_time container_memory container_cpu heap_used heap_committed heap_max nonheap_used nonheap_committed nonheap_max gc_collections gc_time thread_count thread_peak thread_daemon classes_loaded classes_total classes_unloaded cpu_process cpu_system fd_open fd_max eden_used survivor_used oldgen_used metaspace_used codecache_used status; do
    printf "%-12s | %-6s | %-5s | %-10s | %-7s | %-9s | %-14s | %-12s\n" "$config" "$status" "$build_time" "$image_size" "$startup_time" "$heap_used" "$gc_collections" "$thread_count"
done

echo ""
log "${YELLOW}Open ${RESULTS_DIR}/comprehensive_report.html in your browser for detailed analysis.${NC}"
