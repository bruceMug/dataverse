# Build stage
FROM maven:3.8-eclipse-temurin-17 AS builder

# Copy the source code
COPY . /build/
WORKDIR /build

# Build the application
RUN mvn -P api clean package  # Adjust the profile as needed

# Production image
FROM eclipse-temurin:17-jdk  # A basic JDK image for running the JAR

# Copy the JAR file from the builder stage
COPY --from=builder /build/target/dataverse-*.jar /app/dataverse.jar

# Create necessary directories
RUN mkdir -p /dv/exporters /dv/lang /data/store /secrets

# Environment variables
ENV LANG=en \
    DATAVERSE_JSF_REFRESH_PERIOD=1 \
    DATAVERSE_FEATURE_API_BEARER_AUTH=1

# Expose necessary ports
EXPOSE 8080 4848 8686

# Health check (adjust path if the app uses a different endpoint)
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api/info/version || exit 1

# Run the JAR file directly
CMD ["java", "-jar", "/app/dataverse.jar"]