package com.folhio.api.security.authentication;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

@Component
public class TokenHasher {
    private final SecureRandom random = new SecureRandom();
    private final String pepper;

    public TokenHasher(@Value("${folhio.auth.password-pepper:}") String pepper) {
        this.pepper = pepper == null ? "" : pepper;
    }

    public String novoToken() {
        byte[] bytes = new byte[48];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public String calcularHash(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest((pepper + ":" + token).getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(hashed);
        } catch (Exception error) {
            throw new IllegalStateException("Nao foi possivel proteger o token.", error);
        }
    }
}
