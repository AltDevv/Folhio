package com.folhio.api.processing.router;

import com.folhio.api.progress.ProgressoRegistry;

import com.folhio.api.dto.action.AcaoRequest;
import com.folhio.api.dto.action.AcaoResponse;
import com.folhio.api.service.ArquivoArmazenadoService;
import com.folhio.api.service.RegistroSistemaService;
import com.folhio.api.progress.ProgressoTracker;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.Semaphore;
import java.util.regex.Pattern;

@Service
public class AcaoPrincipalRouter {

    private static final Pattern STORAGE_ID_PATTERN = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
    );

    private final ConversaoOfficeRouter officeConversionRouter;
    private final EdicaoPdfRouter pdfEditRouter;
    private final EdicaoImagemRouter imageEditRouter;
    private final FerramentasRouter toolsRouter;
    private final ProgressoRegistry progressRegistry;
    private final RegistroSistemaService registros;
    private final ArquivoArmazenadoService storageService;
    private final Semaphore actionPermits;
    private final java.util.concurrent.atomic.AtomicInteger processosAtivos = new java.util.concurrent.atomic.AtomicInteger();

    public int obterProcessosAtivos() { return processosAtivos.get(); }

    public AcaoPrincipalRouter(
            ConversaoOfficeRouter officeConversionRouter,
            EdicaoPdfRouter pdfEditRouter,
            EdicaoImagemRouter imageEditRouter,
            FerramentasRouter toolsRouter,
            ProgressoRegistry progressRegistry,
            RegistroSistemaService registros,
            ArquivoArmazenadoService storageService,
            @Value("${folhio.actions.max-concurrent:2}") int maxConcurrentActions
    ) {
        this.officeConversionRouter = officeConversionRouter;
        this.pdfEditRouter = pdfEditRouter;
        this.imageEditRouter = imageEditRouter;
        this.toolsRouter = toolsRouter;
        this.progressRegistry = progressRegistry;
        this.registros = registros;
        this.storageService = storageService;
        this.actionPermits = new Semaphore(Math.max(1, maxConcurrentActions), true);
    }

    public AcaoResponse processar(AcaoRequest request, String ownerClientId) {
        return processar(request, ownerClientId, null);
    }

    public AcaoResponse processar(AcaoRequest request, String ownerClientId, String ownerUserId) {
        if (!actionPermits.tryAcquire()) {
            throw new com.folhio.api.handler.processing.exception.ServidorOcupadoException();
        }
        processosAtivos.incrementAndGet();
        try {
            return storageService.comProprietario(ownerClientId, ownerUserId, () -> processarNoContextoProprietario(request));
        } finally {
            processosAtivos.decrementAndGet();
            actionPermits.release();
        }
    }

    private AcaoResponse processarNoContextoProprietario(AcaoRequest request) {
        String requestId = request.requestId();
        long inicio = System.nanoTime();
        progressRegistry.iniciar(requestId, "Preparando processamento");
        registros.registrarProcesso("INFO", "acao.iniciada", descricaoAcao(request), requestId, null, detalhesDaAcao(request));
        try {
            AcaoResponse response = executarComProgresso(request);
            if (!response.success()) {
                throw new com.folhio.api.handler.processing.exception.OperacaoNaoSuportadaException();
            }
            progressRegistry.concluir(requestId, response.success() ? "Processamento concluído" : response.message());
            Map<String, Object> detalhes = detalhesDaAcao(request);
            detalhes.put("status", response.status());
            detalhes.put("success", response.success());
            detalhes.put("mensagemResposta", response.message());
            if (response.outputFile() != null) {
                detalhes.put("mimeTypeGerado", response.outputFile().mimeType());
                detalhes.put("tamanhoArquivoGerado", response.outputFile().sizeBytes());
            }
            if (response.success()) {
                registros.registrarProcesso("INFO", "acao.concluida", response.message(), requestId,
                        (System.nanoTime() - inicio) / 1_000_000, detalhes);
            } else {
                registros.aviso("ACAO", "acao.rejeitada", response.message(), detalhes);
            }
            return response;
        } catch (Exception error) {
            RuntimeException falha;
            if (error instanceof com.folhio.api.handler.NegocioException negocio) {
                falha = negocio;
            } else if (error instanceof UnsupportedOperationException) {
                falha = new com.folhio.api.handler.processing.exception.OperacaoNaoSuportadaException();
            } else if (error instanceof IllegalArgumentException) {
                falha = new com.folhio.api.handler.validation.exception.DadosInvalidosException();
            } else {
                falha = new com.folhio.api.handler.processing.exception.ProcessamentoArquivoException(
                        "Nao foi possivel processar o arquivo.", error);
            }
            progressRegistry.concluir(requestId, "Nao foi possivel concluir o processamento");
            Map<String, Object> detalhesErro = detalhesDaAcao(request);
            detalhesErro.put("erroClasse", error.getClass().getSimpleName());
            registros.registrarProcesso("ERRO", "acao.erro", falha.getMessage(), requestId,
                    (System.nanoTime() - inicio) / 1_000_000, detalhesErro);
            throw falha;
        } finally {
            excluirEnviosTemporarios(request.payload());
        }
    }

    private AcaoResponse executarComProgresso(AcaoRequest request) {
        final AcaoResponse[] response = new AcaoResponse[1];
        ProgressoTracker.comOuvinte(
                (progress, message) -> progressRegistry.atualizar(request.requestId(), progress, message),
                () -> response[0] = rotear(request)
        );
        return response[0];
    }

    private AcaoResponse rotear(AcaoRequest request) {
        if (request.category() == null || request.type() == null) {
            throw new com.folhio.api.handler.validation.exception.DadosInvalidosException(
                    "Informe a categoria e o tipo da operacao.");
        }

        return switch (request.category()) {
            case "converter" -> officeConversionRouter.processar(request);
            case "edit" -> rotearEdicao(request);
            case "tools" -> toolsRouter.processar(request);
            default -> AcaoResponse.rejeitado(
                    request.requestId(),
                    "Categoria ainda não implementada: " + request.category(),
                    java.util.Map.of("supportedCategories", java.util.List.of("converter", "edit", "tools"))
            );
        };
    }

    private AcaoResponse rotearEdicao(AcaoRequest request) {
        if ("visual_image_edit".equals(request.type())) {
            return imageEditRouter.processar(request);
        }
        return pdfEditRouter.processar(request);
    }

    private String descricaoAcao(AcaoRequest request) {
        String titulo = request.title() == null || request.title().isBlank() ? request.type() : request.title();
        return "Processando arquivo: " + titulo;
    }

    private Map<String, Object> detalhesDaAcao(AcaoRequest request) {
        Map<String, Object> detalhes = new LinkedHashMap<>();
        detalhes.put("requestId", request.requestId());
        detalhes.put("app", request.app());
        detalhes.put("schemaVersion", request.schemaVersion());
        detalhes.put("category", request.category());
        detalhes.put("type", request.type());
        detalhes.put("title", request.title());
        detalhes.put("legacyOperationName", request.legacyOperationName());
        detalhes.put("client", request.client());
        return detalhes;
    }

    private void excluirEnviosTemporarios(Map<String, Object> payload) {
        if (payload == null || payload.isEmpty()) {
            return;
        }

        Set<String> ids = new LinkedHashSet<>();
        coletarIdentificadoresArquivos(payload, ids);
        ids.forEach(storageService::excluirEnvioSilenciosamente);
    }

    private void coletarIdentificadoresArquivos(Object value, Set<String> ids) {
        if (value instanceof Map<?, ?> map) {
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                Object key = entry.getKey();
                Object child = entry.getValue();
                if ("id".equals(String.valueOf(key)) && child instanceof String id && ehIdentificadorArmazenamento(id)) {
                    ids.add(id);
                }
                coletarIdentificadoresArquivos(child, ids);
            }
            return;
        }

        if (value instanceof Iterable<?> iterable) {
            for (Object item : iterable) {
                coletarIdentificadoresArquivos(item, ids);
            }
        }
    }

    private boolean ehIdentificadorArmazenamento(String id) {
        return id != null && STORAGE_ID_PATTERN.matcher(id).matches();
    }
}
