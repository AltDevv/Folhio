package com.folhio.api.repository;

import com.folhio.api.entity.Usuario;
import com.folhio.api.entity.TokenRecuperacaoSenha;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface TokenRecuperacaoSenhaRepository extends JpaRepository<TokenRecuperacaoSenha, String> {
    @org.springframework.data.jpa.repository.Query("select t from PasswordResetToken t where t.tokenHash = ?1")
    Optional<TokenRecuperacaoSenha> buscarPorHashToken(String tokenHash);

    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Modifying(flushAutomatically = true)
    @org.springframework.data.jpa.repository.Query("delete from PasswordResetToken t where t.user = ?1")
    int excluirPorUsuario(Usuario user);
}
