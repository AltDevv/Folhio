package com.folhio.api.mapper;

import com.folhio.api.entity.Usuario;

import com.folhio.api.dto.auth.AutenticacaoDtos.ConfiguracaoDoisFatoresResponse;
import com.folhio.api.dto.auth.AutenticacaoDtos.UsuarioResponse;

public final class UsuarioMapper {

    private static final String TWO_FACTOR_EMAIL = "email";

    private UsuarioMapper() {
    }

    public static UsuarioResponse respostaUsuario(Usuario user) {
        return new UsuarioResponse(
                user.obterId(),
                user.obterNomeExibicao(),
                user.obterEmail(),
                user.obterUrlAvatar(),
                user.emailVerificado(),
                user.doisFatoresAtivado(),
                user.obterMetodoDoisFatores()
        );
    }

    public static ConfiguracaoDoisFatoresResponse respostaConfiguracaoDoisFatores(Usuario user, boolean emailSenderAvailable) {
        return new ConfiguracaoDoisFatoresResponse(
                user.doisFatoresAtivado(),
                metodoConfiguracaoDoisFatores(user),
                emailSenderAvailable,
                false,
                null,
                null
        );
    }

    public static String metodoConfiguracaoDoisFatores(Usuario user) {
        return user.obterMetodoDoisFatores() == null || user.obterMetodoDoisFatores().isBlank()
                ? TWO_FACTOR_EMAIL
                : user.obterMetodoDoisFatores();
    }
}
