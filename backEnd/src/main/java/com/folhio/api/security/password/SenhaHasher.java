package com.folhio.api.security.password;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

@Component
public class SenhaHasher {
    private final PasswordEncoder encoder = new BCryptPasswordEncoder(12);
    private final String pepper;

    public SenhaHasher(@Value("${folhio.auth.password-pepper:}") String pepper) {
        this.pepper = pepper == null ? "" : pepper;
    }

    public String calcularHash(String password) {
        return encoder.encode(materialSenha(password));
    }

    public boolean corresponde(String password, String hash) {
        if (hash == null) return false;
        if (encoder.matches(materialSenha(password), hash)) return true;

        // Compatibility for accounts created before password pre-hashing.
        String legacyMaterial = pepper + password;
        if (legacyMaterial.getBytes(StandardCharsets.UTF_8).length > 72) return false;
        return encoder.matches(legacyMaterial, hash);
    }

    private String materialSenha(String password) {
        if (password == null) throw new com.folhio.api.handler.validation.exception.DadosInvalidosException("Senha obrigatoria.");
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(pepper.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return Base64.getEncoder().encodeToString(mac.doFinal(password.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception error) {
            throw new IllegalStateException("Nao foi possivel proteger a senha.", error);
        }
    }
}
