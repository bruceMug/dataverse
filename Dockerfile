# Use a multi-stage build
FROM maven:3.8-openjdk-17 AS builder

# Set working directory
WORKDIR /build

# Copy the source code
COPY . .

# Build the application
RUN mvn -Pct clean package -DskipTests

# Final image
FROM payara/server-full:5.2022.5-jdk17

# Set environment variables
ENV PAYARA_ARGS "--debug --postbootcommandfile /opt/payara/dataverse/setup-all.asadmin"

# Copy the built application
COPY --from=builder /build/target/dataverse-*.war ${DEPLOY_DIR}/dataverse.war

# Copy configuration files
COPY conf/docker/dataverse/setup-all.asadmin /opt/payara/dataverse/
COPY conf/docker/dataverse/bin/* /opt/payara/dataverse/bin/

# Make scripts executable
RUN chmod +x /opt/payara/dataverse/bin/*

# Set the working directory
WORKDIR /opt/payara

# Expose necessary ports
EXPOSE 8080 4848 9009

# Start Payara
CMD ["bin/entrypoint.sh"]





# ----------------------TEST 2 --------------------------------
# Build stage: Use Maven to build the application
# FROM maven:3.8-eclipse-temurin-17 AS builder

# WORKDIR /build
# COPY . .
# RUN mvn -Pct clean package -DskipTests -Ddocker.skip

# RUN echo -e "\e[1;32m===== Listing the /build/target Directory =====\e[0m" && ls -l /build/target

# # Production stage: Use Payara for deployment
# FROM payara/server-full:6.2023.12-jdk17

# # Create necessary directories for Dataverse
# USER root
# RUN mkdir -p /dv/exporters /dv/lang /data/store /secrets && \
#     chown -R payara:payara /dv /data /secrets

# ENV SCRIPT_DIR=/opt/payara/scripts \
#     DEPLOY_DIR=/opt/payara/deployments \
#     LANG=en \
#     DATAVERSE_JSF_REFRESH_PERIOD=1 \
#     DATAVERSE_FEATURE_API_BEARER_AUTH=1 \
#     PAYARA_ARGS="--debug"

# COPY --from=builder --chown=payara:payara /build/target/dataverse-*.jar $DEPLOY_DIR/dataverse.jar

# USER payara

# # WORKDIR /opt/payara

# EXPOSE 8080 4848 8686 9009

# HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
#     CMD curl -f http://localhost:8080/api/info/version || exit 1

# # Start Payara server using its default entrypoint script
# CMD ["/opt/payara/scripts/entrypoint.sh", "--debug"]




# ----------------------TEST 1 --------------------------------
# # Build stage
# FROM maven:3.8-eclipse-temurin-17 AS builder

# WORKDIR /build
# COPY . .
# RUN mvn -P api clean package -DskipTests

# # Production stage
# FROM payara/server-full:6.2023.12-jdk17

# # Create necessary directories
# USER root
# RUN mkdir -p /dv/exporters /dv/lang /data/store /secrets && \
#     chown -R payara:payara /dv /data /secrets

# # Copy application from builder
# COPY --from=builder --chown=payara:payara /build/target/dataverse-*.war $DEPLOY_DIR/dataverse.war

# COPY --chown=payara:payara scripts/api/* /opt/dataverse/scripts/
# COPY --chown=payara:payara conf/* /opt/dataverse/conf/

# # Switch to payara user for security
# USER payara

# # Health check
# HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
#     CMD curl -f http://localhost:8080/api/info/version || exit 1

# # Default environment variables
# ENV LANG=en \
#     DATAVERSE_JSF_REFRESH_PERIOD=1 \
#     DATAVERSE_FEATURE_API_BEARER_AUTH=1 \
#     DEPLOY_DIR=/opt/payara/deployments \
#     PAYARA_DIR=/opt/payara \
#     SCRIPT_DIR=/opt/payara/scripts \
#     PAYARA_ARGS="--debug"

# # Expose necessary ports
# EXPOSE 8080 4848 8686 9009

# # CMD ["asadmin", "start-domain", "--verbose"]

# COPY --chown=payara:payara docker-entrypoint.sh /opt/payara/scripts/
# RUN chmod +x /opt/payara/scripts/docker-entrypoint.sh

# ENTRYPOINT ["/opt/payara/scripts/docker-entrypoint.sh"]