package com.folhio.api.dto.action;

import java.util.Map;

public record AcaoResponse(
        String requestId,
        boolean success,
        String status,
        String message,
        Map<String, Object> data,
        ArquivoSaida outputFile
) {
    public static AcaoResponse sucesso(String requestId, String message, Map<String, Object> data, ArquivoSaida outputFile) {
        return new AcaoResponse(requestId, true, "completed", message, data, outputFile);
    }

    public static AcaoResponse aceito(String requestId, String message, Map<String, Object> data) {
        return new AcaoResponse(requestId, true, "accepted", message, data, null);
    }

    public static AcaoResponse rejeitado(String requestId, String message, Map<String, Object> data) {
        return new AcaoResponse(requestId, false, "rejected", message, data, null);
    }

    public record ArquivoSaida(
            String fileName,
            String mimeType,
            Long sizeBytes,
            String downloadUrl,
            String storageKey
    ) {
    }
}
