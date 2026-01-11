package com.ezalb.aws_java_orchestrator.model;
import jakarta.validation.constraints.NotBlank;

public record ProcessRequest(
        @NotBlank String filename,
        @NotBlank String schemaVersion,
        String source
) {}
