package com.ezalb.aws_java_orchestrator.model;

public record ProcessResponse(
        String requestId,
        String filename,
        String schemaVersion,
        String status,
        String processedAt,
        String service
) {}
