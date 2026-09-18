package com.folhio.api.security.filter;

import com.folhio.api.security.IdentidadeCliente;

import com.folhio.api.service.RegistroSistemaService;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class AutenticacaoChaveApiFilter implements Filter {

    private static final String HEADER_NAME = "X-API-Key";
    private static final int INVALID_KEY_LIMIT = 80;
    private static final Duration INVALID_KEY_WINDOW = Duration.ofMinutes(10);

    private final String appApiKey;
    private final String adminApiKey;
    private final int maxRequestsPerWindow;
    private final Duration requestWindow;
    private final RegistroSistemaService registros;
    private final Map<String, JanelaFalhas> invalidKeyAttempts = new ConcurrentHashMap<>();
    private final Map<String, JanelaRequisicoes> requestWindows = new ConcurrentHashMap<>();

    public AutenticacaoChaveApiFilter(
            @Value("${folhio.security.app-api-key:}") String appApiKey,
            @Value("${folhio.security.admin-api-key:}") String adminApiKey,
            @Value("${folhio.security.rate-limit.max-requests:120}") int maxRequestsPerWindow,
            @Value("${folhio.security.rate-limit.window-seconds:60}") int requestWindowSeconds,
            RegistroSistemaService registros
    ) {
        this.appApiKey = appApiKey;
        this.adminApiKey = adminApiKey;
        this.maxRequestsPerWindow = Math.max(1, maxRequestsPerWindow);
        this.requestWindow = Duration.ofSeconds(Math.max(1, requestWindowSeconds));
        this.registros = registros;
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        adicionarCabecalhosSeguranca(httpResponse);

        if (ehRedirecionamentoAdministrativoLegado(httpRequest)) {
            chain.doFilter(request, response);
            return;
        }

        if (ehRequisicaoRegistroCliente(httpRequest)) {
            if (!requisicaoPermitida(httpRequest, "client-log")) {
                escreverRespostaLimiteRequisicoes(httpRequest, httpResponse);
                return;
            }
            chain.doFilter(request, response);
            return;
        }

        if (podeProsseguirSemChave(httpRequest) || chaveApiCorresponde(httpRequest, chaveApiEsperada(httpRequest))) {
            if (!podeProsseguirSemChave(httpRequest) && !requisicaoPermitida(httpRequest, "api")) {
                escreverRespostaLimiteRequisicoes(httpRequest, httpResponse);
                return;
            }
            chain.doFilter(request, response);
            return;
        }

        if (excessoTentativasInvalidas(httpRequest)) {
            escreverRespostaLimiteRequisicoes(httpRequest, httpResponse);
            return;
        }

        registrarApiKeyInvalida(httpRequest);
        com.folhio.api.handler.RespostaErro.escrever(401, "CHAVE_API_INVALIDA",
                "Nao foi possivel conectar com seguranca. Verifique a configuracao do app.", httpRequest, httpResponse);
    }

    private boolean podeProsseguirSemChave(HttpServletRequest request) {
        String path = request.getRequestURI();
        return "OPTIONS".equalsIgnoreCase(request.getMethod())
                || "/favicon.ico".equals(path)
                || "/api/folhio/health".equals(path)
                || "/studio".equals(path)
                || (path != null && path.startsWith("/studio/"))
                || (path != null && path.startsWith("/l/"))
                || (path != null && path.startsWith("/espacos/"));
    }

    private boolean ehRequisicaoRegistroCliente(HttpServletRequest request) {
        return "POST".equalsIgnoreCase(request.getMethod())
                && "/api/folhio/logs/client".equals(request.getRequestURI());
    }

    private boolean ehRedirecionamentoAdministrativoLegado(HttpServletRequest request) {
        String path = request.getRequestURI();
        return "/admin".equals(path) || (path != null && path.startsWith("/admin/"));
    }

    private String chaveApiEsperada(HttpServletRequest request) {
        String path = request.getRequestURI();
        if (path != null && path.startsWith("/api/folhio/admin/")) {
            return adminApiKey;
        }
        return appApiKey;
    }

    private boolean chaveApiCorresponde(HttpServletRequest request, String expectedApiKey) {
        String providedKey = chaveApiInformada(request);
        if (caminhoComecaCom(request, "/ws/logs")) {
            return chaveApiIgual(providedKey, adminApiKey);
        }
        if (caminhoComecaCom(request, "/ws/")) {
            return chaveApiIgual(providedKey, appApiKey) || chaveApiIgual(providedKey, adminApiKey);
        }
        return chaveApiIgual(providedKey, expectedApiKey);
    }

    private String chaveApiInformada(HttpServletRequest request) {
        String providedKey = request.getHeader(HEADER_NAME);
        if ((providedKey == null || providedKey.isBlank()) && caminhoComecaCom(request, "/ws/")) {
            providedKey = request.getParameter("apiKey");
        }
        return providedKey;
    }

    private boolean chaveApiIgual(String providedKey, String expectedApiKey) {
        if (expectedApiKey == null || expectedApiKey.isBlank() || providedKey == null || providedKey.isBlank()) {
            return false;
        }

        byte[] expected = expectedApiKey.getBytes(StandardCharsets.UTF_8);
        byte[] provided = providedKey.getBytes(StandardCharsets.UTF_8);
        return expected.length == provided.length && MessageDigest.isEqual(expected, provided);
    }

    private boolean caminhoComecaCom(HttpServletRequest request, String prefix) {
        String path = request.getRequestURI();
        return path != null && path.startsWith(prefix);
    }

    private void escreverRespostaLimiteRequisicoes(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setHeader("Retry-After", String.valueOf(requestWindow.toSeconds()));
        com.folhio.api.handler.RespostaErro.escrever(429, "LIMITE_REQUISICOES",
                "Muitas tentativas. Aguarde um pouco e tente novamente.", request, response);
    }

    private void adicionarCabecalhosSeguranca(HttpServletResponse response) {
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("X-Frame-Options", "DENY");
        response.setHeader("Referrer-Policy", "no-referrer");
        response.setHeader("Cache-Control", "no-store");
    }

    private boolean excessoTentativasInvalidas(HttpServletRequest request) {
        String key = chaveCliente(request);
        Instant now = Instant.now();
        JanelaFalhas window = invalidKeyAttempts.compute(key, (ignored, current) -> {
            if (current == null || current.expiresAt().isBefore(now)) {
                return new JanelaFalhas(1, now.plus(INVALID_KEY_WINDOW));
            }
            return new JanelaFalhas(current.count() + 1, current.expiresAt());
        });
        return window.count() > INVALID_KEY_LIMIT;
    }

    private boolean requisicaoPermitida(HttpServletRequest request, String scope) {
        String key = scope + ":" + chaveCliente(request);
        Instant now = Instant.now();
        JanelaRequisicoes window = requestWindows.compute(key, (ignored, current) -> {
            if (current == null || current.expiresAt().isBefore(now)) {
                return new JanelaRequisicoes(1, now.plus(requestWindow));
            }
            return new JanelaRequisicoes(current.count() + 1, current.expiresAt());
        });
        return window.count() <= maxRequestsPerWindow;
    }

    private String chaveCliente(HttpServletRequest request) {
        String clientId = request.getHeader(IdentidadeCliente.HEADER_NAME);
        if (IdentidadeCliente.ehValido(clientId)) {
            return clientId;
        }
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            return forwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private void registrarApiKeyInvalida(HttpServletRequest request) {
        try {
            registros.aviso(
                    "SEGURANCA",
                    "api.chave_invalida",
                    "Requisição rejeitada por chave de API ausente ou inválida.",
                    Map.of(
                            "metodo", request.getMethod(),
                            "caminho", request.getRequestURI(),
                            "clientId", chaveCliente(request),
                            "userAgent", request.getHeader("User-Agent") == null ? "" : request.getHeader("User-Agent")
                    )
            );
        } catch (RuntimeException ignored) {
            // Falha ao salvar log nao pode alterar a resposta de seguranca.
        }
    }

    private record JanelaFalhas(int count, Instant expiresAt) {
    }

    private record JanelaRequisicoes(int count, Instant expiresAt) {
    }
}
