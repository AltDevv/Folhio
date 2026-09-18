package com.folhio.api.security.authentication;

import com.folhio.api.entity.Usuario;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class TokenAcessoService {
    private static final Base64.Encoder URL_ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder URL_DECODER = Base64.getUrlDecoder();
    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
    };

    private final ObjectMapper objectMapper;
    private final byte[] secret;
    private final long accessTokenSeconds;

    public TokenAcessoService(
            ObjectMapper objectMapper,
            @Value("${folhio.auth.access-token-secret:}") String secret,
            @Value("${folhio.auth.access-token-minutes:20}") long accessTokenMinutes
    ) {
        this.objectMapper = objectMapper;
        this.secret = secret == null ? new byte[0] : secret.getBytes(StandardCharsets.UTF_8);
        this.accessTokenSeconds = Math.max(1, accessTokenMinutes) * 60;
    }

    public long expiraEmSegundos() {
        return accessTokenSeconds;
    }

    public String emitir(Usuario user) {
        validarSegredo();
        try {
            long now = Instant.now().getEpochSecond();
            Map<String, Object> header = Map.of("alg", "HS256", "typ", "JWT");
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("sub", user.obterId());
            payload.put("email", user.obterEmail());
            payload.put("name", user.obterNomeExibicao());
            payload.put("iat", now);
            payload.put("exp", now + accessTokenSeconds);

            String headerPart = codificarJson(header);
            String payloadPart = codificarJson(payload);
            String signaturePart = assinar(headerPart + "." + payloadPart);
            return headerPart + "." + payloadPart + "." + signaturePart;
        } catch (Exception error) {
            throw new IllegalStateException("Nao foi possivel emitir sessao.", error);
        }
    }

    public UsuarioAutenticado validar(String token) {
        validarSegredo();
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                throw new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Token invalido.");
            }
            String expectedSignature = assinar(parts[0] + "." + parts[1]);
            if (!compararEmTempoConstante(expectedSignature, parts[2])) {
                throw new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Token invalido.");
            }

            Map<String, Object> payload = objectMapper.readValue(URL_DECODER.decode(parts[1]), MAP_TYPE);
            long exp = numero(payload.get("exp"));
            if (exp <= Instant.now().getEpochSecond()) {
                throw new com.folhio.api.handler.auth.exception.SessaoExpiradaException("Sessao expirada.");
            }
            return new UsuarioAutenticado(
                    textoObrigatorio(payload.get("sub")),
                    textoObrigatorio(payload.get("email")),
                    textoObrigatorio(payload.get("name"))
            );
        } catch (com.folhio.api.handler.NegocioException error) {
            throw error;
        } catch (Exception error) {
            throw new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Token invalido.");
        }
    }

    private String codificarJson(Map<String, Object> value) throws Exception {
        return URL_ENCODER.encodeToString(objectMapper.writeValueAsBytes(value));
    }

    private String assinar(String value) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret, "HmacSHA256"));
        return URL_ENCODER.encodeToString(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
    }

    private void validarSegredo() {
        if (secret.length < 32) {
            throw new IllegalStateException("Configure FOLHIO_AUTH_ACCESS_TOKEN_SECRET com pelo menos 32 bytes.");
        }
    }

    private boolean compararEmTempoConstante(String expected, String provided) {
        byte[] left = expected.getBytes(StandardCharsets.UTF_8);
        byte[] right = provided.getBytes(StandardCharsets.UTF_8);
        return left.length == right.length && MessageDigest.isEqual(left, right);
    }

    private long numero(Object value) {
        if (value instanceof Number number) return number.longValue();
        throw new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Token invalido.");
    }

    private String textoObrigatorio(Object value) {
        if (value instanceof String text && !text.isBlank()) return text;
        throw new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Token invalido.");
    }
}
