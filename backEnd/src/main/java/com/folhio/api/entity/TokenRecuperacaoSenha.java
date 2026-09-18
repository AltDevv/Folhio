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

@Entity(name = "PasswordResetToken")
@Table(
        name = "password_reset_tokens",
        indexes = {
                @Index(name = "idx_password_reset_token_hash", columnList = "token_hash", unique = true),
                @Index(name = "idx_password_reset_user", columnList = "user_id")
        }
)
public class TokenRecuperacaoSenha {

    @Id
    @Column(nullable = false, updatable = false, length = 36)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private Usuario user;

    @Column(name = "token_hash", nullable = false, unique = true, length = 96)
    private String tokenHash;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "used_at")
    private Instant usedAt;

    protected TokenRecuperacaoSenha() {
    }

    public TokenRecuperacaoSenha(Usuario user, String tokenHash, Instant expiresAt) {
        this.id = UUID.randomUUID().toString();
        this.user = user;
        this.tokenHash = tokenHash;
        this.createdAt = Instant.now();
        this.expiresAt = expiresAt;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("user")
    public Usuario obterUsuario() {
        return user;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("tokenHash")
    public String obterHashToken() {
        return tokenHash;
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
