package com.folhio.api.processing.ocr;

import java.util.List;

public record DocumentoOcr(
        String documentType,
        String recommendedMode,
        List<BlocoOcr> blocks,
        List<ItemTextoOcr> items
) {
}
