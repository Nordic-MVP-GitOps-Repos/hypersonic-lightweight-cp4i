FROM cp.icr.io/cp/ibm-eventstreams-kafka:11.1.6

USER root
RUN mkdir -p /opt/kafka/plugins/
RUN curl -Lo /opt/kafka/plugins/kafka-connect-mq-source.jar https://github.com/ibm-messaging/kafka-connect-mq-source/releases/download/v1.3.2/kafka-connect-mq-source-1.3.2-jar-with-dependencies.jar

USER 1001