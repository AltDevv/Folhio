package com.folhio.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity(name = "MaterialDocxTemplate")
@Table(
        name = "material_docx_templates",
        indexes = {
                @Index(name = "idx_material_templates_type", columnList = "material_type"),
                @Index(name = "idx_material_templates_active", columnList = "active")
        }
)
public class ModeloDocxMaterial {

    @Id
    @Column(nullable = false, updatable = false, length = 60)
    private String id;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(name = "material_type", nullable = false, length = 50)
    private String materialType;

    @Column(name = "style_code", nullable = false, length = 50)
    private String styleCode;

    @Column(name = "resource_path", nullable = false, length = 240)
    private String resourcePath;

    @Column(nullable = false, length = 300)
    private String description;

    @Column(nullable = false)
    private boolean active;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected ModeloDocxMaterial() {
    }

    public ModeloDocxMaterial(
            String id,
            String name,
            String materialType,
            String styleCode,
            String resourcePath,
            String description
    ) {
        this.id = id;
        this.name = name;
        this.materialType = materialType;
        this.styleCode = styleCode;
        this.resourcePath = resourcePath;
        this.description = description;
        this.active = true;
        this.createdAt = Instant.now();
        this.updatedAt = this.createdAt;
    }

    public void atualizarDadosCatalogo(ModeloDocxMaterial template) {
        this.name = template.name;
        this.materialType = template.materialType;
        this.styleCode = template.styleCode;
        this.resourcePath = template.resourcePath;
        this.description = template.description;
        this.updatedAt = Instant.now();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("id")
    public String obterId() {
        return id;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("name")
    public String obterNome() {
        return name;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("materialType")
    public String obterTipoMaterial() {
        return materialType;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("styleCode")
    public String obterCodigoEstilo() {
        return styleCode;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("resourcePath")
    public String obterCaminhoRecurso() {
        return resourcePath;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("description")
    public String obterDescricao() {
        return description;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("active")
    public boolean estaAtivo() {
        return active;
    }
}
