package com.example.demo

import org.awaitility.kotlin.await
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.BeforeEach
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.web.client.TestRestTemplate
import org.springframework.boot.test.web.server.LocalServerPort
import org.springframework.http.*
import org.springframework.test.context.ActiveProfiles
import org.junit.jupiter.api.Assertions.*
import java.time.Duration
import java.util.concurrent.CompletableFuture
import java.util.concurrent.Executors

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class OrderApiEndToEndTest {

    @LocalServerPort
    private var port: Int = 0

    @Autowired
    private lateinit var restTemplate: TestRestTemplate

    private fun getBaseUrl() = "http://localhost:$port"

    @BeforeEach
    fun setUp() {
        // Ensure clean state for each test
        await.atMost(Duration.ofSeconds(5)).until {
            try {
                val response = restTemplate.getForEntity("${getBaseUrl()}/orders", Array<Order>::class.java)
                response.statusCode == HttpStatus.OK
            } catch (e: Exception) {
                false
            }
        }
    }

    @Test
    fun `should perform complete order management workflow`() {
        val testOrderId = "e2e-workflow-order"
        
        // Step 1: Verify order doesn't exist initially
        val initialGetResponse = restTemplate.getForEntity(
            "${getBaseUrl()}/orders/$testOrderId",
            String::class.java
        )
        assertEquals(HttpStatus.OK, initialGetResponse.statusCode)
        assertTrue(initialGetResponse.body.isNullOrEmpty())

        // Step 2: Create a new order
        val newOrder = Order(testOrderId, "End-to-end test order")
        val createResponse = restTemplate.postForEntity(
            "${getBaseUrl()}/orders",
            newOrder,
            Order::class.java
        )
        assertEquals(HttpStatus.OK, createResponse.statusCode)
        assertEquals(newOrder, createResponse.body)

        // Step 3: Verify order exists and can be retrieved
        val getResponse = restTemplate.getForEntity(
            "${getBaseUrl()}/orders/$testOrderId",
            Order::class.java
        )
        assertEquals(HttpStatus.OK, getResponse.statusCode)
        assertEquals(newOrder, getResponse.body)

        // Step 4: Verify order appears in all orders list
        val allOrdersResponse = restTemplate.getForEntity(
            "${getBaseUrl()}/orders",
            Array<Order>::class.java
        )
        assertEquals(HttpStatus.OK, allOrdersResponse.statusCode)
        val allOrders = allOrdersResponse.body!!.toList()
        assertTrue(allOrders.contains(newOrder))

        // Step 5: Update the order (create with same ID)
        val updatedOrder = Order(testOrderId, "Updated end-to-end test order")
        val updateResponse = restTemplate.postForEntity(
            "${getBaseUrl()}/orders",
            updatedOrder,
            Order::class.java
        )
        assertEquals(HttpStatus.OK, updateResponse.statusCode)
        assertEquals(updatedOrder, updateResponse.body)

        // Step 6: Verify the update took effect
        val getUpdatedResponse = restTemplate.getForEntity(
            "${getBaseUrl()}/orders/$testOrderId",
            Order::class.java
        )
        assertEquals(HttpStatus.OK, getUpdatedResponse.statusCode)
        assertEquals(updatedOrder, getUpdatedResponse.body)
        assertEquals("Updated end-to-end test order", getUpdatedResponse.body?.description)
    }

    @Test
    fun `should handle high-volume order creation and retrieval`() {
        val numberOfOrders = 100
        val orderPrefix = "bulk-test"
        
        // Step 1: Create multiple orders concurrently
        val executor = Executors.newFixedThreadPool(10)
        val createFutures = (1..numberOfOrders).map { i ->
            CompletableFuture.supplyAsync({
                val order = Order("$orderPrefix-$i", "Bulk test order $i")
                restTemplate.postForEntity(
                    "${getBaseUrl()}/orders",
                    order,
                    Order::class.java
                )
            }, executor)
        }

        // Wait for all creations to complete
        val createResponses = createFutures.map { it.get() }
        
        // Verify all creations succeeded
        createResponses.forEach { response ->
            assertEquals(HttpStatus.OK, response.statusCode)
            assertNotNull(response.body)
        }

        // Step 2: Retrieve all orders and verify count
        await.atMost(Duration.ofSeconds(10)).until {
            val allOrdersResponse = restTemplate.getForEntity(
                "${getBaseUrl()}/orders",
                Array<Order>::class.java
            )
            val bulkOrders = allOrdersResponse.body!!.filter { it.id.startsWith(orderPrefix) }
            bulkOrders.size >= numberOfOrders
        }

        // Step 3: Verify individual order retrieval
        val retrievalFutures = (1..numberOfOrders).map { i ->
            CompletableFuture.supplyAsync({
                restTemplate.getForEntity(
                    "${getBaseUrl()}/orders/$orderPrefix-$i",
                    Order::class.java
                )
            }, executor)
        }

        val retrievalResponses = retrievalFutures.map { it.get() }
        
        // Verify all retrievals succeeded
        retrievalResponses.forEach { response ->
            assertEquals(HttpStatus.OK, response.statusCode)
            assertNotNull(response.body)
            assertTrue(response.body!!.id.startsWith(orderPrefix))
        }

        executor.shutdown()
    }

    @Test
    fun `should handle malformed requests gracefully`() {
        // Test malformed JSON
        val headers = HttpHeaders()
        headers.contentType = MediaType.APPLICATION_JSON
        val malformedJsonEntity = HttpEntity("""{"invalid": json}""", headers)
        
        val malformedResponse = restTemplate.exchange(
            "${getBaseUrl()}/orders",
            HttpMethod.POST,
            malformedJsonEntity,
            String::class.java
        )
        assertEquals(HttpStatus.BAD_REQUEST, malformedResponse.statusCode)

        // Test missing required fields
        val incompleteJsonEntity = HttpEntity("""{"description": "Missing ID"}""", headers)
        val incompleteResponse = restTemplate.exchange(
            "${getBaseUrl()}/orders",
            HttpMethod.POST,
            incompleteJsonEntity,
            String::class.java
        )
        assertEquals(HttpStatus.BAD_REQUEST, incompleteResponse.statusCode)

        // Test wrong content type
        val wrongContentTypeHeaders = HttpHeaders()
        wrongContentTypeHeaders.contentType = MediaType.TEXT_PLAIN
        val wrongContentTypeEntity = HttpEntity("""{"id": "test", "description": "test"}""", wrongContentTypeHeaders)
        
        val wrongContentTypeResponse = restTemplate.exchange(
            "${getBaseUrl()}/orders",
            HttpMethod.POST,
            wrongContentTypeEntity,
            String::class.java
        )
        assertEquals(HttpStatus.UNSUPPORTED_MEDIA_TYPE, wrongContentTypeResponse.statusCode)
    }

    @Test
    fun `should handle edge cases in order data`() {
        // Test with empty strings
        val emptyOrder = Order("", "")
        val emptyResponse = restTemplate.postForEntity(
            "${getBaseUrl()}/orders",
            emptyOrder,
            Order::class.java
        )
        assertEquals(HttpStatus.OK, emptyResponse.statusCode)
        assertEquals(emptyOrder, emptyResponse.body)

        // Test with very long strings
        val longId = "a".repeat(1000)
        val longDescription = "b".repeat(10000)
        val longOrder = Order(longId, longDescription)
        val longResponse = restTemplate.postForEntity(
            "${getBaseUrl()}/orders",
            longOrder,
            Order::class.java
        )
        assertEquals(HttpStatus.OK, longResponse.statusCode)
        assertEquals(longOrder, longResponse.body)

        // Test with special characters
        val specialOrder = Order("order-with-特殊字符-🚀", "Description with émojis 🎉 and spëcial chars")
        val specialResponse = restTemplate.postForEntity(
            "${getBaseUrl()}/orders",
            specialOrder,
            Order::class.java
        )
        assertEquals(HttpStatus.OK, specialResponse.statusCode)
        assertEquals(specialOrder, specialResponse.body)

        // Verify retrieval of special character order
        val retrieveSpecialResponse = restTemplate.getForEntity(
            "${getBaseUrl()}/orders/order-with-特殊字符-🚀",
            Order::class.java
        )
        assertEquals(HttpStatus.OK, retrieveSpecialResponse.statusCode)
        assertEquals(specialOrder, retrieveSpecialResponse.body)
    }

    @Test
    fun `should maintain data consistency under concurrent access`() {
        val sharedOrderId = "concurrent-consistency-test"
        val numberOfThreads = 20
        val executor = Executors.newFixedThreadPool(numberOfThreads)
        
        // Create futures for concurrent operations
        val futures = (1..numberOfThreads).map { i ->
            CompletableFuture.runAsync({
                // Each thread will try to create/update the same order
                val order = Order(sharedOrderId, "Update from thread $i")
                restTemplate.postForEntity(
                    "${getBaseUrl()}/orders",
                    order,
                    Order::class.java
                )
                
                // Then immediately try to read it
                restTemplate.getForEntity(
                    "${getBaseUrl()}/orders/$sharedOrderId",
                    Order::class.java
                )
            }, executor)
        }

        // Wait for all operations to complete
        CompletableFuture.allOf(*futures.toTypedArray()).join()

        // Verify final state is consistent
        val finalResponse = restTemplate.getForEntity(
            "${getBaseUrl()}/orders/$sharedOrderId",
            Order::class.java
        )
        assertEquals(HttpStatus.OK, finalResponse.statusCode)
        assertNotNull(finalResponse.body)
        assertEquals(sharedOrderId, finalResponse.body?.id)
        assertTrue(finalResponse.body?.description?.startsWith("Update from thread") == true)

        // Verify the order appears exactly once in the list
        val allOrdersResponse = restTemplate.getForEntity(
            "${getBaseUrl()}/orders",
            Array<Order>::class.java
        )
        val matchingOrders = allOrdersResponse.body!!.filter { it.id == sharedOrderId }
        assertEquals(1, matchingOrders.size)

        executor.shutdown()
    }

    @Test
    fun `should handle rapid sequential operations`() {
        val orderId = "rapid-sequential-test"
        val numberOfOperations = 50
        
        // Perform rapid sequential create/update operations
        repeat(numberOfOperations) { i ->
            val order = Order(orderId, "Sequential update $i")
            val response = restTemplate.postForEntity(
                "${getBaseUrl()}/orders",
                order,
                Order::class.java
            )
            assertEquals(HttpStatus.OK, response.statusCode)
            assertEquals(order, response.body)
            
            // Immediately verify the update
            val getResponse = restTemplate.getForEntity(
                "${getBaseUrl()}/orders/$orderId",
                Order::class.java
            )
            assertEquals(HttpStatus.OK, getResponse.statusCode)
            assertEquals(order, getResponse.body)
        }

        // Verify final state
        val finalResponse = restTemplate.getForEntity(
            "${getBaseUrl()}/orders/$orderId",
            Order::class.java
        )
        assertEquals(HttpStatus.OK, finalResponse.statusCode)
        assertEquals("Sequential update ${numberOfOperations - 1}", finalResponse.body?.description)
    }
}
