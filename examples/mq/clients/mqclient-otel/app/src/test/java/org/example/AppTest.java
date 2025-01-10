package org.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import io.opentelemetry.javaagent.testing.common.AgentTestingExporterAccess;


class AppTest {
    @Test void testMqConnection() throws Exception {
        MQJWTExample classUnderTest = new MQJWTExample();

        //var otelGRPCEndpoint = MQJWTExample.getLocalProperty("otelGRPCEndpoint");

        // System.setProperty("otel.resource.attributes", "service.name=javaPut");
		// //System.setProperty("otel.javaagent.logging","application");
		// System.setProperty("otel.javaagent.debug", "true");
        // System.setProperty("otel.javaagent.enabled", "true");
		// System.setProperty("otel.exporter.otlp.protocol", "grpc");
		// System.setProperty("otel.exporter.otlp.endpoint", otelGRPCEndpoint);
		// System.setProperty("otel.metrics.exporter", "none");
		// System.setProperty("otel.logs.exporter", "none");
		// System.setProperty("otel.traces.exporter", "otlp");
		// System.setProperty("otel.traces.exporter.otlp.protocol", "grpc");

        try {
            AgentTestingExporterAccess.reset();

            classUnderTest.callMq();

            var spans = AgentTestingExporterAccess.getExportedSpans();
            System.out.println(spans.toString());
            //assertFalse(spans.isEmpty());
        } catch (Exception e) {
            e.printStackTrace();
            fail(e);
        }
    }
}
