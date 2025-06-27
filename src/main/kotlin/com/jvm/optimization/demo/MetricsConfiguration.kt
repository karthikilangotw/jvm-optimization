package com.jvm.optimization.demo

import io.micrometer.core.instrument.Counter
import io.micrometer.core.instrument.Gauge
import io.micrometer.core.instrument.MeterRegistry
import io.micrometer.core.instrument.Timer
import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Bean
import java.lang.management.ManagementFactory
import java.util.concurrent.atomic.AtomicInteger

@Configuration
class MetricsConfiguration {

    @Bean
    fun orderCounter(meterRegistry: MeterRegistry): Counter {
        return Counter.builder("orders_created_total")
            .description("Total number of orders created")
            .register(meterRegistry)
    }

    @Bean
    fun orderProcessingTimer(meterRegistry: MeterRegistry): Timer {
        return Timer.builder("order_processing_duration_seconds")
            .description("Time taken to process orders")
            .register(meterRegistry)
    }

    @Bean
    fun activeOrdersGauge(meterRegistry: MeterRegistry, orderService: OrderService): Gauge {
        return Gauge.builder("orders_active_count") { orderService.getAllOrders().size.toDouble() }
            .description("Number of active orders in memory")
            .register(meterRegistry)
    }

    @Bean
    fun jvmCustomMetrics(meterRegistry: MeterRegistry): List<Gauge> {
        val memoryBean = ManagementFactory.getMemoryMXBean()
        val threadBean = ManagementFactory.getThreadMXBean()
        
        val gauges = mutableListOf<Gauge>()
        
        // Custom JVM memory metrics
        gauges.add(
            Gauge.builder("jvm_memory_heap_utilization_ratio") {
                val used = memoryBean.heapMemoryUsage.used.toDouble()
                val max = memoryBean.heapMemoryUsage.max.toDouble()
                if (max > 0) used / max else 0.0
            }
            .description("Heap memory utilization ratio")
            .register(meterRegistry)
        )

        gauges.add(
            Gauge.builder("jvm_memory_nonheap_utilization_ratio") {
                val used = memoryBean.nonHeapMemoryUsage.used.toDouble()
                val max = memoryBean.nonHeapMemoryUsage.max.toDouble()
                if (max > 0) used / max else 0.0
            }
            .description("Non-heap memory utilization ratio")
            .register(meterRegistry)
        )

        // Thread metrics
        gauges.add(
            Gauge.builder("jvm_threads_daemon_ratio") {
                val total = threadBean.threadCount.toDouble()
                val daemon = threadBean.daemonThreadCount.toDouble()
                if (total > 0) daemon / total else 0.0
            }
            .description("Ratio of daemon threads to total threads")
            .register(meterRegistry)
        )
        
        return gauges
    }
}
