# Spring Boot Demo Application

A Spring Boot application demonstrating REST API development with comprehensive testing and monitoring.

## 🚀 Features

- **REST API**: Order management endpoints
- **Spring Boot Actuator**: Production-ready monitoring endpoints
- **Comprehensive Testing**: Unit, integration, and end-to-end tests
- **Thread-Safe Operations**: Concurrent request handling

## 📊 Available Endpoints

### Application Endpoints
- `POST /orders` - Create a new order
- `GET /orders` - Get all orders
- `GET /orders/{id}` - Get order by ID

### Monitoring Endpoints
- `GET /actuator/health` - Application health check
- `GET /actuator/info` - Application information

## 🔧 Quick Start

### 1. Run the Application
```bash
./gradlew bootRun
```

### 2. Test the API
```bash
# Create an order
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"id": "test-1", "description": "Test Order"}'

# Get all orders
curl http://localhost:8080/orders

# Get specific order
curl http://localhost:8080/orders/test-1

# Check application health
curl http://localhost:8080/actuator/health
```

## 🐳 Docker Deployment

### Standard Deployment
```bash
docker build -t spring-boot-demo .
docker run -p 8080:8080 spring-boot-demo
```

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

## 📦 Project Structure

```
├── src/main/kotlin/com/example/demo/
│   ├── DemoApplication.kt          # Main application
│   ├── Order.kt                    # Order model
│   ├── OrderController.kt          # REST controller
│   └── OrderService.kt             # Business logic
├── src/test/kotlin/com/example/demo/
│   ├── OrderTest.kt                # Unit tests for Order
│   ├── OrderServiceTest.kt         # Unit tests for OrderService
│   ├── OrderControllerTest.kt      # Unit tests for OrderController
│   ├── DemoApplicationIntegrationTest.kt    # Integration tests
│   ├── ActuatorEndpointsIntegrationTest.kt  # Actuator tests
│   └── OrderApiEndToEndTest.kt     # End-to-end tests
├── Dockerfile                      # Docker configuration
└── build.gradle.kts               # Build configuration
```

## 🔍 Testing

The application includes comprehensive testing:

### Unit Tests
- **OrderTest**: Data class functionality
- **OrderServiceTest**: Business logic and concurrency
- **OrderControllerTest**: REST API layer

### Integration Tests
- **DemoApplicationIntegrationTest**: Full application context
- **ActuatorEndpointsIntegrationTest**: Health and monitoring endpoints

### End-to-End Tests
- **OrderApiEndToEndTest**: Complete API workflows

### Run Tests
```bash
# Run all tests
./gradlew test

# Run specific test categories
./gradlew test --tests "*Test"           # Unit tests
./gradlew test --tests "*IntegrationTest" # Integration tests
./gradlew test --tests "*EndToEndTest"    # End-to-end tests
```

## 🔍 Troubleshooting

### Check Application Health
```bash
curl http://localhost:8080/actuator/health
```

### Check Application Logs
```bash
./gradlew bootRun --info
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

**Happy coding! 🚀**