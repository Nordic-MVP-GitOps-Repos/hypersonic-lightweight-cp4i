See:

* https://github.com/ibm-messaging/mq-exits/blob/master/channel/jmsjwtexit/README.md (Since this example was written JWKS support has been implemented.)
* https://community.ibm.com/community/user/integration/blogs/vasily-shcherbinin1/2024/06/19/introducing-jwks
* https://ibm-cloud.slack.com/archives/CACD10YCD/p1731575557512819?thread_ts=1731520229.420199&cid=CACD10YCD
* https://www.ibm.com/docs/en/ibm-mq/9.4?topic=wat-configuring-queue-manager-accept-authentication-tokens-using-jwks-endpoint


Steps to configure this should be 

1. Validate that we can get a token from the keycloak token endpoint for a user in keycloak:
    ```
    curl -s -X POST 'https://keycloak-cp4i.apps.t9xdnubu.eastus.aroapp.io/realms/cloudpak/protocol/openid-connect/token' -H "Content-Type: application/x-www-form-urlencoded" -d "username=integration-admin" -d 
    'password=<password>' -d 'grant_type=password' -d 'client_id=admin-cli' | jq -r '.access_token'
    ```
1. Identify keycloak JWKS endpoint - should be https://keycloak-cp4i.apps.t9xdnubu.eastus.aroapp.io/realms/master/protocol/openid-connect/certs (see https://keycloak-cp4i.apps.t9xdnubu.eastus.aroapp.io/realms/cloudpak/.well-known/openid-configuration)
1. Certificate can be fetched with:
    ```
    curl -s https://keycloak-cp4i.apps.t9xdnubu.eastus.aroapp.io/realms/master/protocol/openid-connect/certs | jq -r ' .keys[1].x5c[0]'
    ```
1. Create openshift secret with this certificate
1. Add the certificate to the QMs truststore (qm.yaml) and validate that the chain is ok. 
1. Setup qm.ini file to create outgoing connections by defining HTTPSKeyStore: https://www.ibm.com/docs/en/SSFKSJ_9.4.0/secure/create_key_repos_as_TLS_trust.html - or refer to these in the truststore already created by the operator?
1. Setup qm.ini file to use JKWS endpoint by defining JWKS stanza: https://www.ibm.com/docs/en/ibm-mq/9.4?topic=qmini-jwks-stanza-file
1. Compile and place jmsjwt exit jar files in container - or, write a new java application to illustrate this: https://www.ibm.com/docs/en/ibm-mq/9.4?topic=tokens-using-authentication-in-application - example here: https://github.com/Nordic-MVP-GitOps-Repos/liberty-sampleapp/blob/main/src/test/java/com/ibm/ce/jms/ClientTest.java
1. Compile client program and test.
