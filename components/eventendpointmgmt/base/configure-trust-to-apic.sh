#Based on instructions here: https://ibm.github.io/event-automation/eem/integrating-with-apic/configure-eem-for-apic/
# To setup trust we need to the CA from API Connect and the platform API uri
# Find API Connect platform api endpoint

apic_platform_uri=$(oc get -n cp4i apiconnectcluster/apic-cluster -o json | jq '.status.endpoints | .[] | select(.name=="platformApi") | .uri')

echo $apic_platform_uri

set -x 

# The certificate that EEM needs to trust is default-ssl in the CP4I namespace
# Create a new secret in the event automation namespace containing the CA from the cp4i namespace
rm -f /tmp/cert.crt
oc get secret -n cp4i default-ssl -o jsonpath="{.data['cert\.crt']}" | base64 -d > /tmp/cert.crt
oc create secret generic apim-cpd -n event-automation-ns --from-file=ca.crt=/tmp/cert.crt

# We can now configure eem to use the new secret.