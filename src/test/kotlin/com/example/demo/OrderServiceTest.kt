package com.example.demo

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Assertions.*
import java.util.concurrent.CompletableFuture
import java.util.concurrent.Executors

class OrderServiceTest {

    private lateinit var orderService: OrderService

    @BeforeEach
    fun setUp() {
        orderService = OrderService()
    }

    @Test
    fun `should create and store order`() {
        // Given
        val order = Order("order-123", "Test order")

        // When
        val createdOrder = orderService.createOrder(order)

        // Then
        assertEquals(order, createdOrder)
        assertEquals(order, orderService.getOrder("order-123"))
    }

    @Test
    fun `should return null for non-existent order`() {
        // When
        val result = orderService.getOrder("non-existent")

        // Then
        assertNull(result)
    }

    @Test
    fun `should return all orders`() {
        // Given
        val order1 = Order("order-1", "First order")
        val order2 = Order("order-2", "Second order")
        val order3 = Order("order-3", "Third order")

        // When
        orderService.createOrder(order1)
        orderService.createOrder(order2)
        orderService.createOrder(order3)
        val allOrders = orderService.getAllOrders()

        // Then
        assertEquals(3, allOrders.size)
        assertTrue(allOrders.contains(order1))
        assertTrue(allOrders.contains(order2))
        assertTrue(allOrders.contains(order3))
    }

    @Test
    fun `should return empty list when no orders exist`() {
        // When
        val allOrders = orderService.getAllOrders()

        // Then
        assertTrue(allOrders.isEmpty())
    }

    @Test
    fun `should update existing order when creating with same id`() {
        // Given
        val originalOrder = Order("order-123", "Original description")
        val updatedOrder = Order("order-123", "Updated description")

        // When
        orderService.createOrder(originalOrder)
        orderService.createOrder(updatedOrder)

        // Then
        val retrievedOrder = orderService.getOrder("order-123")
        assertEquals(updatedOrder, retrievedOrder)
        assertEquals("Updated description", retrievedOrder?.description)
    }

    @Test
    fun `should handle concurrent access safely`() {
        // Given
        val executor = Executors.newFixedThreadPool(10)
        val futures = mutableListOf<CompletableFuture<Void>>()

        // When - Create 100 orders concurrently
        repeat(100) { i ->
            val future = CompletableFuture.runAsync({
                val order = Order("order-$i", "Description $i")
                orderService.createOrder(order)
            }, executor)
            futures.add(future)
        }

        // Wait for all operations to complete
        CompletableFuture.allOf(*futures.toTypedArray()).join()

        // Then
        val allOrders = orderService.getAllOrders()
        assertEquals(100, allOrders.size)

        // Verify all orders are present
        repeat(100) { i ->
            val order = orderService.getOrder("order-$i")
            assertNotNull(order)
            assertEquals("Description $i", order?.description)
        }

        executor.shutdown()
    }

    @Test
    fun `should handle concurrent read and write operations`() {
        // Given
        val executor = Executors.newFixedThreadPool(20)
        val writeFutures = mutableListOf<CompletableFuture<Void>>()
        val readFutures = mutableListOf<CompletableFuture<List<Order>>>()

        // When - Perform concurrent writes
        repeat(50) { i ->
            val future = CompletableFuture.runAsync({
                val order = Order("order-$i", "Description $i")
                orderService.createOrder(order)
            }, executor)
            writeFutures.add(future)
        }

        // Perform concurrent reads
        repeat(50) { 
            val future = CompletableFuture.supplyAsync({
                orderService.getAllOrders()
            }, executor)
            readFutures.add(future)
        }

        // Wait for all operations to complete
        CompletableFuture.allOf(*writeFutures.toTypedArray()).join()
        CompletableFuture.allOf(*readFutures.toTypedArray()).join()

        // Then
        val finalOrders = orderService.getAllOrders()
        assertEquals(50, finalOrders.size)

        // Verify no exceptions occurred during concurrent access
        readFutures.forEach { future ->
            assertDoesNotThrow { future.get() }
        }

        executor.shutdown()
    }
}
