package com.folhio.api.progress.websocket;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.folhio.api.progress.state.Progresso;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.net.URI;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class ProgressoWebSocketHandler extends TextWebSocketHandler {

    private final Map<String, Set<WebSocketSession>> sessionsByRequest = new ConcurrentHashMap<>();
    private final Map<String, String> requestBySession = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        String requestId = identificadorRequisicaoDe(session.getUri());
        if (requestId == null || requestId.isBlank()) {
            fecharSilenciosamente(session, CloseStatus.BAD_DATA);
            return;
        }
        sessionsByRequest.computeIfAbsent(requestId, ignored -> ConcurrentHashMap.newKeySet()).add(session);
        requestBySession.put(session.getId(), requestId);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        remover(session);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        remover(session);
        fecharSilenciosamente(session, CloseStatus.SERVER_ERROR);
    }

    public void publicar(Progresso progress) {
        Set<WebSocketSession> sessions = sessionsByRequest.get(progress.requestId());
        if (sessions == null || sessions.isEmpty()) {
            return;
        }

        String payload = codificar(progress);
        for (WebSocketSession session : sessions) {
            if (!session.isOpen()) {
                remover(session);
                continue;
            }
            try {
                synchronized (session) {
                    if (session.isOpen()) session.sendMessage(new TextMessage(payload));
                }
            } catch (IOException | IllegalStateException ignored) {
                remover(session);
                fecharSilenciosamente(session, CloseStatus.SERVER_ERROR);
            }
        }
    }

    private String codificar(Progresso progress) {
        try {
            return objectMapper.writeValueAsString(progress);
        } catch (JsonProcessingException ignored) {
            return "{\"requestId\":\"" + progress.requestId() + "\",\"progress\":" + progress.progress() + "}";
        }
    }

    private String identificadorRequisicaoDe(URI uri) {
        if (uri == null || uri.getPath() == null) {
            return null;
        }
        String path = uri.getPath();
        int slash = path.lastIndexOf('/');
        if (slash < 0 || slash == path.length() - 1) {
            return null;
        }
        return path.substring(slash + 1);
    }

    private void remover(WebSocketSession session) {
        String requestId = requestBySession.remove(session.getId());
        if (requestId == null) {
            return;
        }
        Set<WebSocketSession> sessions = sessionsByRequest.get(requestId);
        if (sessions == null) {
            return;
        }
        sessions.remove(session);
        if (sessions.isEmpty()) {
            sessionsByRequest.remove(requestId);
        }
    }

    private void fecharSilenciosamente(WebSocketSession session, CloseStatus status) {
        try {
            if (session.isOpen()) {
                session.close(status);
            }
        } catch (IOException ignored) {
            // Best effort cleanup.
        }
    }
}
