package com.folhio.api.logs.websocket;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.folhio.api.entity.RegistroSistema;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RegistroWebSocketHandler extends TextWebSocketHandler {

    private final Set<WebSocketSession> sessions = ConcurrentHashMap.newKeySet();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        sessions.add(session);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        sessions.remove(session);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        sessions.remove(session);
        fecharSilenciosamente(session);
    }

    public void publicar(RegistroSistema log) {
        if (sessions.isEmpty()) {
            return;
        }
        String payload = codificar(log);
        for (WebSocketSession session : sessions) {
            if (!session.isOpen()) {
                sessions.remove(session);
                continue;
            }
            try {
                session.sendMessage(new TextMessage(payload));
            } catch (IOException ignored) {
                sessions.remove(session);
                fecharSilenciosamente(session);
            }
        }
    }

    private String codificar(RegistroSistema log) {
        try {
            return objectMapper.writeValueAsString(Map.of(
                    "type", "log.created",
                    "id", log.obterId(),
                    "criadoEm", log.obterCriadoEm(),
                    "nivel", log.obterNivel(),
                    "categoria", log.obterCategoria(),
                    "evento", log.obterEvento(),
                    "requestId", log.obterIdentificadorRequisicao() == null ? "" : log.obterIdentificadorRequisicao()
            ));
        } catch (JsonProcessingException ignored) {
            return "{\"type\":\"log.created\"}";
        }
    }

    private void fecharSilenciosamente(WebSocketSession session) {
        try {
            if (session.isOpen()) {
                session.close(CloseStatus.SERVER_ERROR);
            }
        } catch (IOException ignored) {
            // Best effort cleanup.
        }
    }
}
