package com.jvm.optimization.demo

import io.micrometer.core.instrument.Counter
import io.micrometer.core.instrument.Timer
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/orders")
class OrderController(
    private val orderService: OrderService,
    private val orderCounter: Counter,
    private val orderProcessingTimer: Timer
) {

    @PostMapping
    fun createOrder(@RequestBody order: Order): Order {
        return orderProcessingTimer.recordCallable {
            val result = orderService.createOrder(order)
            orderCounter.increment()
            result
        }!!
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
