# ----------------------TEST 2 --------------------------------
# Build stage: Use Maven to build the application
FROM maven:3.8-eclipse-temurin-17 AS builder

WORKDIR /build
COPY . .
RUN mvn -Pct clean package -DskipTests -Ddocker.skip

RUN echo -e "\e[1;32m===== Listing the /build/target Directory =====\e[0m" && ls -l /build/target

# Production stage: Use Payara for deployment
FROM payara/server-full:6.2023.12-jdk17

# Create necessary directories for Dataverse
USER root
RUN mkdir -p /dv/exporters /dv/lang /data/store /secrets && \
    chown -R payara:payara /dv /data /secrets

ENV SCRIPT_DIR=/opt/payara/scripts \
    DEPLOY_DIR=/opt/payara/deployments \
    LANG=en \
    DATAVERSE_JSF_REFRESH_PERIOD=1 \
    DATAVERSE_FEATURE_API_BEARER_AUTH=1 \
    PAYARA_ARGS="--debug"

COPY --from=builder --chown=payara:payara /build/target/dataverse-*.jar $DEPLOY_DIR/dataverse.jar

USER payara

# WORKDIR /opt/payara

EXPOSE 8080 4848 8686 9009

HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api/info/version || exit 1

# Start Payara server using its default entrypoint script
CMD ["/opt/payara/scripts/entrypoint.sh", "--debug"]