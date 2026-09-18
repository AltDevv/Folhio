package com.folhio.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity(name = "AppUser")
@Table(
        name = "app_users",
        indexes = {
                @Index(name = "idx_app_users_email_normalized", columnList = "email_normalized", unique = true),
                @Index(name = "idx_app_users_google_subject", columnList = "google_subject")
        }
)
public class Usuario {

    @Id
    @Column(nullable = false, updatable = false, length = 36)
    private String id;

    @Column(name = "email_normalized", nullable = false, unique = true, length = 320)
    private String emailNormalized;

    @Column(nullable = false, length = 320)
    private String email;

    @Column(name = "display_name", nullable = false, length = 120)
    private String displayName;

    @Column(name = "password_hash", length = 120)
    private String passwordHash;

    @Column(name = "google_subject", length = 160)
    private String googleSubject;

    @Column(name = "avatar_url", length = 1024)
    private String avatarUrl;

    @Column(name = "email_verified", nullable = false)
    private boolean emailVerified;

    @Column(nullable = false)
    private boolean disabled;

    @Column(name = "two_factor_enabled")
    private Boolean twoFactorEnabled;

    @Column(name = "two_factor_method", length = 20)
    private String twoFactorMethod;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Usuario() {
    }

    public Usuario(String email, String displayName) {
        this.id = UUID.randomUUID().toString();
        this.email = email;
        this.emailNormalized = normalizarEmail(email);
        this.displayName = displayName;
        this.createdAt = Instant.now();
        this.updatedAt = this.createdAt;
    }

    public static String normalizarEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }

    public static String emailGoogleCanonico(String email) {
        String normalized = normalizarEmail(email);
        int separator = normalized.lastIndexOf('@');
        if (separator <= 0) {
            return normalized;
        }
        String local = normalized.substring(0, separator);
        String domain = normalized.substring(separator + 1);
        if (!domain.equals("gmail.com") && !domain.equals("googlemail.com")) {
            return normalized;
        }
        int plus = local.indexOf('+');
        if (plus >= 0) {
            local = local.substring(0, plus);
        }
        return local.replace(".", "") + "@gmail.com";
    }

    public void atualizarDataModificacao() {
        this.updatedAt = Instant.now();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("id")
    public String obterId() {
        return id;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("emailNormalized")
    public String obterEmailNormalizado() {
        return emailNormalized;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("email")
    public String obterEmail() {
        return email;
    }

    public void definirEmail(String email) {
        this.email = email;
        this.emailNormalized = normalizarEmail(email);
        atualizarDataModificacao();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("displayName")
    public String obterNomeExibicao() {
        return displayName;
    }

    public void definirNomeExibicao(String displayName) {
        this.displayName = displayName;
        atualizarDataModificacao();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("passwordHash")
    public String obterHashSenha() {
        return passwordHash;
    }

    public void definirHashSenha(String passwordHash) {
        this.passwordHash = passwordHash;
        atualizarDataModificacao();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("googleSubject")
    public String obterIdentificadorGoogle() {
        return googleSubject;
    }

    public void definirIdentificadorGoogle(String googleSubject) {
        this.googleSubject = googleSubject;
        atualizarDataModificacao();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("avatarUrl")
    public String obterUrlAvatar() {
        return avatarUrl;
    }

    public void definirUrlAvatar(String avatarUrl) {
        this.avatarUrl = avatarUrl;
        atualizarDataModificacao();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("emailVerified")
    public boolean emailVerificado() {
        return emailVerified;
    }

    public void definirEmailVerificado(boolean emailVerified) {
        this.emailVerified = emailVerified;
        atualizarDataModificacao();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("disabled")
    public boolean estaDesativado() {
        return disabled;
    }

    public void definirDesativado(boolean disabled) {
        this.disabled = disabled;
        atualizarDataModificacao();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("twoFactorEnabled")
    public boolean doisFatoresAtivado() {
        return Boolean.TRUE.equals(twoFactorEnabled);
    }

    public void definirDoisFatoresAtivado(boolean twoFactorEnabled) {
        this.twoFactorEnabled = twoFactorEnabled;
        atualizarDataModificacao();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("twoFactorMethod")
    public String obterMetodoDoisFatores() {
        return twoFactorMethod;
    }

    public void definirMetodoDoisFatores(String twoFactorMethod) {
        this.twoFactorMethod = twoFactorMethod;
        atualizarDataModificacao();
    }
}
