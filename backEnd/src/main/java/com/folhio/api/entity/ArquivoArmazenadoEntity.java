package com.folhio.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity(name = "StoredFileEntity")
@Table(
        name = "stored_files",
        indexes = {
                @Index(name = "idx_stored_files_storage_area", columnList = "storage_area"),
                @Index(name = "idx_stored_files_created_at", columnList = "created_at"),
                @Index(name = "idx_stored_files_persistent", columnList = "persistent")
        }
)
public class ArquivoArmazenadoEntity {

    @Id
    @Column(nullable = false, updatable = false, length = 36)
    private String id;

    @Column(name = "original_file_name", nullable = false, length = 180)
    private String originalFileName;

    @Column(name = "content_type", nullable = false, length = 160)
    private String contentType;

    @Column(name = "size_bytes", nullable = false)
    private long sizeBytes;

    @Column(name = "storage_area", nullable = false, length = 24)
    private String storageArea;

    @Column(name = "storage_key", nullable = false, unique = true, length = 700)
    private String storageKey;

    @Column(nullable = false)
    private boolean persistent;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected ArquivoArmazenadoEntity() {
    }

    public ArquivoArmazenadoEntity(
            String id,
            String originalFileName,
            String contentType,
            long sizeBytes,
            String storageArea,
            String storageKey,
            boolean persistent
    ) {
        this.id = id;
        this.originalFileName = originalFileName;
        this.contentType = contentType;
        this.sizeBytes = sizeBytes;
        this.storageArea = storageArea;
        this.storageKey = storageKey;
        this.persistent = persistent;
        this.createdAt = Instant.now();
        this.updatedAt = this.createdAt;
    }

    public void atualizarDataModificacao(long sizeBytes, String contentType) {
        this.sizeBytes = sizeBytes;
        this.contentType = contentType;
        this.updatedAt = Instant.now();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("id")
    public String obterId() {
        return id;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("originalFileName")
    public String obterNomeOriginalArquivo() {
        return originalFileName;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("contentType")
    public String obterTipoConteudo() {
        return contentType;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("sizeBytes")
    public long obterTamanhoBytes() {
        return sizeBytes;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("storageArea")
    public String obterAreaArmazenamento() {
        return storageArea;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("storageKey")
    public String obterChaveArmazenamento() {
        return storageKey;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("persistent")
    public boolean ehPersistente() {
        return persistent;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("createdAt")
    public Instant obterDataCriacao() {
        return createdAt;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("updatedAt")
    public Instant obterDataAtualizacao() {
        return updatedAt;
    }
}
