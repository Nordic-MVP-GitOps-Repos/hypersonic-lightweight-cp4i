Sample illustrating mapping from a certificate cn to a MCAUSER. 

In [client-cert.yaml](client-cert.yaml) a commonName 'mqclient1' is defined, which is mapped to a principal 'mqclient1' in [configmap.yaml](configmap.yaml)

To setup a keystore for testing with MQ Explorer, download tls.crt and tls.key from 'mq-client-certificate-tls-secret' and do:

```
openssl pkcs12 -export -in tls.crt -inkey tls.key -out certificate.p12 -name “certificate”
keytool -importkeystore -srckeystore certificate.p12 -srcstoretype pkcs12 -destkeystore keystore-client.jks
```

Currently, the cert-utils-operator generated keystore.jks and truststore.jks can't be used with MQ Explorer since those use PKCS8 format. See: https://github.com/pavlo-v-chernykh/keystore-go/issues/52

See also https://community.ibm.com/community/user/integration/blogs/arthur-barr/2022/11/24/authenticating-to-ibm-mq-using-tls-certificates

If you're using a client that uses .kdb keystores, do:

* Paste the contents of tls.key and tls.crt into a single file combined.crt.
* Download ca.crt from mq-client-certificate-tls-secret
* Then create the key database and import the ca and client certificate:

```
/opt/mqm/bin/runmqakm -keydb -create -db key.kdb -pw <password> -type cms -expire 365 -stash
/opt/mqm/bin/runmqakm -cert -add -db key.kdb -label ca -file ca.crt -pw <password>
/opt/mqm/bin/runmqakm -cert -add -db key.kdb -label cert -file combined.crt -pw <password>
```
