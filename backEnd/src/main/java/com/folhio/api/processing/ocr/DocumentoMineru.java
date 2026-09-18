package com.folhio.api.processing.ocr;

import java.nio.file.Path;
import java.util.List;

public record DocumentoMineru(
        List<List<ElementoMineru>> pages,
        Path outputDirectory
) {
}
