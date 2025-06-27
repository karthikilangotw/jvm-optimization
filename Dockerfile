# Simplified Dockerfile using pre-built JAR from libs folder
FROM amazoncorretto:21-al2023
WORKDIR /app

# Install shadow-utils for user management in AL2023
RUN yum update -y && yum install -y shadow-utils && yum clean all

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Create directories for logs and dumps
RUN mkdir -p /app/logs /app/dumps && \
    chown -R appuser:appuser /app

# Copy the pre-built JAR from host libs folder
COPY build/libs/demo-0.0.1-SNAPSHOT.jar app.jar
RUN chown appuser:appuser app.jar

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# JVM optimization settings
ENTRYPOINT ["java", \
    # GC Settings - Using G1GC
    "-XX:+UseG1GC", \
    "-XX:MaxGCPauseMillis=200", \
    # Memory Settings
    "-XX:MaxRAMPercentage=75.0", \
    "-XX:InitialRAMPercentage=50.0", \
    # Performance Optimizations
    "-XX:+OptimizeStringConcat", \
    "-XX:+UseStringDeduplication", \
    # Monitoring and Debugging
    "-XX:+HeapDumpOnOutOfMemoryError", \
    "-XX:HeapDumpPath=/app/dumps/", \
    # Startup optimization
    "-XX:+TieredCompilation", \
    "-XX:TieredStopAtLevel=1", \
    # Run the application
    "-jar", "app.jar"]
