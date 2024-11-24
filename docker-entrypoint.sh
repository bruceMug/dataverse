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

# Initialize Dataverse if not already initialized
if [ ! -f "/dv/.initialized" ]; then
    echo "Initializing Dataverse..."
    
    # Wait for application to be ready
    until curl -s http://localhost:8080/api/info/version > /dev/null; do
        echo "Waiting for Dataverse to start..."
        sleep 5
    done
    
    # Run initialization scripts
    if [ -f "/opt/dataverse/scripts/setup-all.sh" ]; then
        echo "Running setup-all.sh..."
        bash /opt/dataverse/scripts/setup-all.sh
    else
        echo "Creating root dataverse..."
        curl -X POST -H "Content-type:application/json" http://localhost:8080/api/dataverses/:root \
            -d "{\"alias\":\"root\",\"name\":\"Root\",\"dataverseContacts\":[{\"contactEmail\":\"${ADMIN_EMAIL}\"}],\"affiliation\":\"${ADMIN_INSTITUTION}\"}"
    fi
    
    touch /dv/.initialized
fi

# Stop domain to restart with new configuration
${PAYARA_DIR}/bin/asadmin stop-domain

# Start Payara in the foreground
exec ${PAYARA_DIR}/bin/asadmin start-domain --verbose





# OLDER FILE CONTENTS
# !/bin/bash
# set -e

# # Wait for database
# echo "Waiting for database..."
# while ! nc -z ${DATAVERSE_DB_HOST} 5432; do
#   sleep 1
# done
# echo "Database is up"

# # Start Payara in the background
# ${PAYARA_DIR}/bin/asadmin start-domain

# # Configure admin password if not already configured
# if ! ${PAYARA_DIR}/bin/asadmin --user=${ADMIN_USER} --passwordfile=/tmp/pwd.txt list-domains; then
#     echo "AS_ADMIN_PASSWORD=" > /tmp/pwd.txt
#     echo "AS_ADMIN_NEWPASSWORD=${ADMIN_PASSWORD}" >> /tmp/pwd.txt
#     ${PAYARA_DIR}/bin/asadmin --user=${ADMIN_USER} --passwordfile=/tmp/pwd.txt change-admin-password
#     rm /tmp/pwd.txt
    
#     echo "AS_ADMIN_PASSWORD=${ADMIN_PASSWORD}" > /tmp/pwd.txt
#     ${PAYARA_DIR}/bin/asadmin --user=${ADMIN_USER} --passwordfile=/tmp/pwd.txt enable-secure-admin
#     rm /tmp/pwd.txt
# fi

# # Stop domain to restart with new configuration
# ${PAYARA_DIR}/bin/asadmin stop-domain

# # Start Payara in the foreground
# exec ${PAYARA_DIR}/bin/asadmin start-domain --verbose
