package com.folhio.api.entity;

import com.folhio.api.files.model.ArquivoArmazenado;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.Instant;
import java.util.UUID;

@Entity(name = "UserFile")
@Table(
        name = "user_files",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_user_files_file_owner", columnNames = {"stored_file_id", "owner_client_id"})
        },
        indexes = {
                @Index(name = "idx_user_files_owner_client", columnList = "owner_client_id"),
                @Index(name = "idx_user_files_owner_user", columnList = "owner_user_id"),
                @Index(name = "idx_user_files_file", columnList = "stored_file_id")
        }
)
public class ArquivoUsuario {

    @Id
    @Column(nullable = false, updatable = false, length = 36)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "stored_file_id", nullable = false)
    private ArquivoArmazenadoEntity storedFile;

    @Column(name = "owner_client_id", nullable = false, length = 120)
    private String ownerClientId;

    @Column(name = "owner_user_id", length = 36)
    private String ownerUserId;

    @Column(nullable = false, length = 40)
    private String role;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected ArquivoUsuario() {
    }

    public ArquivoUsuario(ArquivoArmazenadoEntity storedFile, String ownerClientId, String ownerUserId, String role) {
        this.id = UUID.randomUUID().toString();
        this.storedFile = storedFile;
        this.ownerClientId = ownerClientId;
        this.ownerUserId = ownerUserId;
        this.role = role;
        this.createdAt = Instant.now();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("storedFile")
    public ArquivoArmazenadoEntity obterArquivoArmazenado() {
        return storedFile;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("ownerClientId")
    public String obterIdentificadorClienteProprietario() {
        return ownerClientId;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("ownerUserId")
    public String obterIdentificadorUsuarioProprietario() {
        return ownerUserId;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("role")
    public String obterPapel() {
        return role;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("createdAt")
    public Instant obterDataCriacao() {
        return createdAt;
    }
}
