package com.jvm.optimization.demo

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.lang.management.ManagementFactory
import java.lang.management.MemoryMXBean
import java.lang.management.GarbageCollectorMXBean
import java.lang.management.RuntimeMXBean
import java.lang.management.ThreadMXBean
import java.lang.management.OperatingSystemMXBean

@RestController
@RequestMapping("/jvm")
class JvmMetricsController {

    @GetMapping("/metrics")
    fun getJvmMetrics(): JvmMetrics {
        val memoryBean = ManagementFactory.getMemoryMXBean()
        val runtimeBean = ManagementFactory.getRuntimeMXBean()
        val threadBean = ManagementFactory.getThreadMXBean()
        val osBean = ManagementFactory.getOperatingSystemMXBean()
        val gcBeans = ManagementFactory.getGarbageCollectorMXBeans()

        return JvmMetrics(
            memory = MemoryInfo(
                heapUsed = memoryBean.heapMemoryUsage.used,
                heapMax = memoryBean.heapMemoryUsage.max,
                heapCommitted = memoryBean.heapMemoryUsage.committed,
                nonHeapUsed = memoryBean.nonHeapMemoryUsage.used,
                nonHeapMax = memoryBean.nonHeapMemoryUsage.max,
                nonHeapCommitted = memoryBean.nonHeapMemoryUsage.committed
            ),
            runtime = RuntimeInfo(
                uptime = runtimeBean.uptime,
                startTime = runtimeBean.startTime,
                vmName = runtimeBean.vmName,
                vmVersion = runtimeBean.vmVersion,
                vmVendor = runtimeBean.vmVendor,
                javaVersion = System.getProperty("java.version"),
                javaVendor = System.getProperty("java.vendor")
            ),
            threads = ThreadInfo(
                threadCount = threadBean.threadCount,
                peakThreadCount = threadBean.peakThreadCount,
                daemonThreadCount = threadBean.daemonThreadCount,
                totalStartedThreadCount = threadBean.totalStartedThreadCount
            ),
            operatingSystem = OperatingSystemInfo(
                name = osBean.name,
                version = osBean.version,
                arch = osBean.arch,
                availableProcessors = osBean.availableProcessors
            ),
            garbageCollection = gcBeans.map { gcBean ->
                GarbageCollectorInfo(
                    name = gcBean.name,
                    collectionCount = gcBean.collectionCount,
                    collectionTime = gcBean.collectionTime
                )
            }
        )
    }

    @GetMapping("/memory")
    fun getMemoryMetrics(): MemoryInfo {
        val memoryBean = ManagementFactory.getMemoryMXBean()
        return MemoryInfo(
            heapUsed = memoryBean.heapMemoryUsage.used,
            heapMax = memoryBean.heapMemoryUsage.max,
            heapCommitted = memoryBean.heapMemoryUsage.committed,
            nonHeapUsed = memoryBean.nonHeapMemoryUsage.used,
            nonHeapMax = memoryBean.nonHeapMemoryUsage.max,
            nonHeapCommitted = memoryBean.nonHeapMemoryUsage.committed
        )
    }

    @GetMapping("/gc")
    fun getGarbageCollectionMetrics(): List<GarbageCollectorInfo> {
        val gcBeans = ManagementFactory.getGarbageCollectorMXBeans()
        return gcBeans.map { gcBean ->
            GarbageCollectorInfo(
                name = gcBean.name,
                collectionCount = gcBean.collectionCount,
                collectionTime = gcBean.collectionTime
            )
        }
    }

    @GetMapping("/threads")
    fun getThreadMetrics(): ThreadInfo {
        val threadBean = ManagementFactory.getThreadMXBean()
        return ThreadInfo(
            threadCount = threadBean.threadCount,
            peakThreadCount = threadBean.peakThreadCount,
            daemonThreadCount = threadBean.daemonThreadCount,
            totalStartedThreadCount = threadBean.totalStartedThreadCount
        )
    }
}

data class JvmMetrics(
    val memory: MemoryInfo,
    val runtime: RuntimeInfo,
    val threads: ThreadInfo,
    val operatingSystem: OperatingSystemInfo,
    val garbageCollection: List<GarbageCollectorInfo>
)

data class MemoryInfo(
    val heapUsed: Long,
    val heapMax: Long,
    val heapCommitted: Long,
    val nonHeapUsed: Long,
    val nonHeapMax: Long,
    val nonHeapCommitted: Long
)

data class RuntimeInfo(
    val uptime: Long,
    val startTime: Long,
    val vmName: String,
    val vmVersion: String,
    val vmVendor: String,
    val javaVersion: String,
    val javaVendor: String
)

data class ThreadInfo(
    val threadCount: Int,
    val peakThreadCount: Int,
    val daemonThreadCount: Int,
    val totalStartedThreadCount: Long
)

data class OperatingSystemInfo(
    val name: String,
    val version: String,
    val arch: String,
    val availableProcessors: Int
)

data class GarbageCollectorInfo(
    val name: String,
    val collectionCount: Long,
    val collectionTime: Long
)
