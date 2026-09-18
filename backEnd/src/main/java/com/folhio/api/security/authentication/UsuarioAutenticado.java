package com.folhio.api.security.authentication;

public record UsuarioAutenticado(
        String id,
        String email,
        String name
) {
    public static final String REQUEST_ATTRIBUTE = "folhio.authenticatedUser";
}
