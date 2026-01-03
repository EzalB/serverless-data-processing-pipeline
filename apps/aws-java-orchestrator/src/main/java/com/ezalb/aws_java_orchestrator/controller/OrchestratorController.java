package com.ezalb.aws_java_orchestrator.controller;

import com.ezalb.aws_java_orchestrator.model.ProcessRequest;
import com.ezalb.aws_java_orchestrator.model.ProcessResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.UUID;

@RestController
@RequestMapping("/")
public class OrchestratorController {

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("ok");
    }

    @PostMapping("/process")
    public ResponseEntity<ProcessResponse> process(
            @RequestBody ProcessRequest request
    ) {
        ProcessResponse response = new ProcessResponse(
                UUID.randomUUID().toString(),
                request.filename(),
                request.schemaVersion(),
                "processed",
                Instant.now().toString(),
                "aws-java-orchestrator"
        );

        return ResponseEntity.ok(response);
    }
}
