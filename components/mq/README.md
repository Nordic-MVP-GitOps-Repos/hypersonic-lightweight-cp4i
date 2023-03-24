TLS is required on the Queue Manager side to connect from outside the cluster since TLS-SNI is used to route to the correct Queue Manager in the cluster. Two options exist for what gets sent by the client in the SNI header, either the Channel name or the Hostname. 

If the Channel name is used to route, the Channel name must be unique in the cluster and a [TLS-SNI route](components/mq/base/native-ha-qm/sni-route.yaml) that maps from the channel name to the MQ OpenShift service needs to be setup. 

If hostname is used, no TLS-SNI route is needed and there is no constraint on channel name uniqueness (but there is no possibility of different certs for different channels in the same QM)

To connect to a QM in OpenShift from MQ Explorer using hostname, setup your QM with self-signed certificates as shown here [qm.yaml](components/mq/base/native-ha-qm/qm.yaml) and in eclipse.ini for MQ Explorer, add a vmarg 

`-Dcom.ibm.mq.cfg.SSL.outboundSNI=HOSTNAME` HOSTNAME here is the literal string - don't replace it. When registering the remote QM in MQ Explorer, use the route exposed by the QM and port 443.

For more detailed information, see:

* https://community.ibm.com/community/user/integration/blogs/callum-jackson1/2021/02/15/connecting-to-a-queue-manager-running-in-openshift
* https://github.com/ibm-messaging/cp4i-mq-samples
* https://www.ibm.com/docs/en/ibm-mq/9.3?topic=file-ssl-stanza-client-configuration
