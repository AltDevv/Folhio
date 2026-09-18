package com.folhio.api.service;

import com.folhio.api.entity.RegistroSistema;
import com.folhio.api.repository.RegistroSistemaRepository;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.folhio.api.logs.websocket.RegistroWebSocketHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

@Service
public class RegistroSistemaService {

    private static final Logger logger = LoggerFactory.getLogger(RegistroSistemaService.class);
    private static final int MAX_DETALHES = 12_000;
    private static final int MAX_TEXTO = 500;
    private static final Duration RETENCAO_LOGS = Duration.ofDays(10);
    private static final ZoneId ZONA_METRICAS = ZoneId.of("America/Sao_Paulo");

    private final RegistroSistemaRepository repository;
    private final RegistroWebSocketHandler logWebSockets;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final boolean detailedErrorLogs;

    public RegistroSistemaService(
            RegistroSistemaRepository repository,
            RegistroWebSocketHandler logWebSockets,
            @Value("${folhio.logs.detailed-errors:false}") boolean detailedErrorLogs
    ) {
        this.repository = repository;
        this.logWebSockets = logWebSockets;
        this.detailedErrorLogs = detailedErrorLogs;
    }

    public void informacao(String categoria, String evento, String mensagem, Map<String, Object> detalhes) {
        registrar("INFO", "backend", categoria, evento, mensagem, null, null, null, null, null, null, null, detalhes);
    }

    public void registrarProcesso(String nivel, String evento, String mensagem, String requestId,
                                  Long duracaoMs, Map<String, Object> detalhes) {
        registrar(nivel, "backend", "ACAO", evento, mensagem, requestId, null, null,
                null, duracaoMs, null, null, detalhes);
    }

    public void aviso(String categoria, String evento, String mensagem, Map<String, Object> detalhes) {
        registrar("AVISO", "backend", categoria, evento, mensagem, null, null, null, null, null, null, null, detalhes);
    }

    public void erro(String categoria, String evento, String mensagem, Throwable erro, Map<String, Object> detalhes) {
        Map<String, Object> enriquecido = new LinkedHashMap<>();
        if (detalhes != null) {
            enriquecido.putAll(detalhes);
        }
        enriquecido.put("erroClasse", erro == null ? null : erro.getClass().getName());
        if (detailedErrorLogs) {
            enriquecido.put("erroMensagem", erro == null ? null : erro.getMessage());
            enriquecido.put("stackTrace", stackTraceCurta(erro));
        }
        registrar("ERRO", "backend", categoria, evento, mensagem, null, null, null, null, null, null, null, enriquecido);
    }

    public void registrarRequisicao(
            String nivel,
            String evento,
            String mensagem,
            String requestId,
            String metodo,
            String caminho,
            Integer statusHttp,
            Long duracaoMs,
            String ip,
            String userAgent,
            Map<String, Object> detalhes
    ) {
        registrar(nivel, "backend", "HTTP", evento, mensagem, requestId, metodo, caminho, statusHttp, duracaoMs, ip, userAgent, detalhes);
    }

    public void registrarCliente(Map<String, Object> payload) {
        registrar(
                texto(payload.get("nivel"), "INFO").toUpperCase(),
                "flutter",
                texto(payload.get("categoria"), "CLIENTE").toUpperCase(),
                texto(payload.get("evento"), "cliente.evento"),
                texto(payload.get("mensagem"), "Evento enviado pelo app"),
                texto(payload.get("requestId"), null),
                null,
                null,
                null,
                null,
                null,
                null,
                mapa(payload.get("detalhes"))
        );
    }

    public List<RegistroSistema> listar(String nivel, String categoria, String busca, int limite) {
        int tamanho = Math.max(1, Math.min(limite, 500));
        String nivelNormalizado = vazioParaNull(nivel);
        String categoriaNormalizada = vazioParaNull(categoria);
        String buscaNormalizada = vazioParaNull(busca);
        PageRequest pagina = PageRequest.of(0, tamanho);

        if (buscaNormalizada == null) {
            return repository.buscarRecentesSemBusca(nivelNormalizado, categoriaNormalizada, pagina);
        }

        return repository.buscarRecentes(nivelNormalizado, categoriaNormalizada, buscaNormalizada, pagina);
    }

    public Map<String, Object> resumo() {
        Map<String, Object> resumo = new LinkedHashMap<>();
        resumo.put("total", repository.count());
        resumo.put("erros", repository.contarPorNivel("ERRO"));
        resumo.put("avisos", repository.contarPorNivel("AVISO"));
        resumo.put("infos", repository.contarPorNivel("INFO"));
        resumo.put("requisicoes", repository.contarPorCategoria("HTTP"));
        resumo.put("retencaoDias", RETENCAO_LOGS.toDays());
        return resumo;
    }

    public Map<String, Object> metricas() {
        Instant desde = Instant.now().minus(RETENCAO_LOGS);
        List<RegistroSistema> logs = repository.buscarCriadosAposOrdenadosPorCriacao(desde);
        Map<String, Long> porDia = new TreeMap<>();
        Map<String, Long> porCategoria = new TreeMap<>();
        Map<String, Long> porNivel = new TreeMap<>();
        Map<String, Long> porEvento = new TreeMap<>();
        Map<String, Long> porStatus = new TreeMap<>();
        Map<String, Long> porFerramenta = new TreeMap<>();
        long duracaoTotal = 0;
        long duracaoContagem = 0;

        for (RegistroSistema log : logs) {
            LocalDate dia = log.obterCriadoEm().atZone(ZONA_METRICAS).toLocalDate();
            incrementar(porDia, dia.toString());
            incrementar(porCategoria, log.obterCategoria());
            incrementar(porNivel, log.obterNivel());
            incrementar(porEvento, log.obterEvento());
            incrementar(porStatus, grupoStatus(log.obterStatusHttp()));
            if (log.obterDuracaoMs() != null) {
                duracaoTotal += log.obterDuracaoMs();
                duracaoContagem++;
            }
            String ferramenta = ferramenta(log);
            if (!ferramenta.isBlank()) {
                incrementar(porFerramenta, ferramenta);
            }
        }

        Map<String, Object> metricas = new LinkedHashMap<>();
        metricas.put("retencaoDias", RETENCAO_LOGS.toDays());
        metricas.put("desde", desde.toString());
        metricas.put("total", logs.size());
        metricas.put("duracaoMediaMs", duracaoContagem == 0 ? 0 : duracaoTotal / duracaoContagem);
        metricas.put("porDia", porDia);
        metricas.put("porCategoria", porCategoria);
        metricas.put("porNivel", porNivel);
        metricas.put("porEvento", limitarMapa(porEvento, 12));
        metricas.put("porStatus", porStatus);
        metricas.put("porFerramenta", limitarMapa(porFerramenta, 10));
        return metricas;
    }

    public boolean existeEventoRecente(String evento, Duration intervalo) {
        return repository.existePorEventoECriadoApos(evento, Instant.now().minus(intervalo));
    }

    @Transactional
    @Scheduled(cron = "0 15 3 * * *", zone = "America/Sao_Paulo")
    public void limparLogsExpirados() {
        Instant limite = Instant.now().minus(RETENCAO_LOGS);
        long removidos = repository.excluirCriadosAntesDe(limite);
        if (removidos > 0) {
            logger.info("Removidos {} logs com mais de {} dias.", removidos, RETENCAO_LOGS.toDays());
        }
    }

    private void registrar(
            String nivel,
            String origem,
            String categoria,
            String evento,
            String mensagem,
            String requestId,
            String metodo,
            String caminho,
            Integer statusHttp,
            Long duracaoMs,
            String ip,
            String userAgent,
            Map<String, Object> detalhes
    ) {
        try {
            RegistroSistema salvo = repository.save(new RegistroSistema(
                    texto(nivel, "INFO").toUpperCase(),
                    texto(origem, "backend"),
                    texto(categoria, "GERAL").toUpperCase(),
                    texto(evento, "evento"),
                    texto(com.folhio.api.logs.DetalhesRegistroSanitizer.textoSeguro(mensagem), "Sem mensagem"),
                    vazioParaNull(requestId == null ? org.slf4j.MDC.get("requestId") : requestId),
                    vazioParaNull(metodo),
                    vazioParaNull(caminho),
                    statusHttp,
                    duracaoMs,
                    vazioParaNull(ip),
                    vazioParaNull(userAgent),
                    detalhesJson(com.folhio.api.logs.DetalhesRegistroSanitizer.limpar(detalhes))
            ));
            logWebSockets.publicar(salvo);
        } catch (Exception erroAoRegistrar) {
            logger.warn("Nao foi possivel salvar log do sistema.", erroAoRegistrar);
        }
    }

    private String detalhesJson(Map<String, Object> detalhes) throws JsonProcessingException {
        if (detalhes == null || detalhes.isEmpty()) {
            return null;
        }
        String json = objectMapper.writeValueAsString(detalhes);
        if (json.length() <= MAX_DETALHES) return json;
        Map<String,Object> limitado = new LinkedHashMap<>();
        limitado.put("detalhesReduzidos", true);
        for (var entrada : detalhes.entrySet()) {
            limitado.put(entrada.getKey(), entrada.getValue());
            if (objectMapper.writeValueAsString(limitado).length() > MAX_DETALHES) {
                limitado.remove(entrada.getKey());
                break;
            }
        }
        return objectMapper.writeValueAsString(limitado);
    }

    private String stackTraceCurta(Throwable erro) {
        if (erro == null) {
            return null;
        }
        StringWriter writer = new StringWriter();
        erro.printStackTrace(new PrintWriter(writer));
        String stack = writer.toString();
        return stack.length() <= MAX_DETALHES ? stack : stack.substring(0, MAX_DETALHES);
    }

    private String texto(Object valor, String fallback) {
        if (valor == null) {
            return fallback;
        }
        String texto = valor.toString().trim();
        if (texto.isBlank()) {
            return fallback;
        }
        return texto.length() <= MAX_TEXTO ? texto : texto.substring(0, MAX_TEXTO);
    }

    private String vazioParaNull(String valor) {
        if (valor == null || valor.isBlank()) {
            return null;
        }
        return valor.trim();
    }

    private Map<String, Object> mapa(Object valor) {
        if (valor instanceof Map<?, ?> cru) {
            Map<String, Object> mapa = new LinkedHashMap<>();
            for (Map.Entry<?, ?> entrada : cru.entrySet()) {
                mapa.put(String.valueOf(entrada.getKey()), entrada.getValue());
            }
            return mapa;
        }
        return Map.of();
    }

    private Map<String, Object> mascararSegredos(Map<String, Object> detalhes) {
        if (detalhes == null || detalhes.isEmpty()) {
            return detalhes;
        }
        Map<String, Object> seguro = new LinkedHashMap<>();
        for (Map.Entry<String, Object> entrada : detalhes.entrySet()) {
            String chave = entrada.getKey();
            Object valor = entrada.getValue();
            if (pareceSegredo(chave)) {
                seguro.put(chave, "***");
            } else if (pareceDadoDispensavel(chave)) {
                seguro.put(chave, resumoNaoSensivel(chave, valor));
            } else if (valor instanceof Map<?, ?> mapa) {
                Map<String, Object> filho = new LinkedHashMap<>();
                for (Map.Entry<?, ?> item : mapa.entrySet()) {
                    filho.put(String.valueOf(item.getKey()), item.getValue());
                }
                seguro.put(chave, mascararSegredos(filho));
            } else {
                seguro.put(chave, valor);
            }
        }
        return seguro;
    }

    private boolean pareceSegredo(String chave) {
        String normalizada = chave == null ? "" : chave.toLowerCase();
        return normalizada.contains("senha")
                || normalizada.contains("password")
                || normalizada.contains("token")
                || normalizada.contains("apikey")
                || normalizada.contains("api_key")
                || normalizada.contains("clientid")
                || normalizada.contains("authorization");
    }

    private boolean pareceDadoDispensavel(String chave) {
        String normalizada = chave == null ? "" : chave.toLowerCase();
        return normalizada.equals("client")
                || normalizada.equals("payload")
                || normalizada.contains("fileid")
                || normalizada.contains("storagekey")
                || normalizada.contains("downloadurl")
                || normalizada.contains("path")
                || normalizada.contains("filename")
                || normalizada.contains("nomearquivo")
                || normalizada.contains("arquivo")
                || normalizada.contains("email")
                || normalizada.contains("stacktrace")
                || normalizada.contains("erromensagem")
                || normalizada.contains("querystring")
                || normalizada.contains("useragent");
    }

    private Object resumoNaoSensivel(String chave, Object valor) {
        String normalizada = chave == null ? "" : chave.toLowerCase();
        if (normalizada.contains("filename") || normalizada.contains("nomearquivo") || normalizada.contains("arquivo")) {
            String texto = valor == null ? "" : valor.toString();
            int ponto = texto.lastIndexOf('.');
            return ponto >= 0 && ponto < texto.length() - 1 ? "extensao:" + texto.substring(ponto + 1).toLowerCase() : "arquivo";
        }
        if (normalizada.contains("stacktrace")) {
            return "***";
        }
        if (valor instanceof Map<?, ?> mapa) {
            return Map.of("campos", mapa.size());
        }
        if (valor instanceof Iterable<?> iterable) {
            int total = 0;
            for (Object ignored : iterable) {
                total++;
            }
            return Map.of("itens", total);
        }
        return valor == null ? null : "***";
    }

    private void incrementar(Map<String, Long> mapa, String chave) {
        String normalizada = chave == null || chave.isBlank() ? "NAO_INFORMADO" : chave;
        mapa.put(normalizada, mapa.getOrDefault(normalizada, 0L) + 1);
    }

    private String grupoStatus(Integer status) {
        if (status == null || status <= 0) {
            return "sem_status";
        }
        return (status / 100) + "xx";
    }

    private String ferramenta(RegistroSistema log) {
        Map<String, Object> detalhes = interpretarDetalhes(log.obterDetalhes());
        return texto(detalhes.get("legacyOperationName"), texto(detalhes.get("type"), ""));
    }

    private Map<String, Long> limitarMapa(Map<String, Long> origem, int limite) {
        Map<String, Long> limitado = new LinkedHashMap<>();
        origem.entrySet()
                .stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(limite)
                .forEach(entrada -> limitado.put(entrada.getKey(), entrada.getValue()));
        return limitado;
    }

    private Map<String, Object> interpretarDetalhes(String detalhes) {
        if (detalhes == null || detalhes.isBlank()) {
            return Map.of();
        }
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> mapa = objectMapper.readValue(detalhes, Map.class);
            return mapa;
        } catch (Exception ignored) {
            return Map.of();
        }
    }
}
