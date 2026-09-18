package com.folhio.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name="material_layouts")
public class LayoutMaterial {
    @Id private String id;
    @Column(nullable=false, length=120) private String nome;
    @Column(length=500) private String descricao;
    @Version private long versao;
    private boolean publicado;
    @Column(nullable=false, columnDefinition="text") private String paginasJson;
    @Column(nullable=false) private Instant atualizadoEm;
    protected LayoutMaterial() {}
    public LayoutMaterial(String nome, String descricao, boolean publicado, String json) {
        id = UUID.randomUUID().toString();
        atualizar(nome, descricao, publicado, json);
    }
    public void atualizar(String nome, String descricao, boolean publicado, String json) {
        this.nome=nome; this.descricao=descricao; this.publicado=publicado;
        this.paginasJson=json; this.atualizadoEm=Instant.now();
    }
    public String obterId() { return id; }
    public String obterNome() { return nome; }
    public String obterDescricao() { return descricao; }
    public long obterVersao() { return versao; }
    public boolean estaPublicado() { return publicado; }
    public String obterPaginasJson() { return paginasJson; }
    public Instant obterAtualizadoEm() { return atualizadoEm; }
}
