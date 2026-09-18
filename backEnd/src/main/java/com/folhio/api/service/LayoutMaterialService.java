package com.folhio.api.service;

import com.folhio.api.dto.layout.LayoutDtos.*;
import com.folhio.api.entity.LayoutMaterial;
import com.folhio.api.repository.LayoutMaterialRepository;
import com.folhio.api.audit.AuditoriaService;
import com.folhio.api.enums.AcaoAuditoria;
import com.folhio.api.handler.material.exception.ModeloNaoEncontradoException;
import com.folhio.api.handler.validation.exception.DadosInvalidosException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.type.TypeReference;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.dao.OptimisticLockingFailureException;
import java.util.*;

@Service
public class LayoutMaterialService {
    private final LayoutMaterialRepository repository;
    private final AuditoriaService audit;
    private final ObjectMapper mapper = new ObjectMapper();
    public LayoutMaterialService(LayoutMaterialRepository repository, AuditoriaService audit) {
        this.repository=repository; this.audit=audit;
    }
    public List<LayoutResponse> listar(int pagina) {
        return repository.findAll(PageRequest.of(Math.max(0,pagina), 50,
                Sort.by(Sort.Direction.DESC,"atualizadoEm"))).stream().map(this::resposta).toList();
    }
    public LayoutResponse buscar(String id) { return resposta(obter(id)); }
    @Transactional
    public LayoutResponse salvar(String id, LayoutRequest request) {
        validarPaginas(request.paginas());
        LayoutMaterial layout;
        String json;
        try { json=mapper.writeValueAsString(request.paginas()); }
        catch (Exception erro) { throw new IllegalStateException("Falha ao serializar layout.",erro); }
        if (id==null) {
            layout=new LayoutMaterial(request.nome().trim(),request.descricao(),request.publicado(),json);
        } else {
            layout=obter(id);
            if (layout.obterVersao()!=request.versao()) {
                throw new OptimisticLockingFailureException("Layout alterado em outra sessao.");
            }
            layout.atualizar(request.nome().trim(),request.descricao(),request.publicado(),json);
        }
        layout=repository.saveAndFlush(layout);
        audit.registrar(id==null ? AcaoAuditoria.CREATE_LAYOUT : AcaoAuditoria.UPDATE_LAYOUT,
                "studio-admin",layout.obterId());
        return resposta(layout);
    }
    @Transactional
    public void excluir(String id, long versao) {
        LayoutMaterial layout=obter(id);
        if (layout.obterVersao()!=versao) throw new OptimisticLockingFailureException("Layout alterado.");
        repository.delete(layout);
        repository.flush();
        audit.registrar(AcaoAuditoria.DELETE_LAYOUT,"studio-admin",id);
    }
    private LayoutMaterial obter(String id) {
        return repository.findById(id).orElseThrow(ModeloNaoEncontradoException::new);
    }
    public void validarPaginas(List<Pagina> paginas) {
        Set<String> ids=new HashSet<>(), campos=new HashSet<>();
        int total=0;
        for (Pagina pagina:paginas) {
            if (!ids.add(pagina.id())) throw new DadosInvalidosException("Paginas com identificadores repetidos.");
            for (Bloco bloco:pagina.blocos()) {
                if (++total>500) throw new DadosInvalidosException("Use no maximo 500 blocos por layout.");
                if (!ids.add(bloco.id())) throw new DadosInvalidosException("Blocos com identificadores repetidos.");
                if (!Double.isFinite(bloco.x()) || !Double.isFinite(bloco.y()) ||
                    !Double.isFinite(bloco.largura()) || !Double.isFinite(bloco.altura()) ||
                    bloco.x()+bloco.largura()>210.01 || bloco.y()+bloco.altura()>297.01) {
                    throw new DadosInvalidosException("Um bloco ultrapassa os limites da pagina A4.");
                }
                if (!bloco.campo().isBlank() && !campos.add(bloco.campo())) {
                    throw new DadosInvalidosException("Cada campo de preenchimento precisa ter um nome unico.");
                }
                if (Set.of("enunciado","imagem","alternativas","resposta").contains(bloco.tipo())
                        && bloco.campo().isBlank()) {
                    throw new DadosInvalidosException("Informe o campo de preenchimento dos blocos dinamicos.");
                }
            }
        }
    }
    private LayoutResponse resposta(LayoutMaterial layout) {
        try {
            return new LayoutResponse(layout.obterId(),layout.obterNome(),layout.obterDescricao(),
                    layout.obterVersao(),layout.estaPublicado(),layout.obterAtualizadoEm(),
                    mapper.readValue(layout.obterPaginasJson(),new TypeReference<List<Pagina>>(){}),1);
        } catch (Exception erro) { throw new IllegalStateException("Falha ao ler layout salvo.",erro); }
    }
}
