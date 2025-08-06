package com.example.demo

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.BeforeEach
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.web.client.TestRestTemplate
import org.springframework.boot.test.web.server.LocalServerPort
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.test.context.ActiveProfiles
import org.junit.jupiter.api.Assertions.*

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class DemoApplicationIntegrationTest {

    @LocalServerPort
    private var port: Int = 0

    @Autowired
    private lateinit var restTemplate: TestRestTemplate

    @Autowired
    private lateinit var orderService: OrderService

    private fun getBaseUrl() = "http://localhost:$port"

    @BeforeEach
    fun setUp() {
        // Clear any existing orders before each test
        orderService.getAllOrders().forEach { order ->
            // Since we don't have a delete method, we'll work with the existing state
        }
    }

    @Test
    fun `application should start successfully`() {
        // This test verifies that the Spring Boot application context loads successfully
        assertTrue(port > 0)
    }

    @Test
    fun `should create order via REST API`() {
        // Given
        val order = Order("integration-test-1", "Integration test order")

        // When
        val response: ResponseEntity<Order> = restTemplate.postForEntity(
            "${getBaseUrl()}/orders",
            order,
            Order::class.java
        )

        // Then
        assertEquals(HttpStatus.OK, response.statusCode)
        assertNotNull(response.body)
        assertEquals("integration-test-1", response.body?.id)
        assertEquals("Integration test order", response.body?.description)
    }

    @Test
    fun `should retrieve order by id via REST API`() {
        // Given - Create an order first
        val order = Order("integration-test-2", "Another integration test order")
        restTemplate.postForEntity("${getBaseUrl()}/orders", order, Order::class.java)

        // When
        val response: ResponseEntity<Order> = restTemplate.getForEntity(
            "${getBaseUrl()}/orders/integration-test-2",
            Order::class.java
        )

        // Then
        assertEquals(HttpStatus.OK, response.statusCode)
        assertNotNull(response.body)
        assertEquals("integration-test-2", response.body?.id)
        assertEquals("Another integration test order", response.body?.description)
    }

    @Test
    fun `should return 200 with empty body for non-existent order`() {
        // When
        val response: ResponseEntity<String> = restTemplate.getForEntity(
            "${getBaseUrl()}/orders/non-existent-order",
            String::class.java
        )

        // Then
        assertEquals(HttpStatus.OK, response.statusCode)
        assertTrue(response.body.isNullOrEmpty())
    }

    @Test
    fun `should retrieve all orders via REST API`() {
        // Given - Create multiple orders
        val orders = listOf(
            Order("integration-test-3", "First order"),
            Order("integration-test-4", "Second order"),
            Order("integration-test-5", "Third order")
        )

        orders.forEach { order ->
            restTemplate.postForEntity("${getBaseUrl()}/orders", order, Order::class.java)
        }

        // When
        val response: ResponseEntity<Array<Order>> = restTemplate.getForEntity(
            "${getBaseUrl()}/orders",
            Array<Order>::class.java
        )

        // Then
        assertEquals(HttpStatus.OK, response.statusCode)
        assertNotNull(response.body)
        val retrievedOrders = response.body!!.toList()
        
        // Verify that our test orders are included (there might be others from previous tests)
        assertTrue(retrievedOrders.any { it.id == "integration-test-3" })
        assertTrue(retrievedOrders.any { it.id == "integration-test-4" })
        assertTrue(retrievedOrders.any { it.id == "integration-test-5" })
    }

    @Test
    fun `should handle complete order lifecycle`() {
        // Given
        val orderId = "lifecycle-test-order"
        val originalOrder = Order(orderId, "Original description")
        val updatedOrder = Order(orderId, "Updated description")

        // When - Create order
        val createResponse: ResponseEntity<Order> = restTemplate.postForEntity(
            "${getBaseUrl()}/orders",
            originalOrder,
            Order::class.java
        )

        // Then - Verify creation
        assertEquals(HttpStatus.OK, createResponse.statusCode)
        assertEquals(originalOrder, createResponse.body)

        // When - Retrieve order
        val getResponse: ResponseEntity<Order> = restTemplate.getForEntity(
            "${getBaseUrl()}/orders/$orderId",
            Order::class.java
        )

        // Then - Verify retrieval
        assertEquals(HttpStatus.OK, getResponse.statusCode)
        assertEquals(originalOrder, getResponse.body)

        // When - Update order (create with same ID)
        val updateResponse: ResponseEntity<Order> = restTemplate.postForEntity(
            "${getBaseUrl()}/orders",
            updatedOrder,
            Order::class.java
        )

        // Then - Verify update
        assertEquals(HttpStatus.OK, updateResponse.statusCode)
        assertEquals(updatedOrder, updateResponse.body)

        // When - Retrieve updated order
        val getUpdatedResponse: ResponseEntity<Order> = restTemplate.getForEntity(
            "${getBaseUrl()}/orders/$orderId",
            Order::class.java
        )

        // Then - Verify updated retrieval
        assertEquals(HttpStatus.OK, getUpdatedResponse.statusCode)
        assertEquals(updatedOrder, getUpdatedResponse.body)
        assertEquals("Updated description", getUpdatedResponse.body?.description)
    }

    @Test
    fun `should handle concurrent requests properly`() {
        // Given
        val numberOfRequests = 50
        val responses = mutableListOf<ResponseEntity<Order>>()

        // When - Make concurrent requests
        val threads = (1..numberOfRequests).map { i ->
            Thread {
                val order = Order("concurrent-test-$i", "Concurrent order $i")
                val response = restTemplate.postForEntity(
                    "${getBaseUrl()}/orders",
                    order,
                    Order::class.java
                )
                synchronized(responses) {
                    responses.add(response)
                }
            }
        }

        threads.forEach { it.start() }
        threads.forEach { it.join() }

        // Then - Verify all requests succeeded
        assertEquals(numberOfRequests, responses.size)
        responses.forEach { response ->
            assertEquals(HttpStatus.OK, response.statusCode)
            assertNotNull(response.body)
        }

        // Verify all orders were created
        val allOrdersResponse: ResponseEntity<Array<Order>> = restTemplate.getForEntity(
            "${getBaseUrl()}/orders",
            Array<Order>::class.java
        )

        val allOrders = allOrdersResponse.body!!.toList()
        val concurrentOrders = allOrders.filter { it.id.startsWith("concurrent-test-") }
        assertEquals(numberOfRequests, concurrentOrders.size)
    }
}
