package com.example.demo

import org.springframework.stereotype.Service
import java.util.concurrent.ConcurrentHashMap

@Service
class OrderService {
    private val orders = ConcurrentHashMap<String, Order>()

    fun createOrder(order: Order): Order {
        orders[order.id] = order
        return order
    }

    fun getOrder(id: String): Order? {
        return orders[id]
    }

    fun getAllOrders(): List<Order> {
        return orders.values.toList()
    }
}
