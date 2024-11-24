# Build stage
FROM maven:3.8-eclipse-temurin-17 AS builder

WORKDIR /build
COPY . .
RUN mvn -P api clean package -DskipTests

# Production stage
FROM payara/server-full:6.2023.12-jdk17

# Create necessary directories
USER root
RUN mkdir -p /dv/exporters /dv/lang /data/store /secrets && \
    chown -R payara:payara /dv /data /secrets

# Copy application from builder
COPY --from=builder --chown=payara:payara /build/target/dataverse-*.war $DEPLOY_DIR/dataverse.war
COPY --from=builder /build/scripts/api /opt/payara/scripts

COPY --chown=payar:payara scripts/* /opt/dataverse/scripts/

COPY --chown=payara:payara conf/default/* /opt/dataverse/default/
COPY --chown=payara:payara conf/lang/* /dv/lang/

# Switch to payara user for security
USER payara

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api/info/version || exit 1

# Default environment variables
ENV LANG=en \
    DATAVERSE_JSF_REFRESH_PERIOD=1 \
    DATAVERSE_FEATURE_API_BEARER_AUTH=1 \
    DEPLOY_DIR=/opt/payara/deployments \
    PAYARA_DIR=/opt/payara \
    SCRIPT_DIR=/opt/payara/scripts \
    PAYARA_ARGS="--debug"

# Expose necessary ports
EXPOSE 8080 4848 8686 9009

# CMD ["asadmin", "start-domain", "--verbose"]

COPY --chown=payara:payara docker-entrypoint.sh /opt/payara/scripts/
RUN chmod +x /opt/payara/scripts/docker-entrypoint.sh

ENTRYPOINT ["/opt/payara/scripts/docker-entrypoint.sh"]