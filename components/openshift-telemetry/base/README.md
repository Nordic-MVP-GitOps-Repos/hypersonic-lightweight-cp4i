# Tempo configuration

Make sure a secret is created to configure the S3 storage for Tempo according to instructions at
<https://docs.openshift.com/container-platform/4.15/observability/distr_tracing/distr_tracing_tempo/distr-tracing-tempo-installing.html#installing-a-tempostack-instance>

Make sure the name is `tempostack-s3`. See example below for bucket created with ODF as defined in [objectstorageclaim.yaml](./blob/main/components/openshift-telemetry/variants/cloudprovider/odf/objectstorageclaim.yaml)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tempostack-s3
  namespace: openshift-tempo-operator
stringData:
  endpoint: https://s3.openshift-storage.svc:443
  bucket: tempo-bucket
  access_key_id: <access key>
  access_key_secret: <secret key>
type: Opaque
```
