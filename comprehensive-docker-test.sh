#!/bin/zsh

# Comprehensive Docker Configuration Testing Script
# Tests all Docker configurations and compares JVM metrics

set -e  # Exit on any error

# Configuration
TEST_DURATION=60  # seconds to run each container
WARMUP_TIME=30    # seconds to wait for application startup
BASE_PORT=8080
RESULTS_DIR="test-results/comprehensive_$(date +%Y%m%d_%H%M%S)"
MEMORY_LIMIT="512m"  # Container memory limit

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create results directory
mkdir -p "$RESULTS_DIR"

echo -e "${BLUE}🐳 Comprehensive Docker Configuration Testing${NC}"
echo "=============================================="
echo "Test Duration: ${TEST_DURATION}s per container"
echo "Warmup Time: ${WARMUP_TIME}s"
echo "Memory Limit: ${MEMORY_LIMIT}"
echo "Results Directory: ${RESULTS_DIR}"
echo ""

# Define Docker configurations (using arrays for zsh compatibility)
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

# Initialize results file
RESULTS_CSV="${RESULTS_DIR}/results.csv"
echo "Configuration,Build_Time,Image_Size_MB,Startup_Time,Memory_Usage_MB,CPU_Usage_Percent,Heap_Used_MB,Heap_Max_MB,GC_Collections,GC_Time_MS,Status" > "$RESULTS_CSV"

# Function to log with timestamp
log() {
    echo -e "[$(date '+%H:%M:%S')] $1"
}

# Function to get container stats
get_container_stats() {
    local container_name=$1
    local stats_file="${RESULTS_DIR}/${container_name}_stats.json"
    
    # Get Docker stats
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" "$container_name" > "${RESULTS_DIR}/${container_name}_docker_stats.txt" 2>/dev/null || echo "N/A" > "${RESULTS_DIR}/${container_name}_docker_stats.txt"
    
    # Try to get JVM metrics from actuator endpoint
    local jvm_metrics=""
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics" > /dev/null 2>&1; then
        curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.used" > "${RESULTS_DIR}/${container_name}_jvm_memory.json" 2>/dev/null || echo "{}" > "${RESULTS_DIR}/${container_name}_jvm_memory.json"
        curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.gc.memory.allocated" > "${RESULTS_DIR}/${container_name}_jvm_gc.json" 2>/dev/null || echo "{}" > "${RESULTS_DIR}/${container_name}_jvm_gc.json"
    fi
}

# Function to test a single Docker configuration
test_docker_config() {
    local config_name=$1
    local dockerfile_path=$2
    local image_name="jvm-test-${config_name}"
    local container_name="test-${config_name}"
    
    log "${BLUE}Testing configuration: ${config_name}${NC}"
    echo "Dockerfile: ${dockerfile_path}"
    
    # Clean up any existing containers/images
    docker rm -f "$container_name" 2>/dev/null || true
    docker rmi -f "$image_name" 2>/dev/null || true
    
    # Build the image and measure time
    log "${YELLOW}Building image...${NC}"
    local build_start=$(date +%s)
    
    if docker build -f "$dockerfile_path" -t "$image_name" . > "${RESULTS_DIR}/${config_name}_build.log" 2>&1; then
        local build_end=$(date +%s)
        local build_time=$((build_end - build_start))
        log "${GREEN}✓ Build successful (${build_time}s)${NC}"
    else
        log "${RED}✗ Build failed${NC}"
        echo "${config_name},BUILD_FAILED,0,0,0,0,0,0,0,0,FAILED" >> "$RESULTS_CSV"
        return 1
    fi
    
    # Get image size
    local image_size=$(docker images "$image_name" --format "table {{.Size}}" | tail -n 1 | sed 's/MB//' | sed 's/GB/*1024/' | bc 2>/dev/null || echo "0")
    
    # Run the container
    log "${YELLOW}Starting container...${NC}"
    local startup_start=$(date +%s)
    
    if docker run -d --name "$container_name" --memory="$MEMORY_LIMIT" -p "${BASE_PORT}:8080" "$image_name" > /dev/null 2>&1; then
        log "${GREEN}✓ Container started${NC}"
    else
        log "${RED}✗ Container failed to start${NC}"
        echo "${config_name},${build_time},${image_size},STARTUP_FAILED,0,0,0,0,0,0,FAILED" >> "$RESULTS_CSV"
        return 1
    fi
    
    # Wait for application to start and measure startup time
    log "${YELLOW}Waiting for application startup...${NC}"
    local startup_time=0
    local max_startup_wait=120  # 2 minutes max wait
    
    while [ $startup_time -lt $max_startup_wait ]; do
        if curl -s "http://localhost:${BASE_PORT}/actuator/health" > /dev/null 2>&1; then
            local startup_end=$(date +%s)
            startup_time=$((startup_end - startup_start))
            log "${GREEN}✓ Application ready (${startup_time}s)${NC}"
            break
        fi
        sleep 2
        startup_time=$((startup_time + 2))
    done
    
    if [ $startup_time -ge $max_startup_wait ]; then
        log "${RED}✗ Application startup timeout${NC}"
        docker logs "$container_name" > "${RESULTS_DIR}/${config_name}_startup_logs.txt" 2>&1
        docker rm -f "$container_name" 2>/dev/null || true
        echo "${config_name},${build_time},${image_size},TIMEOUT,0,0,0,0,0,0,FAILED" >> "$RESULTS_CSV"
        return 1
    fi
    
    # Warmup period
    log "${YELLOW}Warming up application (${WARMUP_TIME}s)...${NC}"
    for i in $(seq 1 $((WARMUP_TIME/5))); do
        curl -s "http://localhost:${BASE_PORT}/" > /dev/null 2>&1 || true
        sleep 5
    done
    
    # Collect metrics during test period
    log "${YELLOW}Collecting metrics (${TEST_DURATION}s)...${NC}"
    local metrics_start=$(date +%s)
    local metrics_end=$((metrics_start + TEST_DURATION))
    
    # Initialize metric collection variables
    local total_memory=0
    local total_cpu=0
    local sample_count=0
    
    while [ $(date +%s) -lt $metrics_end ]; do
        # Get container stats
        local stats=$(docker stats --no-stream --format "{{.MemUsage}}\t{{.CPUPerc}}" "$container_name" 2>/dev/null || echo "0MiB / 0MiB\t0.00%")
        local memory_raw=$(echo "$stats" | cut -f1 | sed 's/MiB.*//' | sed 's/GiB/*1024/' | bc 2>/dev/null || echo "0")
        local cpu_raw=$(echo "$stats" | cut -f2 | sed 's/%//' || echo "0")
        
        total_memory=$(echo "$total_memory + $memory_raw" | bc 2>/dev/null || echo "$total_memory")
        total_cpu=$(echo "$total_cpu + $cpu_raw" | bc 2>/dev/null || echo "$total_cpu")
        sample_count=$((sample_count + 1))
        
        # Make some requests to generate load
        curl -s "http://localhost:${BASE_PORT}/" > /dev/null 2>&1 || true
        
        sleep 5
    done
    
    # Calculate averages
    local avg_memory=$(echo "scale=2; $total_memory / $sample_count" | bc 2>/dev/null || echo "0")
    local avg_cpu=$(echo "scale=2; $total_cpu / $sample_count" | bc 2>/dev/null || echo "0")
    
    # Try to get JVM-specific metrics
    local heap_used=0
    local heap_max=0
    local gc_collections=0
    local gc_time=0
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.used?tag=area:heap" 2>/dev/null | grep -q "measurements"; then
        heap_used=$(curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.used?tag=area:heap" | jq -r '.measurements[0].value' 2>/dev/null | awk '{print int($1/1024/1024)}' || echo "0")
    fi
    
    if curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.max?tag=area:heap" 2>/dev/null | grep -q "measurements"; then
        heap_max=$(curl -s "http://localhost:${BASE_PORT}/actuator/metrics/jvm.memory.max?tag=area:heap" | jq -r '.measurements[0].value' 2>/dev/null | awk '{print int($1/1024/1024)}' || echo "0")
    fi
    
    # Get final container logs
    docker logs "$container_name" > "${RESULTS_DIR}/${config_name}_runtime_logs.txt" 2>&1
    
    # Save detailed stats
    get_container_stats "$container_name"
    
    # Clean up
    docker rm -f "$container_name" 2>/dev/null || true
    
    # Record results
    echo "${config_name},${build_time},${image_size},${startup_time},${avg_memory},${avg_cpu},${heap_used},${heap_max},${gc_collections},${gc_time},SUCCESS" >> "$RESULTS_CSV"
    
    log "${GREEN}✓ Test completed for ${config_name}${NC}"
    echo ""
}

# Main testing loop
log "${BLUE}Starting comprehensive Docker testing...${NC}"
echo ""

for config_pair in "${CONFIGS[@]}"; do
    config=$(echo "$config_pair" | cut -d: -f1)
    dockerfile=$(echo "$config_pair" | cut -d: -f2)
    test_docker_config "$config" "$dockerfile" || true
    
    # Small delay between tests
    sleep 5
done

# Generate HTML report
log "${BLUE}Generating HTML report...${NC}"
cat > "${RESULTS_DIR}/report.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Docker Configuration Performance Comparison</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .success { color: green; }
        .failed { color: red; }
        .metric { font-weight: bold; }
        .best { background-color: #e8f5e8; }
    </style>
</head>
<body>
    <h1>Docker Configuration Performance Comparison</h1>
    <p>Generated on: $(date)</p>
    
    <h2>Results Summary</h2>
    <table id="resultsTable">
        <thead>
            <tr>
                <th>Configuration</th>
                <th>Build Time (s)</th>
                <th>Image Size (MB)</th>
                <th>Startup Time (s)</th>
                <th>Avg Memory (MB)</th>
                <th>Avg CPU (%)</th>
                <th>Heap Used (MB)</th>
                <th>Heap Max (MB)</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
EOF

# Add results to HTML
tail -n +2 "$RESULTS_CSV" | while IFS=',' read -r config build_time image_size startup_time memory cpu heap_used heap_max gc_collections gc_time status; do
    status_class="success"
    if [ "$status" = "FAILED" ]; then
        status_class="failed"
    fi
    
    echo "            <tr>" >> "${RESULTS_DIR}/report.html"
    echo "                <td>$config</td>" >> "${RESULTS_DIR}/report.html"
    echo "                <td>$build_time</td>" >> "${RESULTS_DIR}/report.html"
    echo "                <td>$image_size</td>" >> "${RESULTS_DIR}/report.html"
    echo "                <td>$startup_time</td>" >> "${RESULTS_DIR}/report.html"
    echo "                <td>$memory</td>" >> "${RESULTS_DIR}/report.html"
    echo "                <td>$cpu</td>" >> "${RESULTS_DIR}/report.html"
    echo "                <td>$heap_used</td>" >> "${RESULTS_DIR}/report.html"
    echo "                <td>$heap_max</td>" >> "${RESULTS_DIR}/report.html"
    echo "                <td class=\"$status_class\">$status</td>" >> "${RESULTS_DIR}/report.html"
    echo "            </tr>" >> "${RESULTS_DIR}/report.html"
done

cat >> "${RESULTS_DIR}/report.html" << 'EOF'
        </tbody>
    </table>
    
    <h2>Key Metrics Analysis</h2>
    <ul>
        <li><strong>Build Time:</strong> Time taken to build the Docker image</li>
        <li><strong>Image Size:</strong> Final Docker image size in MB</li>
        <li><strong>Startup Time:</strong> Time for application to become ready</li>
        <li><strong>Memory Usage:</strong> Average container memory usage during test</li>
        <li><strong>CPU Usage:</strong> Average CPU percentage during test</li>
        <li><strong>Heap Metrics:</strong> JVM heap memory usage (if available)</li>
    </ul>
    
    <h2>Test Configuration</h2>
    <ul>
        <li>Test Duration: 60 seconds per container</li>
        <li>Warmup Time: 30 seconds</li>
        <li>Memory Limit: 512MB per container</li>
        <li>Load Testing: Simple HTTP requests during test period</li>
    </ul>
</body>
</html>
EOF

# Summary
log "${GREEN}✓ Testing completed!${NC}"
echo ""
echo "Results saved to: ${RESULTS_DIR}/"
echo "- CSV Report: ${RESULTS_CSV}"
echo "- HTML Report: ${RESULTS_DIR}/report.html"
echo "- Individual logs and stats in: ${RESULTS_DIR}/"
echo ""

# Display quick summary
log "${BLUE}Quick Summary:${NC}"
echo "Configuration | Status | Build Time | Image Size | Startup Time"
echo "------------- | ------ | ---------- | ---------- | ------------"
tail -n +2 "$RESULTS_CSV" | while IFS=',' read -r config build_time image_size startup_time memory cpu heap_used heap_max gc_collections gc_time status; do
    printf "%-12s | %-6s | %-9s | %-9s | %-11s\n" "$config" "$status" "$build_time" "$image_size" "$startup_time"
done

echo ""
log "${YELLOW}Open ${RESULTS_DIR}/report.html in your browser for detailed analysis.${NC}"
