package com.folhio.api.repository;

import com.folhio.api.entity.Usuario;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UsuarioRepository extends JpaRepository<Usuario, String> {
    @org.springframework.data.jpa.repository.Query("select u from AppUser u where u.emailNormalized = ?1")
    Optional<Usuario> buscarPorEmailNormalizado(String emailNormalized);

    @org.springframework.data.jpa.repository.Query("select u from AppUser u where u.googleSubject = ?1")
    Optional<Usuario> buscarPorIdentificadorGoogle(String googleSubject);
}
