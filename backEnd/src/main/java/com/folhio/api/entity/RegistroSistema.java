package com.folhio.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity(name = "SystemLog")
@Table(
        name = "app_logs",
        indexes = {
                @Index(name = "idx_app_logs_criado_em", columnList = "criado_em"),
                @Index(name = "idx_app_logs_nivel", columnList = "nivel"),
                @Index(name = "idx_app_logs_categoria", columnList = "categoria"),
                @Index(name = "idx_app_logs_request_id", columnList = "request_id")
        }
)
public class RegistroSistema {

    @Id
    private UUID id;

    @Column(name = "criado_em", nullable = false)
    private Instant criadoEm;

    @Column(nullable = false, length = 20)
    private String nivel;

    @Column(nullable = false, length = 40)
    private String origem;

    @Column(nullable = false, length = 60)
    private String categoria;

    @Column(nullable = false, length = 120)
    private String evento;

    @Column(nullable = false, length = 500)
    private String mensagem;

    @Column(name = "request_id", length = 80)
    private String requestId;

    @Column(length = 12)
    private String metodo;

    @Column(length = 500)
    private String caminho;

    @Column(name = "status_http")
    private Integer statusHttp;

    @Column(name = "duracao_ms")
    private Long duracaoMs;

    @Column(length = 80)
    private String ip;

    @Column(name = "user_agent", length = 300)
    private String userAgent;

    @Column(columnDefinition = "text")
    private String detalhes;

    public RegistroSistema() {
    }

    public RegistroSistema(
            String nivel,
            String origem,
            String categoria,
            String evento,
            String mensagem,
            String requestId,
            String metodo,
            String caminho,
            Integer statusHttp,
            Long duracaoMs,
            String ip,
            String userAgent,
            String detalhes
    ) {
        this.id = UUID.randomUUID();
        this.criadoEm = Instant.now();
        this.nivel = limite(nivel, 20);
        this.origem = limite(origem, 40);
        this.categoria = limite(categoria, 60);
        this.evento = limite(evento, 120);
        this.mensagem = limite(mensagem, 500);
        this.requestId = limite(requestId, 80);
        this.metodo = limite(metodo, 12);
        this.caminho = limite(caminho, 500);
        this.statusHttp = statusHttp;
        this.duracaoMs = duracaoMs;
        this.ip = limite(ip, 80);
        this.userAgent = limite(userAgent, 300);
        this.detalhes = detalhes;
    }

    private String limite(String valor, int tamanho) {
        if (valor == null) {
            return null;
        }
        return valor.length() <= tamanho ? valor : valor.substring(0, tamanho);
    }

    @com.fasterxml.jackson.annotation.JsonProperty("id")
    public UUID obterId() {
        return id;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("criadoEm")
    public Instant obterCriadoEm() {
        return criadoEm;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("nivel")
    public String obterNivel() {
        return nivel;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("origem")
    public String obterOrigem() {
        return origem;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("categoria")
    public String obterCategoria() {
        return categoria;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("evento")
    public String obterEvento() {
        return evento;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("mensagem")
    public String obterMensagem() {
        return mensagem;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("requestId")
    public String obterIdentificadorRequisicao() {
        return requestId;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("metodo")
    public String obterMetodo() {
        return metodo;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("caminho")
    public String obterCaminho() {
        return caminho;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("statusHttp")
    public Integer obterStatusHttp() {
        return statusHttp;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("duracaoMs")
    public Long obterDuracaoMs() {
        return duracaoMs;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("ip")
    public String obterIp() {
        return ip;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("userAgent")
    public String obterAgenteUsuario() {
        return userAgent;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("detalhes")
    public String obterDetalhes() {
        return detalhes;
    }
}
