package com.folhio.api.config;

import com.folhio.api.logs.websocket.RegistroWebSocketHandler;
import com.folhio.api.progress.websocket.ProgressoWebSocketHandler;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class ConexaoWebSocketConfig implements WebSocketConfigurer {
    private final String[] allowedOrigins;

    private final ProgressoWebSocketHandler progressHandler;
    private final RegistroWebSocketHandler logHandler;

    public ConexaoWebSocketConfig(
            ProgressoWebSocketHandler progressHandler,
            RegistroWebSocketHandler logHandler,
            @org.springframework.beans.factory.annotation.Value("${folhio.websocket.allowed-origins:http://localhost:*,http://127.0.0.1:*}") String allowedOrigins
    ) {
        this.progressHandler = progressHandler;
        this.logHandler = logHandler;
        this.allowedOrigins = java.util.Arrays.stream(allowedOrigins.split(","))
                .map(String::trim).filter(value -> !value.isEmpty()).toArray(String[]::new);
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(progressHandler, "/ws/progress/{requestId}")
                .setAllowedOriginPatterns(allowedOrigins);
        registry.addHandler(logHandler, "/ws/logs")
                .setAllowedOriginPatterns(allowedOrigins);
    }
}
