package com.folhio.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity(name = "MaterialQuestion")
@Table(
        name = "material_questions",
        indexes = {
                @Index(name = "idx_material_questions_filters", columnList = "discipline,subject,school_year,difficulty"),
                @Index(name = "idx_material_questions_active", columnList = "active")
        }
)
public class QuestaoMaterial {

    @Id
    @Column(nullable = false, updatable = false, length = 36)
    private String id;

    @Column(nullable = false, length = 80)
    private String discipline;

    @Column(nullable = false, length = 120)
    private String subject;

    @Column(name = "school_year", nullable = false, length = 40)
    private String schoolYear;

    @Column(nullable = false, length = 40)
    private String difficulty;

    @Column(nullable = false, length = 40)
    private String type;

    @Column(nullable = false, length = 1400)
    private String statement;

    @Lob
    @Column(name = "options_json")
    private String optionsJson;

    @Column(name = "correct_answer", length = 400)
    private String correctAnswer;

    @Column(length = 1600)
    private String explanation;

    @Column(name = "skill_tags", length = 500)
    private String skillTags;

    @Column(nullable = false)
    private boolean active;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected QuestaoMaterial() {
    }

    public QuestaoMaterial(
            String discipline,
            String subject,
            String schoolYear,
            String difficulty,
            String type,
            String statement,
            String optionsJson,
            String correctAnswer,
            String explanation,
            String skillTags
    ) {
        this(null, discipline, subject, schoolYear, difficulty, type, statement, optionsJson, correctAnswer, explanation, skillTags);
    }

    public QuestaoMaterial(
            String id,
            String discipline,
            String subject,
            String schoolYear,
            String difficulty,
            String type,
            String statement,
            String optionsJson,
            String correctAnswer,
            String explanation,
            String skillTags
    ) {
        this.id = id == null || id.isBlank() ? UUID.randomUUID().toString() : id;
        this.discipline = discipline;
        this.subject = subject;
        this.schoolYear = schoolYear;
        this.difficulty = difficulty;
        this.type = type;
        this.statement = statement;
        this.optionsJson = optionsJson;
        this.correctAnswer = correctAnswer;
        this.explanation = explanation;
        this.skillTags = skillTags;
        this.active = true;
        this.createdAt = Instant.now();
        this.updatedAt = this.createdAt;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("id")
    public String obterId() {
        return id;
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

    @com.fasterxml.jackson.annotation.JsonProperty("type")
    public String obterTipo() {
        return type;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("statement")
    public String obterEnunciado() {
        return statement;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("optionsJson")
    public String obterAlternativasJson() {
        return optionsJson;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("correctAnswer")
    public String obterRespostaCorreta() {
        return correctAnswer;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("explanation")
    public String obterExplicacao() {
        return explanation;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("skillTags")
    public String obterMarcadoresHabilidades() {
        return skillTags;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("active")
    public boolean estaAtivo() {
        return active;
    }
}
