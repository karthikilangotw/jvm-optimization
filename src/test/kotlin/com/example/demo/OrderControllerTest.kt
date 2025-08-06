package com.example.demo

import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
import io.mockk.verify
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*

@WebMvcTest(OrderController::class)
class OrderControllerTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @MockkBean
    private lateinit var orderService: OrderService

    @Test
    fun `should create order successfully`() {
        // Given
        val order = Order("order-123", "Test order")
        every { orderService.createOrder(order) } returns order

        // When & Then
        mockMvc.perform(
            post("/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""{"id": "order-123", "description": "Test order"}""")
        )
            .andExpect(status().isOk)
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.id").value("order-123"))
            .andExpect(jsonPath("$.description").value("Test order"))

        verify { orderService.createOrder(order) }
    }

    @Test
    fun `should get order by id successfully`() {
        // Given
        val order = Order("order-123", "Test order")
        every { orderService.getOrder("order-123") } returns order

        // When & Then
        mockMvc.perform(get("/orders/order-123"))
            .andExpect(status().isOk)
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.id").value("order-123"))
            .andExpect(jsonPath("$.description").value("Test order"))

        verify { orderService.getOrder("order-123") }
    }

    @Test
    fun `should return empty response when order not found`() {
        // Given
        every { orderService.getOrder("non-existent") } returns null

        // When & Then
        mockMvc.perform(get("/orders/non-existent"))
            .andExpect(status().isOk)
            .andExpect(content().string(""))

        verify { orderService.getOrder("non-existent") }
    }

    @Test
    fun `should get all orders successfully`() {
        // Given
        val orders = listOf(
            Order("order-1", "First order"),
            Order("order-2", "Second order"),
            Order("order-3", "Third order")
        )
        every { orderService.getAllOrders() } returns orders

        // When & Then
        mockMvc.perform(get("/orders"))
            .andExpect(status().isOk)
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.length()").value(3))
            .andExpect(jsonPath("$[0].id").value("order-1"))
            .andExpect(jsonPath("$[0].description").value("First order"))
            .andExpect(jsonPath("$[1].id").value("order-2"))
            .andExpect(jsonPath("$[1].description").value("Second order"))
            .andExpect(jsonPath("$[2].id").value("order-3"))
            .andExpect(jsonPath("$[2].description").value("Third order"))

        verify { orderService.getAllOrders() }
    }

    @Test
    fun `should return empty array when no orders exist`() {
        // Given
        every { orderService.getAllOrders() } returns emptyList()

        // When & Then
        mockMvc.perform(get("/orders"))
            .andExpect(status().isOk)
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.length()").value(0))

        verify { orderService.getAllOrders() }
    }

    @Test
    fun `should handle malformed JSON in create order`() {
        // When & Then
        mockMvc.perform(
            post("/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""{"invalid": "json", "missing": "required_fields"}""")
        )
            .andExpect(status().isBadRequest)
    }

    @Test
    fun `should handle missing content type in create order`() {
        // When & Then
        mockMvc.perform(
            post("/orders")
                .content("""{"id": "order-123", "description": "Test order"}""")
        )
            .andExpect(status().isUnsupportedMediaType)
    }

    @Test
    fun `should handle empty request body in create order`() {
        // When & Then
        mockMvc.perform(
            post("/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content("")
        )
            .andExpect(status().isBadRequest)
    }

    @Test
    fun `should handle special characters in order id path variable`() {
        // Given
        val orderId = "order-with-special-chars-123"
        val order = Order(orderId, "Test order with special chars")
        every { orderService.getOrder(orderId) } returns order

        // When & Then
        mockMvc.perform(get("/orders/$orderId"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.id").value(orderId))

        verify { orderService.getOrder(orderId) }
    }
}
