package com.folhio.api.handler;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.ResponseEntity;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public record RespostaErro(boolean success, int status, String code, String message,
                           String requestId, String timestamp, Map<String, String> fields) {
    public static RespostaErro criar(int status, String codigo, String mensagem, HttpServletRequest request,
                                    Map<String, String> campos) {
        Object existente = request.getAttribute("folhio.error.requestId");
        String id = existente instanceof String valor ? valor : UUID.randomUUID().toString();
        request.setAttribute("folhio.error.requestId", id);
        request.setAttribute("folhio.error.code", codigo);
        request.setAttribute("folhio.error.message", mensagem);
        return new RespostaErro(false, status, codigo, mensagem, id, Instant.now().toString(), campos);
    }

    public static ResponseEntity<RespostaErro> responder(int status, String codigo, String mensagem,
                                                        HttpServletRequest request) {
        RespostaErro erro = criar(status, codigo, mensagem, request, Map.of());
        if (status >= 500) {
            org.slf4j.LoggerFactory.getLogger(RespostaErro.class)
                    .error("Falha {} requestId={}", codigo, erro.requestId());
        }
        return ResponseEntity.status(status).header("X-Request-Id", erro.requestId()).body(erro);
    }

    public static void escrever(int status, String codigo, String mensagem, HttpServletRequest request,
                                HttpServletResponse response) throws IOException {
        RespostaErro erro = criar(status, codigo, mensagem, request, Map.of());
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        response.setHeader("X-Request-Id", erro.requestId());
        new ObjectMapper().writeValue(response.getWriter(), erro);
    }
}
