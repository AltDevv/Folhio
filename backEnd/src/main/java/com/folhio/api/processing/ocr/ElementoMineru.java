package com.folhio.api.processing.ocr;

import java.nio.file.Path;
import java.util.List;

public record ElementoMineru(
        String type,
        String text,
        int level,
        String html,
        Path imagePath,
        List<Double> bbox
) {
    public boolean temTexto() {
        return text != null && !text.isBlank();
    }

    public boolean temTabela() {
        return html != null && !html.isBlank();
    }

    public boolean temImagem() {
        return imagePath != null;
    }
}
