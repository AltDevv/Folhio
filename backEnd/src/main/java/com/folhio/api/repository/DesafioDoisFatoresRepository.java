package com.folhio.api.repository;

import com.folhio.api.entity.Usuario;
import com.folhio.api.entity.DesafioDoisFatores;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface DesafioDoisFatoresRepository extends JpaRepository<DesafioDoisFatores, String> {
    @org.springframework.data.jpa.repository.Query("select c from AuthTwoFactorChallenge c where c.tokenHash = ?1")
    Optional<DesafioDoisFatores> buscarPorHashToken(String tokenHash);

    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Modifying(flushAutomatically = true)
    @org.springframework.data.jpa.repository.Query("delete from AuthTwoFactorChallenge c where c.user = ?1")
    int excluirPorUsuario(Usuario user);
}
