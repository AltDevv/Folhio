package com.folhio.api.processing.router;

import com.folhio.api.dto.action.AcaoRequest;
import com.folhio.api.dto.action.AcaoResponse;
import com.folhio.api.common.util.MapasJson;
import com.folhio.api.processing.conversion.ResultadoConversao;
import com.folhio.api.processing.conversion.EdicaoPdfEngine;
import com.folhio.api.service.ArquivoArmazenadoService;
import com.folhio.api.files.model.ArquivoArmazenado;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class EdicaoPdfRouter {

    private final ArquivoArmazenadoService storageService;
    private final EdicaoPdfEngine pdfEditEngine;

    public EdicaoPdfRouter(ArquivoArmazenadoService storageService, EdicaoPdfEngine pdfEditEngine) {
        this.storageService = storageService;
        this.pdfEditEngine = pdfEditEngine;
    }

    public AcaoResponse processar(AcaoRequest request) {
        ResultadoConversao result = switch (request.type()) {
            case "pdf_layout" -> {
                ArquivoArmazenado input = storageService.buscar(SuporteAcaoRouter.identificadorArquivoObrigatorio(request.payload(), "file"));
                LimitesProcessamentoAcao.validarPdf(input);
                Map<String, Object> layout = MapasJson.filho(request.payload(), "layout");
                int pagesPerSheet = MapasJson.inteiro(layout, "pagesPerSheet", 2);
                String orientation = MapasJson.texto(layout, "orientation", "landscape");
                int pageMargin = MapasJson.inteiro(layout, "pageMargin", 4);
                yield pdfEditEngine.organizarPaginasPdfPorFolha(input, pagesPerSheet, orientation, pageMargin);
            }
            case "pdf_poster" -> {
                ArquivoArmazenado input = storageService.buscar(SuporteAcaoRouter.identificadorArquivoObrigatorio(request.payload(), "file"));
                LimitesProcessamentoAcao.validarEntradaPoster(input);
                Map<String, Object> poster = MapasJson.filho(request.payload(), "poster");
                int sheetsWide = MapasJson.inteiro(poster, "sheetsWide", 3);
                int sheetsTall = MapasJson.inteiro(poster, "sheetsTall", 2);
                int pageMargin = MapasJson.inteiro(poster, "pageMargin", 6);
                yield pdfEditEngine.dividirPdfEmPoster(input, sheetsWide, sheetsTall, pageMargin);
            }
            case "cut_pages" -> {
                ArquivoArmazenado input = storageService.buscar(SuporteAcaoRouter.identificadorArquivoObrigatorio(request.payload(), "file"));
                LimitesProcessamentoAcao.validarPdf(input);
                yield pdfEditEngine.extrairPaginas(input, MapasJson.listaInteiros(request.payload(), "pagesToKeep"));
            }
            case "merge_pdfs" -> {
                List<ArquivoArmazenado> files = new ArrayList<>();
                for (Object item : MapasJson.listar(request.payload(), "files")) {
                    if (item instanceof Map<?, ?> raw) {
                        @SuppressWarnings("unchecked")
                        Map<String, Object> file = (Map<String, Object>) raw;
                        files.add(storageService.buscar(MapasJson.texto(file, "id", "")));
                    }
                }
                LimitesProcessamentoAcao.validarMesclagem(files);
                yield pdfEditEngine.mesclarPdfs(files);
            }
            case "compress_pdf" -> {
                ArquivoArmazenado input = storageService.buscar(SuporteAcaoRouter.identificadorArquivoObrigatorio(request.payload(), "file"));
                LimitesProcessamentoAcao.validarPdf(input);
                Map<String, Object> compression = MapasJson.filho(request.payload(), "compression");
                yield pdfEditEngine.compactarPdf(input, MapasJson.texto(compression, "level", "medium"));
            }
            case "add_header" -> {
                ArquivoArmazenado input = storageService.buscar(SuporteAcaoRouter.identificadorArquivoObrigatorio(request.payload(), "file"));
                LimitesProcessamentoAcao.validarPdf(input);
                Map<String, Object> header = MapasJson.filho(request.payload(), "header");
                yield pdfEditEngine.adicionarIdentificacaoAtividade(
                        input,
                        MapasJson.texto(header, "schoolName", "Escola"),
                        MapasJson.texto(header, "subject", ""),
                        MapasJson.texto(header, "className", "Turma"),
                        MapasJson.texto(header, "teacherName", ""),
                        MapasJson.texto(header, "dateText", ""),
                        MapasJson.booleano(header, "showStudentNameLine", true),
                        MapasJson.booleano(header, "showGradeLine", false),
                        MapasJson.booleano(header, "applyToAllPages", false)
                );
            }
            case "number_pages" -> {
                ArquivoArmazenado input = storageService.buscar(SuporteAcaoRouter.identificadorArquivoObrigatorio(request.payload(), "file"));
                LimitesProcessamentoAcao.validarPdf(input);
                Map<String, Object> numbering = MapasJson.filho(request.payload(), "numbering");
                yield pdfEditEngine.numerarPaginas(
                        input,
                        MapasJson.texto(numbering, "position", "bottom_right"),
                        MapasJson.inteiro(numbering, "startAtPage", 1),
                        MapasJson.inteiro(numbering, "firstNumber", 1),
                        MapasJson.texto(numbering, "format", "plain")
                );
            }
            case "add_signature" -> {
                ArquivoArmazenado input = storageService.buscar(SuporteAcaoRouter.identificadorArquivoObrigatorio(request.payload(), "file"));
                LimitesProcessamentoAcao.validarPdf(input);
                Map<String, Object> signature = MapasJson.filho(request.payload(), "signature");
                String imageId = MapasJson.texto(MapasJson.filho(signature, "image"), "id", "");
                ArquivoArmazenado signatureImage = imageId.isBlank() ? null : storageService.buscar(imageId);
                if (signatureImage != null) {
                    LimitesProcessamentoAcao.validarImagem(signatureImage);
                }
                yield pdfEditEngine.adicionarAssinatura(
                        input,
                        signatureImage,
                        MapasJson.texto(signature, "signerName", ""),
                        MapasJson.texto(signature, "role", ""),
                        MapasJson.texto(signature, "dateText", ""),
                        MapasJson.texto(signature, "position", "bottom_right"),
                        MapasJson.decimal(signature, "xRatio", 0.62),
                        MapasJson.decimal(signature, "yRatio", 0.78),
                        MapasJson.decimal(signature, "widthRatio", 0.28),
                        MapasJson.booleano(signature, "applyToAllPages", false)
                );
            }
            default -> throw new UnsupportedOperationException("Edição de PDF ainda não implementada: " + request.type());
        };

        return AcaoResponse.sucesso(
                request.requestId(),
                result.message(),
                Map.of(
                        "type", request.type(),
                        "engine", "zilch-compatible"
                ),
                SuporteAcaoRouter.arquivoSaida(result.file())
        );
    }
}
