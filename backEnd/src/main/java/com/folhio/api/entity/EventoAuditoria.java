package com.folhio.api.entity;

import com.folhio.api.enums.AcaoAuditoria;
import jakarta.persistence.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.Instant;
import java.util.UUID;

@Entity(name = "AuditEvent")
@Table(name = "audit_events")
@EntityListeners(AuditingEntityListener.class)
public class EventoAuditoria {
    @Id
    @Column(length = 36, nullable = false, updatable = false)
    private String id;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40, updatable = false)
    private AcaoAuditoria action;
    @Column(length = 120, updatable = false)
    private String actorId;
    @Column(length = 120, updatable = false)
    private String resourceId;
    @CreatedDate
    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    protected EventoAuditoria() {}

    public EventoAuditoria(AcaoAuditoria action, String actorId, String resourceId) {
        this.id = UUID.randomUUID().toString();
        this.action = action;
        this.actorId = actorId;
        this.resourceId = resourceId;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("createdAt")
    public Instant obterDataCriacao() { return createdAt; }
    @com.fasterxml.jackson.annotation.JsonProperty("action")
    public AcaoAuditoria obterAcao() { return action; }
    public String obterId() { return id; }
    public String obterRecurso() { return resourceId; }
    @com.fasterxml.jackson.annotation.JsonProperty("actorId")
    public String obterIdentificadorAutor() { return actorId; }
}
