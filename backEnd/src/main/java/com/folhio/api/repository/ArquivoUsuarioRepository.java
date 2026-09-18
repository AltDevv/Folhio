package com.folhio.api.repository;

import com.folhio.api.entity.ArquivoUsuario;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ArquivoUsuarioRepository extends JpaRepository<ArquivoUsuario, String> {
    @org.springframework.data.jpa.repository.Query("select (count(f) > 0) from UserFile f where f.storedFile.id = ?1 and f.ownerClientId = ?2")
    boolean existePorArquivoEClienteProprietario(String storedFileId, String ownerClientId);

    @org.springframework.data.jpa.repository.Query("select f from UserFile f where f.ownerClientId = ?1 order by f.createdAt desc")
    List<ArquivoUsuario> buscarPorClienteProprietarioOrdenadosPorCriacao(String ownerClientId, Pageable pageable);

    @org.springframework.data.jpa.repository.Query("select f from UserFile f where f.storedFile.id = ?1")
    List<ArquivoUsuario> buscarPorIdentificadorArquivo(String storedFileId);

    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Modifying(flushAutomatically = true)
    @org.springframework.data.jpa.repository.Query("delete from UserFile f where f.storedFile.id = ?1")
    void excluirPorIdentificadorArquivo(String storedFileId);
}
