package com.folhio.api.repository;

import com.folhio.api.entity.Usuario;
import com.folhio.api.entity.SessaoRenovacao;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SessaoRenovacaoRepository extends JpaRepository<SessaoRenovacao, String> {
    @org.springframework.data.jpa.repository.Query("select s from AuthRefreshSession s where s.tokenHash = ?1")
    Optional<SessaoRenovacao> buscarPorHashToken(String tokenHash);

    @org.springframework.data.jpa.repository.Query("select s from AuthRefreshSession s where s.user = ?1 and s.revokedAt is null")
    List<SessaoRenovacao> buscarSessoesNaoRevogadasPorUsuario(Usuario user);

    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Modifying(flushAutomatically = true)
    @org.springframework.data.jpa.repository.Query("delete from AuthRefreshSession s where s.user = ?1")
    int excluirPorUsuario(Usuario user);
}
