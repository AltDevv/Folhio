package com.folhio.api.logs;

import com.folhio.api.service.RegistroSistemaService;

import com.folhio.api.security.authentication.UsuarioAutenticado;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class RegistroHttpFilter implements Filter {

    private static final String APP_VERSION_HEADER = "X-Folhio-App-Version";
    private static final String DEVICE_HEADER = "X-Folhio-Device";

    private final RegistroSistemaService registros;
    private final String ambiente;

    public RegistroHttpFilter(
            RegistroSistemaService registros,
            @Value("${folhio.environment:local}") String ambiente
    ) {
        this.registros = registros;
        this.ambiente = ambiente;
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        String caminho = httpRequest.getRequestURI();

        if (deveIgnorar(caminho)) {
            chain.doFilter(request, response);
            return;
        }

        long inicio = System.currentTimeMillis();
        String informado = httpRequest.getHeader("X-Request-Id");
        String requestId = informado != null && informado.matches("[A-Za-z0-9._:-]{1,80}")
                ? informado : java.util.UUID.randomUUID().toString();
        httpRequest.setAttribute("folhio.error.requestId", requestId);
        httpResponse.setHeader("X-Request-Id", requestId);
        org.slf4j.MDC.put("requestId", requestId);
        try {
            chain.doFilter(request, response);
        } catch (Exception erro) {
            if (!httpResponse.isCommitted()) {
                httpResponse.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            }
            httpRequest.setAttribute("folhio.log.exception", erro.getClass().getSimpleName());
            if (erro instanceof IOException ioException) {
                throw ioException;
            }
            if (erro instanceof ServletException servletException) {
                throw servletException;
            }
            if (erro instanceof RuntimeException runtimeException) {
                throw runtimeException;
            }
            throw new ServletException(erro);
        } finally {
            if (!httpResponse.isCommitted() || httpResponse.getStatus() > 0) {
                String nivel = httpResponse.getStatus() >= 500 ? "ERRO" : httpResponse.getStatus() >= 400 ? "AVISO" : "INFO";
                String mensagem = (httpResponse.getStatus() >= 500 ? "O servidor nao conseguiu concluir a operacao"
                        : httpResponse.getStatus() >= 400 ? "A requisicao foi recusada"
                        : "A requisicao foi concluida") + " (HTTP " + httpResponse.getStatus() + ").";
                registrar(httpRequest, httpResponse, inicio, nivel, "http.requisicao", mensagem, null);
            }
            org.slf4j.MDC.remove("requestId");
        }
    }

    private void registrar(
            HttpServletRequest request,
            HttpServletResponse response,
            long inicio,
            String nivel,
            String evento,
            String mensagem,
            Exception erro
    ) {
        Map<String, Object> detalhes = new LinkedHashMap<>();
        detalhes.put("contentLength", request.getContentLengthLong());
        detalhes.put("ambiente", ambiente);
        detalhes.put("appVersao", request.getHeader(APP_VERSION_HEADER));
        detalhes.put("dispositivo", request.getHeader(DEVICE_HEADER));
        detalhes.put("codigoErro", request.getAttribute("folhio.error.code"));
        detalhes.put("causa", request.getAttribute("folhio.error.message"));
        detalhes.put("erroClasse", request.getAttribute("folhio.log.exception"));
        detalhes.put("faseResposta", request.isAsyncStarted()
                ? "Resposta em fluxo iniciada; isso nao confirma que o aplicativo recebeu o arquivo inteiro."
                : "Resposta HTTP processada.");
        UsuarioAutenticado usuario = usuarioAutenticado(request);
        if (usuario != null) {
            detalhes.put("usuario", usuario.name());
        }
        if (erro != null) {
            detalhes.put("erroClasse", erro.getClass().getName());
            detalhes.put("mensagemErro", erro.getMessage());
        }

        registros.registrarRequisicao(
                nivel,
                evento,
                mensagem,
                request.getAttribute("folhio.error.requestId") instanceof String id
                        ? id : request.getHeader("X-Request-Id"),
                request.getMethod(),
                request.getRequestURI(),
                response.getStatus(),
                System.currentTimeMillis() - inicio,
                null,
                request.getHeader("User-Agent"),
                detalhes
        );
    }

    private UsuarioAutenticado usuarioAutenticado(HttpServletRequest request) {
        Object valor = request.getAttribute(UsuarioAutenticado.REQUEST_ATTRIBUTE);
        return valor instanceof UsuarioAutenticado usuario ? usuario : null;
    }

    private boolean deveIgnorar(String caminho) {
        return caminho == null
                || "/favicon.ico".equals(caminho)
                || caminho.startsWith("/api/folhio/admin/logs")
                || caminho.startsWith("/api/folhio/admin/audit")
                || caminho.equals("/api/folhio/logs/client")
                || caminho.startsWith("/studio")
                || caminho.startsWith("/admin");
    }
}
