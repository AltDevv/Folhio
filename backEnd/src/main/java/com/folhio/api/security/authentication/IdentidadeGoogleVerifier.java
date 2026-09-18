package com.folhio.api.security.authentication;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@Component
public class IdentidadeGoogleVerifier {
    private final RestClient restClient = RestClient.create();
    private final String clientId;

    public IdentidadeGoogleVerifier(@Value("${folhio.auth.google-client-id:}") String clientId) {
        this.clientId = clientId == null ? "" : clientId.trim();
    }

    public PerfilGoogle verificar(String idToken) {
        if (clientId.isBlank()) {
            throw new com.folhio.api.handler.integration.exception.ServicoGoogleIndisponivelException("Login com Google ainda nao foi configurado neste ambiente.");
        }
        String encoded = URLEncoder.encode(idToken, StandardCharsets.UTF_8);
        @SuppressWarnings("unchecked")
        Map<String, Object> payload;
        try {
            payload = restClient.get()
                    .uri("https://oauth2.googleapis.com/tokeninfo?id_token=" + encoded)
                    .retrieve()
                    .body(Map.class);
        } catch (RestClientResponseException error) {
            if (error.getStatusCode().is5xxServerError() || error.getStatusCode().value() == 429) {
                throw new com.folhio.api.handler.integration.exception.ServicoGoogleIndisponivelException(
                        "Servico do Google indisponivel no momento.", error);
            }
            throw new com.folhio.api.handler.auth.exception.LoginGoogleInvalidoException("Login do Google invalido.");
        } catch (RestClientException error) {
            throw new com.folhio.api.handler.integration.exception.ServicoGoogleIndisponivelException("Servico do Google indisponivel no momento.", error);
        }
        if (payload == null) {
            throw new com.folhio.api.handler.auth.exception.LoginGoogleInvalidoException("Login do Google invalido.");
        }
        String issuer = texto(payload.get("iss"));
        if (!"accounts.google.com".equals(issuer) && !"https://accounts.google.com".equals(issuer)) {
            throw new com.folhio.api.handler.auth.exception.LoginGoogleInvalidoException("Login do Google invalido.");
        }
        String audience = texto(payload.get("aud"));
        if (!audienciaPermitida(clientId, audience)) {
            throw new com.folhio.api.handler.auth.exception.LoginGoogleInvalidoException("Login do Google invalido para este app.");
        }
        boolean verified = Boolean.parseBoolean(texto(payload.get("email_verified")));
        if (!verified) {
            throw new com.folhio.api.handler.auth.exception.LoginGoogleInvalidoException("O email do Google precisa estar verificado.");
        }
        String subject = texto(payload.get("sub"));
        String email = texto(payload.get("email"));
        if (subject.isBlank() || email.isBlank()) {
            throw new com.folhio.api.handler.auth.exception.LoginGoogleInvalidoException("Login do Google invalido.");
        }
        return new PerfilGoogle(
                subject,
                email,
                texto(payload.get("name")),
                texto(payload.get("picture"))
        );
    }

    static boolean audienciaPermitida(String configuredClientId, String tokenAudience) {
        if (configuredClientId == null || tokenAudience == null) {
            return false;
        }
        String configured = configuredClientId.trim();
        String audience = tokenAudience.trim();
        String configuredProject = numeroProjetoGoogle(configured);
        String audienceProject = numeroProjetoGoogle(audience);
        if (configuredProject.isBlank() || audienceProject.isBlank()) {
            return false;
        }
        return configured.equals(audience) || configuredProject.equals(audienceProject);
    }

    private static String numeroProjetoGoogle(String clientId) {
        if (!clientId.endsWith(".apps.googleusercontent.com")) {
            return "";
        }
        int separator = clientId.indexOf('-');
        if (separator <= 0) {
            return "";
        }
        String projectNumber = clientId.substring(0, separator);
        return projectNumber.chars().allMatch(Character::isDigit) ? projectNumber : "";
    }

    private String texto(Object value) {
        return value == null ? "" : value.toString().trim();
    }

    public record PerfilGoogle(String subject, String email, String name, String picture) {
    }
}
