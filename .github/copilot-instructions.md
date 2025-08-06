# GitHub Copilot Instructions - Spring Boot Demo

## Project Context
This is a **production-ready Spring Boot application** demonstrating modern development practices, comprehensive testing, and observability patterns. The codebase serves as a reference implementation for enterprise-grade Kotlin/Spring Boot applications.

## Architecture Decision Records (ADRs)

### ADR-001: Technology Stack Selection
- **Decision**: Spring Boot 3.5.0 + Kotlin 1.9.25 + Java 21
- **Rationale**: Latest LTS versions with modern language features
- **Consequences**: Enhanced performance, modern language features, long-term support

### ADR-002: Data Storage Strategy
- **Decision**: In-memory ConcurrentHashMap for data persistence
- **Rationale**: Simplicity, thread-safety, no external dependencies
- **Consequences**: Data lost on restart, suitable for demo/testing purposes

### ADR-003: Testing Strategy
- **Decision**: Multi-layered testing (Unit → Integration → E2E)
- **Rationale**: Comprehensive coverage, confidence in deployments
- **Consequences**: Higher development time, better code quality

### ADR-004: Monitoring & Observability
- **Decision**: Spring Boot Actuator for monitoring
- **Rationale**: Built-in Spring Boot feature, production-ready
- **Consequences**: Basic monitoring capabilities, easy integration

## Code Generation Guidelines

### Package Structure
```
com.example.demo/
├── DemoApplication.kt          # Main Spring Boot application
├── Order.kt                    # Data model (data class)
├── OrderController.kt          # REST API endpoints
└── OrderService.kt             # Business logic layer
```

### When creating new REST endpoints:
```kotlin
// Template for new REST controllers
@RestController
@RequestMapping("/api/v1/{resource}")
class {Resource}Controller(
    private val {resource}Service: {Resource}Service,
) {
    
    @PostMapping
    fun create{Resource}(@RequestBody {resource}: {Resource}): {Resource} {
        return {resource}Service.create{Resource}({resource})
    }
    
    @GetMapping("/{id}")
    fun get{Resource}(@PathVariable id: String): {Resource}? {
        return {resource}Service.get{Resource}(id)
    }
    
    @GetMapping
    fun getAll{Resource}s(): List<{Resource}> {
        return {resource}Service.getAll{Resource}s()
    }
}
```

### When creating new service classes:
```kotlin
// Template for new service classes
@Service
class {Resource}Service {
    private val {resource}s = ConcurrentHashMap<String, {Resource}>()
    
    fun create{Resource}({resource}: {Resource}): {Resource} {
        {resource}s[{resource}.id] = {resource}
        return {resource}
    }
    
    fun get{Resource}(id: String): {Resource}? {
        return {resource}s[id]
    }
    
    fun getAll{Resource}s(): List<{Resource}> {
        return {resource}s.values.toList()
    }
}
```

### When creating new data models:
```kotlin
// Template for new data classes
data class {Resource}(
    val id: String,
    val name: String,
    val description: String
) {
    // Add validation if needed
    init {
        require(id.isNotBlank()) { "ID cannot be blank" }
        require(name.isNotBlank()) { "Name cannot be blank" }
    }
}
```

## Testing Templates

### Unit Test Template:
```kotlin
class {Resource}ServiceTest {
    private lateinit var {resource}Service: {Resource}Service

    @BeforeEach
    fun setUp() {
        {resource}Service = {Resource}Service()
    }

    @Test
    fun `should create and store {resource}`() {
        // Given
        val {resource} = {Resource}("test-id", "Test Name", "Test Description")

        // When
        val created{Resource} = {resource}Service.create{Resource}({resource})

        // Then
        assertEquals({resource}, created{Resource})
        assertEquals({resource}, {resource}Service.get{Resource}("test-id"))
    }

    @Test
    fun `should return null for non-existent {resource}`() {
        // When
        val result = {resource}Service.get{Resource}("non-existent")

        // Then
        assertNull(result)
    }
}
```

### Integration Test Template:
```kotlin
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class {Resource}IntegrationTest {

    @LocalServerPort
    private var port: Int = 0

    @Autowired
    private lateinit var restTemplate: TestRestTemplate

    private fun getBaseUrl() = "http://localhost:$port"

    @Test
    fun `should create {resource} via REST API`() {
        // Given
        val {resource} = {Resource}("integration-test-1", "Integration Test", "Test Description")

        // When
        val response: ResponseEntity<{Resource}> = restTemplate.postForEntity(
            "${getBaseUrl()}/api/v1/{resource}s",
            {resource},
            {Resource}::class.java
        )

        // Then
        assertEquals(HttpStatus.OK, response.statusCode)
        assertNotNull(response.body)
        assertEquals("integration-test-1", response.body?.id)
    }
}
```

## Configuration Management

### Application Properties Structure:
```properties
# Application Configuration
spring.application.name=${APP_NAME:spring-boot-demo}
server.port=${SERVER_PORT:8080}

# Actuator Configuration
management.endpoints.web.exposure.include=health,info
management.endpoint.health.show-details=always

# Logging Configuration
logging.level.com.example.demo=${LOG_LEVEL:INFO}
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} - %msg%n
```

## Development Workflow for AI

### 1. Feature Development Checklist:
- [ ] Create data model (data class)
- [ ] Implement service layer with business logic
- [ ] Create REST controller with proper HTTP methods
- [ ] Add input validation and error handling
- [ ] Write comprehensive unit tests
- [ ] Add integration tests
- [ ] Update documentation

### 2. Code Review Checklist:
- [ ] Follows Kotlin coding conventions
- [ ] Uses appropriate Spring Boot annotations
- [ ] Implements proper error handling
- [ ] Includes comprehensive tests
- [ ] Thread-safe for concurrent access
- [ ] Follows established patterns

### 3. Quality Gates:
- [ ] All tests pass (unit, integration, e2e)
- [ ] Code coverage > 80%
- [ ] No critical security vulnerabilities
- [ ] Documentation updated

This comprehensive instruction set ensures that AI assistants understand the project's architecture, patterns, and quality standards when contributing to the codebase.
