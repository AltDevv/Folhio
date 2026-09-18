package com.folhio.api.dto.file;

public record ArquivoResponse(boolean success, String fileId, String fileName, String mimeType,
                           long sizeBytes, String downloadUrl, Integer pageCount,
                           Float pageWidth, Float pageHeight, String requestId) {
}
