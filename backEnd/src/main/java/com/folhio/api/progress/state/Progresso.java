package com.folhio.api.progress.state;

public record Progresso(
        String requestId,
        double progress,
        String message,
        boolean done
) {
}
