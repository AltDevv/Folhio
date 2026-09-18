package com.folhio.api.processing.router;

import com.folhio.api.dto.action.AcaoRequest;
import com.folhio.api.dto.action.AcaoResponse;
import com.folhio.api.common.util.MapasJson;
import com.folhio.api.processing.conversion.ResultadoConversao;
import com.folhio.api.processing.conversion.DocumentoRouter;
import com.folhio.api.service.ArquivoArmazenadoService;
import com.folhio.api.files.model.ArquivoArmazenado;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class ConversaoOfficeRouter {

    private static final Map<String, DefinicaoConversao> CONVERSIONS = Map.ofEntries(
            Map.entry("PDF em Word", new DefinicaoConversao("docx")),
            Map.entry("PDF em PNG", new DefinicaoConversao("png")),
            Map.entry("PDF em Excel", new DefinicaoConversao("xlsx")),
            Map.entry("PDF em JPG", new DefinicaoConversao("jpg")),
            Map.entry("Word em PDF", new DefinicaoConversao("pdf")),
            Map.entry("Excel em PDF", new DefinicaoConversao("pdf")),
            Map.entry("PPT em PDF", new DefinicaoConversao("pdf")),
            Map.entry("JPG em PDF", new DefinicaoConversao("pdf")),
            Map.entry("PNG em PDF", new DefinicaoConversao("pdf")),
            Map.entry("JPG em Word", new DefinicaoConversao("docx")),
            Map.entry("PNG em Word", new DefinicaoConversao("docx"))
    );

    private final ArquivoArmazenadoService storageService;
    private final DocumentoRouter documentEngineRouter;

    public ConversaoOfficeRouter(ArquivoArmazenadoService storageService, DocumentoRouter documentEngineRouter) {
        this.storageService = storageService;
        this.documentEngineRouter = documentEngineRouter;
    }

    public AcaoResponse processar(AcaoRequest request) {
        if (!"convert_document".equals(request.type())) {
            return AcaoResponse.rejeitado(
                    request.requestId(),
                    "Tipo de conversão ainda não implementado: " + request.type(),
                    Map.of("supportedTypes", List.of("convert_document"))
            );
        }

        DefinicaoConversao conversion = CONVERSIONS.get(request.legacyOperationName());
        if (conversion == null) {
            return AcaoResponse.rejeitado(
                    request.requestId(),
                    "Conversão ainda não mapeada para os serviços do Zilch: " + request.legacyOperationName(),
                    Map.of("supportedLegacyOperations", CONVERSIONS.keySet())
            );
        }

        ArquivoArmazenado input = storageService.buscar(SuporteAcaoRouter.identificadorArquivoObrigatorio(request.payload(), "sourceFile"));
        LimitesProcessamentoAcao.validarEntradaConversaoDocumento(input);
        String targetFormat = MapasJson.texto(MapasJson.filho(request.payload(), "target"), "format", conversion.targetExtension());
        ResultadoConversao result = documentEngineRouter.converter(input, request.legacyOperationName(), targetFormat);

        return AcaoResponse.sucesso(
                request.requestId(),
                result.message(),
                Map.of(
                        "legacyOperationName", request.legacyOperationName(),
                        "sourceFile", SuporteAcaoRouter.dadosArquivo(input),
                        "target", MapasJson.filho(request.payload(), "target"),
                        "engine", "zilch-compatible"
                ),
                SuporteAcaoRouter.arquivoSaida(result.file())
        );
    }

    private record DefinicaoConversao(String targetExtension) {
    }
}
