#!/bin/bash

# Define names of the objects we will create in APIC
KEYSTORE_NAME=eem-keystore
TRUSTSTORE_NAME=eem-truststore
TLS_CLIENT_PROFILE_NAME=eem-tls-client-profile
EVENT_GATEWAY_NAME=eem-gateway

# Define names of the existing CRs in OpenShift
EEM_MANAGER_CR_NAME=eventendpointmgr
EEM_GATEWAY_CR_NAME=quick-start-gw
EEM_NAMESPACE=cp4i
EEM_CA_SECRET_NAME=$EEM_MANAGER_CR_NAME-ibm-eem-manager-ca

# Directory to write and read files from
WORKING_DIR=/tmp/setup-remote-gw

APIC_CLIENT_CREDS=/Users/kjelllarsson/Downloads/credentials.json

# Setup working directory
rm -rf $WORKING_DIR
mkdir $WORKING_DIR

# Based on instructions here: https://ibm.github.io/event-automation/eem/integrating-with-apic/configure-eem-for-apic/
# Find the certificates that APIC needs to trust EEM

eem_cluster_ca=$(oc get secret -n $EEM_NAMESPACE $EEM_CA_SECRET_NAME -o jsonpath="{.data['ca\.crt']}" | base64 -d | jq -sR .)
eem_certificate=$(oc get secret -n $EEM_NAMESPACE $EEM_CA_SECRET_NAME -o jsonpath="{.data['tls\.crt']}" | base64 -d)
eem_private_key=$(oc get secret -n $EEM_NAMESPACE $EEM_CA_SECRET_NAME -o jsonpath="{.data['tls\.key']}" | base64 -d)

# Create truststore input file with the EEM CA for the APIC CLI to use 
truststore_json_payload='{"title":'${TRUSTSTORE_NAME}',
"name":'${TRUSTSTORE_NAME}',
"summary":"EEM Truststore",
"truststore":'${eem_cluster_ca}'}'

echo $truststore_json_payload > $WORKING_DIR/$TRUSTSTORE_NAME-IN.json

# Create keystore input file with EEM private key and cert for the APIC CLI to use
# Concatenate the certificate and private key
cert_and_key=$eem_certificate$eem_private_key
cert_and_key_json=$(echo "$cert_and_key" | jq -sR .)

keystore_json_payload='{"title":'${KEYSTORE_NAME}',
"name":'${KEYSTORE_NAME}',
"summary":"eem-keystore",
"keystore":'${cert_and_key_json}'}'

echo "$keystore_json_payload" > $WORKING_DIR/$KEYSTORE_NAME-IN.json

# Find the api connect platform api endpoint
platform_api_endpoint=$(oc get -n cp4i apiconnectcluster/apic-cluster -o json | jq -r '.status.endpoints | .[] | select(.name=="platformApi") | .uri')
echo 'Platform API endpoint is' $platform_api_endpoint

apic client-creds:clear
apic client-creds:set $APIC_CLIENT_CREDS
apic login --context admin --server $platform_api_endpoint --sso

# Create truststore
apic truststores:create $WORKING_DIR/$TRUSTSTORE_NAME-IN.json --org admin --server $platform_api_endpoint 
apic truststores:get $TRUSTSTORE_NAME --org admin --server $platform_api_endpoint --format json --fields "name,url" --output $WORKING_DIR

# Create keystore
apic keystores:create $WORKING_DIR/$KEYSTORE_NAME-IN.json --org admin --server $platform_api_endpoint
apic keystores:get $KEYSTORE_NAME --org admin --server $platform_api_endpoint --format json --fields "name,url" --output $WORKING_DIR

# Find the url references of the newly created truststore and keystore - will be
# used when creating the TLS client profile.
truststore_url=$(cat $WORKING_DIR/$TRUSTSTORE_NAME.json | jq ' .url ')
keystore_url=$(cat $WORKING_DIR/$KEYSTORE_NAME.json | jq ' .url ')

# Create TLS client profile input file for APIC CLI
tls_client_profile_json_payload='{"title":'${TLS_CLIENT_PROFILE_NAME}',
    "name":'${TLS_CLIENT_PROFILE_NAME}',
    "protocols": [
        "tls_v1.2",
        "tls_v1.3"
    ],
    "ciphers": [
        "TLS_AES_256_GCM_SHA384",
        "TLS_CHACHA20_POLY1305_SHA256",
        "TLS_AES_128_GCM_SHA256",
        "ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
        "ECDHE_ECDSA_WITH_AES_256_CBC_SHA384",
        "ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
        "ECDHE_ECDSA_WITH_AES_128_CBC_SHA256",
        "ECDHE_ECDSA_WITH_AES_256_CBC_SHA",
        "ECDHE_ECDSA_WITH_AES_128_CBC_SHA",
        "ECDHE_RSA_WITH_AES_256_GCM_SHA384",
        "ECDHE_RSA_WITH_AES_256_CBC_SHA384",
        "ECDHE_RSA_WITH_AES_128_GCM_SHA256",
        "ECDHE_RSA_WITH_AES_128_CBC_SHA256",
        "ECDHE_RSA_WITH_AES_256_CBC_SHA",
        "ECDHE_RSA_WITH_AES_128_CBC_SHA",
        "DHE_RSA_WITH_AES_256_GCM_SHA384",
        "DHE_RSA_WITH_AES_256_CBC_SHA256",
        "DHE_RSA_WITH_AES_128_GCM_SHA256",
        "DHE_RSA_WITH_AES_128_CBC_SHA256",
        "DHE_RSA_WITH_AES_256_CBC_SHA",
        "DHE_RSA_WITH_AES_128_CBC_SHA"
    ], "insecure_server_connections": true, 
    "keystore_url":'${keystore_url}',
    "truststore_url":'${truststore_url}' '}''

echo $tls_client_profile_json_payload > $WORKING_DIR/$TLS_CLIENT_PROFILE_NAME-IN.json

# Create the TLS client profile in APIC
apic tls-client-profiles:create $WORKING_DIR/$TLS_CLIENT_PROFILE_NAME-IN.json --org admin --server $platform_api_endpoint 

# Fetch the newly created profile - url reference will be used when creating the remote gateway.
apic tls-client-profiles:get $TLS_CLIENT_PROFILE_NAME:1.0.0 --org admin --server $platform_api_endpoint --format json --fields "name,url" --output $WORKING_DIR
tls_client_profile_url=$(cat $WORKING_DIR/$TLS_CLIENT_PROFILE_NAME.json | jq ' .url ')

# Find the management and gateway endpoints from EEM
eem_manager=$(oc get -n $EEM_NAMESPACE eventendpointmanagement $EEM_MANAGER_CR_NAME -o json | jq -r '.status.endpoints | .[] | select(.name=="apic") | .uri')

eem_gateway=$(oc get -n $EEM_NAMESPACE eventgateway $EEM_GATEWAY_CR_NAME -o json | jq -r '.status.endpoints | .[] | select(.name=="external-route-https") | .uri' | cut -c 9-):443

# Find the integration url for the gateway services integration
integration_url=$(apic integrations:list --server $platform_api_endpoint --subcollection gateway-service --format json --output - | jq -r '.results | .[] | select(.name=="event-gateway") | .url')

# Find the default TLS server profile for the SNI stanza
default_tls_server_profile_url=$(apic tls-server-profiles:get tls-server-profile-default:1.0.0 --server $platform_api_endpoint --org admin --output - --format json  | jq ' .url')

# Create remote gateway input file for APIC CLI
gateway_json_payload='{"title":'${EVENT_GATEWAY_NAME}',
"name":'${EVENT_GATEWAY_NAME}',
"summary":"eem-gateway",
"type": "gateway_service",
 "sni": [
        {"host": "*", "tls_server_profile_url": '${default_tls_server_profile_url}'}
    ],
"gateway_service_type": "event-gateway",
"integration_url": '${integration_url}',
"tls_client_profile_url": '${tls_client_profile_url}', 
"api_endpoint_base": '${eem_gateway}',
"endpoint": '${eem_manager}' '}''

echo $gateway_json_payload > $WORKING_DIR/$EVENT_GATEWAY_NAME-IN.json

# Create the remote gateway
apic gateway-services:create $WORKING_DIR/$EVENT_GATEWAY_NAME-IN.json --org admin --server $platform_api_endpoint --availability-zone availability-zone-default

# TODO:
# Assign the remote gateway to the Sandbox catalog of the provider organization.
# Requires logging in to the provider organization.