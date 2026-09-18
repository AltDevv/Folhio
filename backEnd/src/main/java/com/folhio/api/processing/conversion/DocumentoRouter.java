package com.folhio.api.processing.conversion;

import com.folhio.api.files.model.ArquivoArmazenado;
import com.folhio.api.progress.ProgressoTracker;
import org.springframework.stereotype.Service;

@Service
public class DocumentoRouter {

    private final ConversaoOfficeEngine officeConversionEngine;
    private final ExportacaoWordEngine wordExportEngine;

    public DocumentoRouter(ConversaoOfficeEngine officeConversionEngine, ExportacaoWordEngine wordExportEngine) {
        this.officeConversionEngine = officeConversionEngine;
        this.wordExportEngine = wordExportEngine;
    }

    public ResultadoConversao converter(ArquivoArmazenado input, String legacyOperationName, String targetFormat) {
        ProgressoTracker.atualizar(0.10, "Arquivo recebido");
        return switch (legacyOperationName) {
            case "PDF em PNG" -> officeConversionEngine.converterPdfParaImagens(input, "png", "image/png");
            case "PDF em JPG" -> officeConversionEngine.converterPdfParaImagens(input, "jpg", "image/jpeg");
            case "JPG em PDF", "PNG em PDF" -> officeConversionEngine.converterImagemParaPdf(input);
            case "PDF em Word" -> wordExportEngine.converterPdfParaWord(input);
            case "JPG em Word", "PNG em Word" -> wordExportEngine.converterImagemParaWord(input);
            case "PDF em Excel" -> officeConversionEngine.converterPdfParaExcel(input);
            case "Word em PDF" -> officeConversionEngine.converterWordParaPdf(input);
            case "Excel em PDF" -> officeConversionEngine.converterExcelParaPdf(input);
            case "PPT em PDF" -> officeConversionEngine.converterPptParaPdf(input);
            default -> throw new IllegalArgumentException("Conversão não suportada: " + legacyOperationName);
        };
    }
}
