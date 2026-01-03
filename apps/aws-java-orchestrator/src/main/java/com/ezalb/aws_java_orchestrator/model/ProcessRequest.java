package com.ezalb.aws_java_orchestrator.model;

public record ProcessRequest(
        String filename,
        String schemaVersion,
        String source
) {}
