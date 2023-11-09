#!/bin/bash

#   Copyright 2023 IBM Corp. All Rights Reserved.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# exit when any command fails
set -e

# allow this script to be run from other locations, despite the
#  relative file paths used in it
if [[ $BASH_SOURCE = */* ]]; then
    cd -- "${BASH_SOURCE%/*}/" || exit
fi

cookieCurlParams() {
    USERNAME="${1}"
    COOKIE_JAR="/tmp/${USERNAME}-cookies.txt"
    echo -n "-b ${COOKIE_JAR} -c ${COOKIE_JAR}"
}

csrfHeader() {
    USERNAME="${1}"
    COOKIE_JAR="/tmp/${USERNAME}-cookies.txt"
    CSRF=($(cat -v ${COOKIE_JAR} | grep "ibm-ei-csrf-token"))
    CSRF_TOKEN="${CSRF[6]}"
    CSRF_TOKEN="${CSRF_TOKEN//^M/}"
    echo -n "x-ibm-ei-csrf-token: ${CSRF_TOKEN}"
}

login() {
    echo "Logging in as ${1}"
    USERNAME="${1}"
    PASSWORD="${2}"
    # count the number of times we have tried this
    #  default to "first" attempt if not specified
    ATTEMPT=${3:-1}

    COOKIE_JAR="/tmp/${USERNAME}-cookies.txt"
    HEADERS_FILE="/tmp/login-response-headers.txt"

    # Trigger redirect and capture response
    REDIRECT_RESPONSE=$(curl -f -k -s ${EEM_API} -c ${COOKIE_JAR} || true)
    if [ -z "$REDIRECT_RESPONSE" ]
    then
        echo "Login unsuccessful."
        if [[ $ATTEMPT -lt 5 ]]
        then
            echo "Retrying..."
            sleep 2
            login $USERNAME $PASSWORD $((ATTEMPT+=1))
            return
        else
            exit 1
        fi
    fi

    # Parse the response to identify callback URL
    PARTS=($(echo $REDIRECT_RESPONSE | tr "?" " "))
    QUERY=${PARTS[3]}
    QUERY_PARAMS=($(echo $QUERY | tr "&" " "))

    # Use response state to login as user and capture callback
    curl -k -f "${EEM_API}/login/oauth/authorize/login" -F "username=${USERNAME}" -F "password=${PASSWORD}" -F ${QUERY_PARAMS[0]} -D ${HEADERS_FILE}
    LOCATION=($(cat -v ${HEADERS_FILE} | grep location))
    CALLBACK="${LOCATION[1]}"
    CALLBACK="${CALLBACK//^M/}"
    rm ${HEADERS_FILE}

    # Call callback
    curl -s -k "${CALLBACK}" $(cookieCurlParams ${USERNAME}) -o /dev/null

    # Print user and grab CSRF
    echo "Authenticated user"
    curl -k "${EEM_API}/auth/protected/userinfo" $(cookieCurlParams ${USERNAME}) -s -o /dev/null
}

exportAsyncApi() {
   
    echo "Exporting asyncapi for ${1}"
    TOPICID="${1}"

    EEMTOPICDEFINITION=$(curl -X GET -s -k $(cookieCurlParams ${CURRENT_USER}) \
    -H "$(csrfHeader ${CURRENT_USER})" \
    -H "Content-Type: application/json" \
    $EEM_API/api/eem/catalogues/entries/$TOPICID)

    echo "$TOPICDEFINITION" 

    ASYNCAPI=$(curl -X POST -s -k $(cookieCurlParams ${CURRENT_USER}) \
    -H "$(csrfHeader ${CURRENT_USER})" \
    -H "Content-Type: application/json" \
    -d '{"addXIBMConfiguration":true}' \
    $EEM_API/api/eem/catalogues/default/entry/$TOPICID/export)

    echo "$ASYNCAPI" | yq ' .info.title'
    echo "$ASYNCAPI"
}

# get the namespace from a command line argument
NAMESPACE=$1

# get location of the EEM manager (also useful for checking that oc login has been run)
EEM_API=$(oc get route -n $NAMESPACE my-eem-manager-ibm-eem-manager -ojsonpath='https://{.spec.host}')


# check namespace option provided
if [ $# -eq 0 ]; then
    >&2 echo "Usage: export-asyncapidefs.sh <NAMESPACE>"
    exit 1
fi

# --------------------------------------
# Login
#
#  login with various users
# --------------------------------------

echo "> Logging into EEM manager"

# TODO - get credentials dynamically
CURRENT_USER=eem-admin
PWD='Th1$ISTh3Adm1nPa$SW0Rd'
login ${CURRENT_USER} ${PWD}

echo "> Listing and exporting Kafka topics"

curl -X GET -s -k $(cookieCurlParams ${CURRENT_USER}) \
    -H "$(csrfHeader ${CURRENT_USER})" \
    -H "Content-Type: application/json" \
    $EEM_API/api/eem/catalogues/entries | jq -r '. [].id' | while read -r topic; do exportAsyncApi "$topic"; done