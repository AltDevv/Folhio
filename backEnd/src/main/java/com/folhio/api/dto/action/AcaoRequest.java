package com.folhio.api.dto.action;

import java.util.Map;

public record AcaoRequest(
        String requestId,
        String app,
        Integer schemaVersion,
        String category,
        String type,
        String title,
        String description,
        String legacyOperationName,
        Map<String, Object> client,
        Map<String, Object> payload
) {
}
