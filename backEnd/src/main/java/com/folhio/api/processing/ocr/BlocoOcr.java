package com.folhio.api.processing.ocr;

import java.util.List;

public record BlocoOcr(
        String type,
        String text,
        List<String> lines,
        double x,
        double y,
        double width,
        double height,
        String alignment,
        double fontSizePt,
        double confidence
) {
}
