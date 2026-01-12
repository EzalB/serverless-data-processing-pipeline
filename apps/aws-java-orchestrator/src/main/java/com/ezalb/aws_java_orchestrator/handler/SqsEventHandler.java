package com.ezalb.aws_java_orchestrator.handler;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class SqsEventHandler implements RequestHandler<SQSEvent, Void> {

    @Override
    public Void handleRequest(SQSEvent event, Context context) {

        log.info("Received {} SQS message(s)", event.getRecords().size());

        event.getRecords().forEach(record -> {
            log.info("Message ID: {}", record.getMessageId());
            log.info("Message Body: {}", record.getBody());

            // 🔹 Orchestration logic placeholder
            // - route by schemaVersion
            // - fan-out to downstream systems
            // - enrich metadata
        });

        return null; // Lambda deletes messages automatically on success
    }
}
