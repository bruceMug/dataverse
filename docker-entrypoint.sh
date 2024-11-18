#!/bin/bash

# Wait for database
echo "Waiting for database..."
while ! nc -z ${DATAVERSE_DB_HOST} 5432; do
  sleep 1
done
echo "Database is up"

# Start Payara
echo "Starting Payara Server..."
exec ${PAYARA_DIR}/bin/asadmin start-domain --verbose