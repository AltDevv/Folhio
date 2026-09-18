package com.folhio.api.files.model;

import java.nio.file.Path;

public record ArquivoArmazenado(
        String id,
        String originalFileName,
        String contentType,
        long sizeBytes,
        Path path,
        String ownerClientId
) {
}
