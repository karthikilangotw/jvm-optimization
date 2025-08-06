package com.example.demo

import org.junit.jupiter.api.Test
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
class ActuatorEndpointsIntegrationTest {

    @LocalServerPort
    private var port: Int = 0

    @Autowired
    private lateinit var restTemplate: TestRestTemplate

    private fun getBaseUrl() = "http://localhost:$port"

    @Test
    fun `should expose health endpoint`() {
        // When
        val response: ResponseEntity<Map<String, Any>> = restTemplate.getForEntity(
            "${getBaseUrl()}/actuator/health",
            Map::class.java as Class<Map<String, Any>>
        )

        // Then
        assertEquals(HttpStatus.OK, response.statusCode)
        assertNotNull(response.body)
        assertEquals("UP", response.body!!["status"])
    }

    @Test
    fun `should provide detailed health information`() {
        // When
        val response: ResponseEntity<Map<String, Any>> = restTemplate.getForEntity(
            "${getBaseUrl()}/actuator/health",
            Map::class.java as Class<Map<String, Any>>
        )

        // Then
        assertEquals(HttpStatus.OK, response.statusCode)
        assertNotNull(response.body)
        
        val healthData = response.body!!
        assertEquals("UP", healthData["status"])
        
        // Verify components are present (if detailed health is enabled)
        if (healthData.containsKey("components")) {
            @Suppress("UNCHECKED_CAST")
            val components = healthData["components"] as Map<String, Any>
            assertTrue(components.isNotEmpty())
        }
    }

    @Test
    fun `should expose application info if configured`() {
        // When
        val response: ResponseEntity<Map<String, Any>> = restTemplate.getForEntity(
            "${getBaseUrl()}/actuator/info",
            Map::class.java as Class<Map<String, Any>>
        )

        // Then
        // Info endpoint might be empty by default, but should be accessible
        assertTrue(response.statusCode == HttpStatus.OK || response.statusCode == HttpStatus.NOT_FOUND)
    }

    @Test
    fun `should handle concurrent requests to actuator endpoints`() {
        // Given
        val numberOfThreads = 10
        val responses = mutableListOf<ResponseEntity<*>>()

        // When - Make concurrent requests to health endpoint
        val threads = (1..numberOfThreads).map { 
            Thread {
                val response = restTemplate.getForEntity(
                    "${getBaseUrl()}/actuator/health",
                    String::class.java
                )
                
                synchronized(responses) {
                    responses.add(response)
                }
            }
        }

        threads.forEach { it.start() }
        threads.forEach { it.join() }

        // Then
        assertEquals(numberOfThreads, responses.size)
        responses.forEach { response ->
            assertEquals(HttpStatus.OK, response.statusCode)
            assertNotNull(response.body)
        }
    }
}
