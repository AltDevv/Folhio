package com.folhio.api.processing.conversion;

import com.folhio.api.files.model.ArquivoArmazenado;

public record ResultadoConversao(
        ArquivoArmazenado file,
        String message
) {
}
