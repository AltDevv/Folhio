package com.folhio.api.progress;

import java.util.function.Supplier;

public final class ProgressoTracker {

    private static final ThreadLocal<ProgressoListener> CURRENT_LISTENER = new ThreadLocal<>();

    private ProgressoTracker() {
    }

    public static void comOuvinte(ProgressoListener listener, Runnable action) {
        CURRENT_LISTENER.set(listener);
        try {
            action.run();
        } finally {
            CURRENT_LISTENER.remove();
        }
    }

    public static <T> T comOuvinte(ProgressoListener listener, Supplier<T> action) {
        CURRENT_LISTENER.set(listener);
        try {
            return action.get();
        } finally {
            CURRENT_LISTENER.remove();
        }
    }

    public static void atualizar(double progress, String message) {
        ProgressoListener listener = CURRENT_LISTENER.get();
        if (listener != null) {
            listener.atualizar(progress, message);
        }
    }

    @FunctionalInterface
    public interface ProgressoListener {
        void atualizar(double progress, String message);
    }
}
