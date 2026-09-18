package com.folhio.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity(name = "AuthTwoFactorChallenge")
@Table(
        name = "auth_two_factor_challenges",
        indexes = {
                @Index(name = "idx_auth_2fa_token_hash", columnList = "token_hash", unique = true),
                @Index(name = "idx_auth_2fa_user", columnList = "user_id")
        }
)
public class DesafioDoisFatores {
    @Id
    @Column(nullable = false, updatable = false, length = 36)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private Usuario user;

    @Column(name = "token_hash", nullable = false, unique = true, length = 96)
    private String tokenHash;

    @Column(name = "code_hash", nullable = false, length = 96)
    private String codeHash;

    @Column(name = "client_id_hash", length = 96)
    private String clientIdHash;

    @Column(nullable = false, length = 20)
    private String method;

    @Column(length = 40)
    private String purpose;

    @Column(name = "needs_name_confirmation", nullable = false)
    private boolean needsNameConfirmation;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "used_at")
    private Instant usedAt;

    protected DesafioDoisFatores() {
    }

    public DesafioDoisFatores(
            Usuario user,
            String tokenHash,
            String codeHash,
            String clientIdHash,
            String method,
            boolean needsNameConfirmation,
            Instant expiresAt
    ) {
        this(user, tokenHash, codeHash, clientIdHash, method, "login", needsNameConfirmation, expiresAt);
    }

    public DesafioDoisFatores(
            Usuario user,
            String tokenHash,
            String codeHash,
            String clientIdHash,
            String method,
            String purpose,
            boolean needsNameConfirmation,
            Instant expiresAt
    ) {
        this.id = UUID.randomUUID().toString();
        this.user = user;
        this.tokenHash = tokenHash;
        this.codeHash = codeHash;
        this.clientIdHash = clientIdHash;
        this.method = method;
        this.purpose = purpose;
        this.needsNameConfirmation = needsNameConfirmation;
        this.createdAt = Instant.now();
        this.expiresAt = expiresAt;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("user")
    public Usuario obterUsuario() {
        return user;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("codeHash")
    public String obterHashCodigo() {
        return codeHash;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("clientIdHash")
    public String obterHashIdentificadorCliente() {
        return clientIdHash;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("method")
    public String obterMetodo() {
        return method;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("purpose")
    public String obterFinalidade() {
        return purpose == null || purpose.isBlank() ? "login" : purpose;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("needsNameConfirmation")
    public boolean precisaConfirmacaoNome() {
        return needsNameConfirmation;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("expiresAt")
    public Instant obterDataExpiracao() {
        return expiresAt;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("usedAt")
    public Instant obterDataUso() {
        return usedAt;
    }

    public void marcarUsado() {
        this.usedAt = Instant.now();
    }
}
