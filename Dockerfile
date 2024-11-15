# Build stage
FROM maven:3.8-eclipse-temurin-17 AS builder

# Copy the source code
COPY . /build/
WORKDIR /build

# Build the application
RUN mvn -P api clean package

# Production image with Payara
FROM eclipse-temurin:17-jdk

# Install Payara Server
ENV PAYARA_VERSION=5.2022.2
RUN curl -L https://search.maven.org/remotecontent?filepath=fish/payara/distributions/payara/${PAYARA_VERSION}/payara-${PAYARA_VERSION}.zip -o /tmp/payara.zip && \
    unzip /tmp/payara.zip -d /opt && \
    rm /tmp/payara.zip

# Set up Payara and copy necessary files
ENV PAYARA_HOME /opt/payara5
ENV PATH "$PAYARA_HOME/bin:$PATH"
COPY --from=builder /build/target/dataverse-*.jar $PAYARA_HOME/deployments/dataverse.war

# Create necessary directories
RUN mkdir -p /dv/exporters /dv/lang /data/store /secrets

# Expose necessary ports
EXPOSE 8080 4848 8686

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api/info/version || exit 1

# Environment variables for Payara configuration
ENV LANG=en \
    DATAVERSE_JSF_REFRESH_PERIOD=1 \
    DATAVERSE_FEATURE_API_BEARER_AUTH=1

# Set JVM arguments for deployment
ENV JVM_ARGS "-Ddataverse.files.storage-driver-id=file1 \
              -Ddataverse.files.file1.type=file \
              -Ddataverse.files.file1.directory=/data/store"

# Start Payara Server
CMD ["asadmin", "start-domain", "--verbose"]



















# # Build stage
# FROM maven:3.8-eclipse-temurin-17 AS builder

# # Copy the source code
# COPY . /build/
# WORKDIR /build

# # Build the application
# RUN mvn -P api clean package

# # Production image
# FROM eclipse-temurin:17-jdk

# # Copy the JAR file from the builder stage
# COPY --from=builder /build/target/dataverse-*.jar /app/dataverse.jar

# # Create necessary directories
# RUN mkdir -p /dv/exporters /dv/lang /data/store /secrets

# # Environment variables
# ENV LANG=en \
#     DATAVERSE_JSF_REFRESH_PERIOD=1 \
#     DATAVERSE_FEATURE_API_BEARER_AUTH=1

# # Expose necessary ports
# EXPOSE 8080 4848 8686

# # Health check (adjust path if the app uses a different endpoint)
# HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
#     CMD curl -f http://localhost:8080/api/info/version || exit 1

# # Run the JAR file directly
# CMD ["java", "-jar", "/app/dataverse.jar"]