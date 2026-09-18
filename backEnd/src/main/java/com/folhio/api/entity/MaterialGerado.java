package com.folhio.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity(name = "GeneratedMaterial")
@Table(
        name = "generated_materials",
        indexes = {
                @Index(name = "idx_generated_materials_owner", columnList = "owner_client_id"),
                @Index(name = "idx_generated_materials_created", columnList = "created_at")
        }
)
public class MaterialGerado {

    @Id
    @Column(nullable = false, updatable = false, length = 36)
    private String id;

    @Column(name = "owner_client_id", nullable = false, length = 96)
    private String ownerClientId;

    @Column(name = "file_id", nullable = false, length = 36)
    private String fileId;

    @Column(name = "file_name", nullable = false, length = 180)
    private String fileName;

    @Column(nullable = false, length = 160)
    private String title;

    @Column(name = "material_type", nullable = false, length = 50)
    private String materialType;

    @Column(length = 80)
    private String discipline;

    @Column(length = 120)
    private String subject;

    @Column(name = "school_year", length = 40)
    private String schoolYear;

    @Column(length = 40)
    private String difficulty;

    @Column(name = "template_id", nullable = false, length = 60)
    private String templateId;

    @Column(name = "question_count", nullable = false)
    private int questionCount;

    @Lob
    @Column(name = "question_ids_json")
    private String questionIdsJson;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected MaterialGerado() {
    }

    public MaterialGerado(
            String ownerClientId,
            String fileId,
            String fileName,
            String title,
            String materialType,
            String discipline,
            String subject,
            String schoolYear,
            String difficulty,
            String templateId,
            int questionCount,
            String questionIdsJson
    ) {
        this.id = UUID.randomUUID().toString();
        this.ownerClientId = ownerClientId;
        this.fileId = fileId;
        this.fileName = fileName;
        this.title = title;
        this.materialType = materialType;
        this.discipline = discipline;
        this.subject = subject;
        this.schoolYear = schoolYear;
        this.difficulty = difficulty;
        this.templateId = templateId;
        this.questionCount = questionCount;
        this.questionIdsJson = questionIdsJson;
        this.createdAt = Instant.now();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("id")
    public String obterId() {
        return id;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("ownerClientId")
    public String obterIdentificadorClienteProprietario() {
        return ownerClientId;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("fileId")
    public String obterIdentificadorArquivo() {
        return fileId;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("fileName")
    public String obterNomeArquivo() {
        return fileName;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("title")
    public String obterTitulo() {
        return title;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("materialType")
    public String obterTipoMaterial() {
        return materialType;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("discipline")
    public String obterDisciplina() {
        return discipline;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("subject")
    public String obterAssunto() {
        return subject;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("schoolYear")
    public String obterAnoEscolar() {
        return schoolYear;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("difficulty")
    public String obterDificuldade() {
        return difficulty;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("templateId")
    public String obterIdentificadorModelo() {
        return templateId;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("questionCount")
    public int obterQuantidadeQuestoes() {
        return questionCount;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("createdAt")
    public Instant obterDataCriacao() {
        return createdAt;
    }
}
