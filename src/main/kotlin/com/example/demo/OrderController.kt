package com.example.demo

import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/orders")
class OrderController(
    private val orderService: OrderService,
) {

    @PostMapping
    fun createOrder(@RequestBody order: Order): Order {
        return orderService.createOrder(order)
    }

    @GetMapping("/{id}")
    fun getOrder(@PathVariable id: String): Order? {
        return orderService.getOrder(id)
    }

    @GetMapping
    fun getAllOrders(): List<Order> {
        return orderService.getAllOrders()
    }
}
