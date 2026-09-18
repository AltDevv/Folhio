package com.folhio.api.processing.ocr;

public record ItemTextoOcr(
        String text,
        double confidence,
        double x,
        double y,
        double width,
        double height,
        String lineText,
        int lineIndex,
        int wordIndex
) {
}
