# Example MQ clients

## jwtmqclient

Example for using JWT authentication on a MQ queue manager. See queue manager definition to use with this client at [native-ha-qm-auth-jwt](../../../components/mq/base/native-ha-qm-auth-jwt/)

## mqclient-otel

Example on otel java instrumentation of JMS together with Tempo to visualize traces between client and MQ. Use queue manager at [native-ha-qm](../../../components/mq/base/native-ha-qm/) with tracing enabled (comment out traceability and otel configuration parts)