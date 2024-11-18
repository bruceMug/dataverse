#!/bin/bash
set -e

# Wait for database
echo "Waiting for database..."
while ! nc -z ${DATAVERSE_DB_HOST} 5432; do
  sleep 1
done
echo "Database is up"

# Start Payara in the background
${PAYARA_DIR}/bin/asadmin start-domain

# Configure admin password if not already configured
if ! ${PAYARA_DIR}/bin/asadmin --user=${ADMIN_USER} --passwordfile=/tmp/pwd.txt list-domains; then
    echo "AS_ADMIN_PASSWORD=" > /tmp/pwd.txt
    echo "AS_ADMIN_NEWPASSWORD=${ADMIN_PASSWORD}" >> /tmp/pwd.txt
    ${PAYARA_DIR}/bin/asadmin --user=${ADMIN_USER} --passwordfile=/tmp/pwd.txt change-admin-password
    rm /tmp/pwd.txt
    
    echo "AS_ADMIN_PASSWORD=${ADMIN_PASSWORD}" > /tmp/pwd.txt
    ${PAYARA_DIR}/bin/asadmin --user=${ADMIN_USER} --passwordfile=/tmp/pwd.txt enable-secure-admin
    rm /tmp/pwd.txt
fi

# Stop domain to restart with new configuration
${PAYARA_DIR}/bin/asadmin stop-domain

# Start Payara in the foreground
exec ${PAYARA_DIR}/bin/asadmin start-domain --verbose