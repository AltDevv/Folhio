package com.folhio.api.processing.router;

import com.folhio.api.dto.action.AcaoRequest;
import com.folhio.api.dto.action.AcaoResponse;
import com.folhio.api.common.util.MapasJson;
import com.folhio.api.processing.generation.CarimboDocumentoService;
import com.folhio.api.processing.generation.DocumentoEscolarService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class FerramentasRouter {

    private final DocumentoEscolarService schoolDocumentService;
    private final CarimboDocumentoService documentStampService;

    public FerramentasRouter(
            DocumentoEscolarService schoolDocumentService,
            CarimboDocumentoService documentStampService
    ) {
        this.schoolDocumentService = schoolDocumentService;
        this.documentStampService = documentStampService;
    }

    public AcaoResponse processar(AcaoRequest request) {
        return switch (request.type()) {
            case "attendance_list" -> schoolDocumentService.gerarListaChamada(request, nomeTurma(request));
            case "grade_sheet" -> schoolDocumentService.gerarPlanilhaNotas(request, nomeTurma(request));
            case "individual_note" -> schoolDocumentService.gerarComunicadosIndividuais(
                    request,
                    nomeTurma(request),
                    MapasJson.texto(request.payload(), "messageTemplate", "Segue o acompanhamento individual do aluno.")
            );
            case "batch_rename" -> renomearResposta(request);
            case "organize_by_class" -> organizarResposta(request);
            case "stamp_documents" -> documentStampService.carimbarDocumentos(request);
            default -> AcaoResponse.rejeitado(
                    request.requestId(),
                    "Tool ainda não implementada: " + request.type(),
                    Map.of("supportedTypes", List.of(
                            "attendance_list",
                            "grade_sheet",
                            "individual_note",
                            "batch_rename",
                            "organize_by_class",
                            "stamp_documents"
                    ))
            );
        };
    }

    private String nomeTurma(AcaoRequest request) {
        return MapasJson.texto(MapasJson.filho(request.payload(), "class"), "name", "Turma");
    }

    private AcaoResponse renomearResposta(AcaoRequest request) {
        return AcaoResponse.aceito(
                request.requestId(),
                "Renomeacao em lote recebida.",
                Map.of(
                        "tool", request.type(),
                        "files", MapasJson.listar(request.payload(), "files"),
                        "pattern", MapasJson.texto(request.payload(), "pattern", "")
                )
        );
    }

    private AcaoResponse organizarResposta(AcaoRequest request) {
        return AcaoResponse.aceito(
                request.requestId(),
                "Organizacao por turma recebida.",
                Map.of(
                        "tool", request.type(),
                        "files", MapasJson.listar(request.payload(), "files"),
                        "organizationMode", MapasJson.texto(request.payload(), "organizationMode", "")
                )
        );
    }
}

