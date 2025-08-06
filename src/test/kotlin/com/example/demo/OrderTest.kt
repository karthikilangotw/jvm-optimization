package com.example.demo

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*

class OrderTest {

    @Test
    fun `should create order with id and description`() {
        // Given
        val id = "order-123"
        val description = "Test order description"

        // When
        val order = Order(id, description)

        // Then
        assertEquals(id, order.id)
        assertEquals(description, order.description)
    }

    @Test
    fun `should support data class equality`() {
        // Given
        val order1 = Order("order-123", "Test order")
        val order2 = Order("order-123", "Test order")
        val order3 = Order("order-456", "Different order")

        // Then
        assertEquals(order1, order2)
        assertNotEquals(order1, order3)
    }

    @Test
    fun `should support data class copy`() {
        // Given
        val originalOrder = Order("order-123", "Original description")

        // When
        val copiedOrder = originalOrder.copy(description = "Updated description")

        // Then
        assertEquals(originalOrder.id, copiedOrder.id)
        assertEquals("Updated description", copiedOrder.description)
        assertNotEquals(originalOrder, copiedOrder)
    }

    @Test
    fun `should have proper toString representation`() {
        // Given
        val order = Order("order-123", "Test order")

        // When
        val toString = order.toString()

        // Then
        assertTrue(toString.contains("order-123"))
        assertTrue(toString.contains("Test order"))
    }

    @Test
    fun `should have proper hashCode implementation`() {
        // Given
        val order1 = Order("order-123", "Test order")
        val order2 = Order("order-123", "Test order")
        val order3 = Order("order-456", "Different order")

        // Then
        assertEquals(order1.hashCode(), order2.hashCode())
        assertNotEquals(order1.hashCode(), order3.hashCode())
    }
}
