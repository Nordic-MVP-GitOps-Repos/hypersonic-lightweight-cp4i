Sample illustrating mapping from a certificate cn to a MCAUSER. To setup a keystore for testing with MQ Explorer, download tls.crt and tls.key from 'mq-client-certificate-tls-secret' and do:

```
openssl pkcs12 -export -in tls.crt -inkey tls.key -out certificate.p12 -name “certificate”
keytool -importkeystore -srckeystore certificate.p12 -srcstoretype pkcs12 -destkeystore keystore-client.jks
```

See also https://community.ibm.com/community/user/integration/blogs/arthur-barr/2022/11/24/authenticating-to-ibm-mq-using-tls-certificates
