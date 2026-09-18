package com.folhio.api.security;

import jakarta.servlet.http.HttpServletRequest;

import java.util.regex.Pattern;

public final class IdentidadeCliente {

    public static final String HEADER_NAME = "X-Folhio-Client-Id";
    private static final Pattern SAFE_CLIENT_ID = Pattern.compile("^[A-Za-z0-9._:-]{12,120}$");

    private IdentidadeCliente() {
    }

    public static String obrigatorio(HttpServletRequest request) {
        String value = request == null ? "" : request.getHeader(HEADER_NAME);
        if (!ehValido(value)) {
            throw new com.folhio.api.handler.auth.exception.IdentificadorClienteInvalidoException("Identificador do app ausente ou invalido.");
        }
        return value;
    }

    public static boolean ehValido(String value) {
        return value != null && SAFE_CLIENT_ID.matcher(value).matches();
    }
}
