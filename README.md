# JVM Optimization Demo

A Spring Boot application demonstrating JVM optimization techniques with comprehensive monitoring and observability.

## 🚀 Features

- **REST API**: Order management endpoints
- **JVM Metrics**: Custom and built-in JVM monitoring
- **Prometheus Integration**: Metrics collection and storage
- **Grafana Dashboards**: Real-time visualization
- **Docker Optimization**: Multiple containerization strategies
- **Spring Boot Actuator**: Production-ready monitoring endpoints

## 📊 Available Endpoints

### Application Endpoints
- `POST /orders` - Create a new order
- `GET /orders` - Get all orders
- `GET /orders/{id}` - Get order by ID

### Monitoring Endpoints
- `GET /actuator/health` - Application health check
- `GET /actuator/metrics` - Available metrics list
- `GET /actuator/prometheus` - Prometheus-formatted metrics
- `GET /jvm/metrics` - Custom JVM metrics (comprehensive)
- `GET /jvm/memory` - Memory-specific metrics
- `GET /jvm/gc` - Garbage collection metrics
- `GET /jvm/threads` - Thread metrics

## 🔧 Quick Start

### 1. Run the Application
```bash
./gradlew bootRun
```

### 2. Start Monitoring Stack
```bash
docker-compose -f docker-compose-monitoring.yml up -d
```

### 3. Access Dashboards
- **Application**: http://localhost:8080
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)

### 4. Test the API
```bash
# Create an order
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"id": "test-1", "description": "Test Order"}'

# Get all orders
curl http://localhost:8080/orders

# Check JVM metrics
curl http://localhost:8080/jvm/metrics
```

## 🐳 Docker Deployment

### Standard Deployment
```bash
docker build -t jvm-optimization-demo .
docker run -p 8080:8080 jvm-optimization-demo
```

### Alternative Dockerfiles
The `dockerfiles/` directory contains various optimization strategies:
- `Dockerfile-alpine` - Minimal Alpine-based image
- `Dockerfile-distroless` - Google Distroless base
- `Dockerfile-genzgc` - With Generational ZGC
- `Dockerfile-jre-slim` - OpenJDK JRE slim variant

## 📈 Monitoring Setup

### Prometheus Metrics
The application exposes metrics at `/actuator/prometheus` including:
- JVM memory usage (`jvm_memory_used_bytes`)
- Garbage collection (`jvm_gc_pause_seconds`)
- HTTP requests (`http_server_requests_seconds`)
- Custom application metrics (`orders_active_count`)

### Grafana Dashboards
Pre-configured dashboards for:
- JVM Memory Usage
- Garbage Collection Performance
- HTTP Request Metrics
- Application-Specific Metrics

### Key Metrics to Monitor
```promql
# Memory utilization
jvm_memory_used_bytes{application="demo"} / jvm_memory_max_bytes{application="demo"}

# GC pause time
rate(jvm_gc_pause_seconds_sum[5m])

# Request rate
rate(http_server_requests_seconds_count[5m])

# Active orders
orders_active_count{application="demo"}
```

## ⚡ JVM Optimization Features

### Garbage Collection
- **G1GC**: Low-latency garbage collection
- **Optimized pause times**: Target 200ms max pause
- **Memory-aware**: Automatic heap sizing based on container limits

### Memory Management
- **Container-aware**: Uses percentage of available RAM
- **String optimization**: Deduplication enabled
- **Heap dumps**: Automatic on OOM errors

### Performance Tuning
- **Tiered compilation**: Optimized startup time
- **String concatenation**: Enhanced performance
- **Monitoring**: Built-in JFR and metrics

## 🛠️ Development

### Build
```bash
./gradlew build
```

### Test
```bash
./gradlew test
```

### Clean
```bash
./gradlew clean
```

### Local Development with Monitoring
```bash
# Terminal 1: Start application
./gradlew bootRun

# Terminal 2: Start monitoring
docker-compose -f docker-compose-monitoring.yml up -d

# Terminal 3: Generate load for testing
for i in {1..100}; do 
  curl -X POST http://localhost:8080/orders \
    -H "Content-Type: application/json" \
    -d "{\"id\": \"load-$i\", \"description\": \"Load test $i\"}"
done
```

## 📦 Project Structure

```
├── src/main/kotlin/com/jvm/optimization/demo/
│   ├── DemoApplication.kt          # Main application
│   ├── Order.kt                    # Order model
│   ├── OrderController.kt          # REST controller
│   ├── OrderService.kt             # Business logic
│   ├── JvmMetricsController.kt     # Custom metrics endpoint
│   └── MetricsConfiguration.kt     # Custom metrics configuration
├── dockerfiles/                    # Various Docker strategies
├── monitoring/                     # Prometheus & Grafana config
├── docker-compose-monitoring.yml   # Monitoring stack
├── Dockerfile                     # Optimized production image
└── build.gradle.kts               # Build configuration
```

## 🔍 Troubleshooting

### Check Application Health
```bash
curl http://localhost:8080/actuator/health
```

### Verify Metrics Collection
```bash
curl http://localhost:8080/actuator/prometheus | grep jvm_memory
```

### Monitor Container Resources
```bash
docker stats prometheus grafana
```

### Access Logs
```bash
docker-compose -f docker-compose-monitoring.yml logs -f
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

**Happy optimizing! 🚀**