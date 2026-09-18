package com.folhio.api.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public final class AutenticacaoDtos {
    private AutenticacaoDtos() {
    }

    public record CadastroRequest(
            @NotBlank @Size(max = 120) String name,
            @NotBlank @Email @Size(max = 320) String email,
            @NotBlank(message = "A senha deve ter pelo menos 8 caracteres, incluindo letras e numeros.")
            @Size(min = 8, max = 120, message = "A senha deve ter pelo menos 8 caracteres, incluindo letras e numeros.")
            @Pattern(regexp = "^(?=.*\\p{L})(?=.*\\d).+$", message = "A senha deve ter pelo menos 8 caracteres, incluindo letras e numeros.")
            String password
    ) {
    }

    public record EntradaRequest(
            @NotBlank @Email @Size(max = 320) String email,
            @NotBlank @Size(max = 120) String password
    ) {
    }

    public record EntradaGoogleRequest(
            @NotBlank String idToken
    ) {
    }

    public record RenovacaoRequest(
            @NotBlank String refreshToken
    ) {
    }

    public record VerificacaoDoisFatoresRequest(
            @NotBlank String twoFactorToken,
            @NotBlank @Size(min = 6, max = 6) String code
    ) {
    }

    public record AtualizacaoDoisFatoresRequest(
            boolean enabled,
            String method,
            String currentPassword,
            String twoFactorToken,
            String twoFactorCode
    ) {
    }

    public record RecuperacaoSenhaRequest(
            @NotBlank @Email @Size(max = 320) String email
    ) {
    }

    public record RedefinicaoSenhaRequest(
            @NotBlank String token,
            @NotBlank(message = "A senha deve ter pelo menos 8 caracteres, incluindo letras e numeros.")
            @Size(min = 8, max = 120, message = "A senha deve ter pelo menos 8 caracteres, incluindo letras e numeros.")
            @Pattern(regexp = "^(?=.*\\p{L})(?=.*\\d).+$", message = "A senha deve ter pelo menos 8 caracteres, incluindo letras e numeros.")
            String newPassword
    ) {
    }

    public record AtualizacaoPerfilRequest(
            @NotBlank @Size(max = 120) String name
    ) {
    }

    public record AtualizacaoContaRequest(
            @Size(max = 120) String name,
            @Email @Size(max = 320) String email,
            @Size(max = 120) String currentPassword,
            @Size(min = 8, max = 120, message = "A senha deve ter pelo menos 8 caracteres, incluindo letras e numeros.")
            @Pattern(regexp = "^(?=.*\\p{L})(?=.*\\d).*$", message = "A senha deve ter pelo menos 8 caracteres, incluindo letras e numeros.")
            String newPassword,
            String twoFactorToken,
            String twoFactorCode
    ) {
    }

    public record ExclusaoContaRequest(
            @Size(max = 120) String currentPassword,
            String twoFactorToken,
            String twoFactorCode
    ) {
    }

    public record UsuarioResponse(
            String id,
            String name,
            String email,
            String avatarUrl,
            boolean emailVerified,
            boolean twoFactorEnabled,
            String twoFactorMethod
    ) {
    }

    public record ConfiguracaoDoisFatoresResponse(
            boolean enabled,
            String method,
            boolean emailAvailable,
            boolean twoFactorRequired,
            String twoFactorToken,
            String twoFactorDestination
    ) {
    }

    public record AtualizacaoContaResponse(
            boolean success,
            UsuarioResponse user,
            boolean twoFactorRequired,
            String twoFactorToken,
            String twoFactorDestination,
            String message
    ) {
    }

    public record AutenticacaoResponse(
            boolean success,
            UsuarioResponse user,
            String accessToken,
            String refreshToken,
            long expiresInSeconds,
            boolean needsNameConfirmation,
            boolean twoFactorRequired,
            String twoFactorToken,
            String twoFactorMethod,
            String twoFactorDestination
    ) {
    }

    public record MensagemResponse(
            boolean success,
            String message
    ) {
    }
}
