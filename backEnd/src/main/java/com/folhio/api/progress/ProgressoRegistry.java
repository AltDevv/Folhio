package com.folhio.api.progress;

import com.folhio.api.progress.state.Progresso;

import com.folhio.api.progress.websocket.ProgressoWebSocketHandler;
import org.springframework.stereotype.Service;

@Service
public class ProgressoRegistry {

    private final ProgressoWebSocketHandler webSockets;

    public ProgressoRegistry(ProgressoWebSocketHandler webSockets) {
        this.webSockets = webSockets;
    }

    public void iniciar(String requestId, String message) {
        atualizar(requestId, 0.02, message);
    }

    public void atualizar(String requestId, double progress, String message) {
        if (requestId == null || requestId.isBlank()) {
            return;
        }
        double normalized = Math.max(0.0, Math.min(1.0, progress));
        Progresso current = new Progresso(requestId, normalized, message, normalized >= 1.0);
        webSockets.publicar(current);
    }

    public void concluir(String requestId, String message) {
        atualizar(requestId, 1.0, message);
    }
}
