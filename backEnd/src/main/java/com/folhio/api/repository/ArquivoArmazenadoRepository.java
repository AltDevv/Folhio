package com.folhio.api.repository;

import com.folhio.api.entity.ArquivoArmazenadoEntity;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

public interface ArquivoArmazenadoRepository extends JpaRepository<ArquivoArmazenadoEntity, String> {
    @org.springframework.data.jpa.repository.Query("select coalesce(sum(f.sizeBytes), 0) from StoredFileEntity f")
    long somarTamanhoRegistrado();
    @org.springframework.data.jpa.repository.Query("select f from StoredFileEntity f where f.persistent = false and f.updatedAt < ?1")
    List<ArquivoArmazenadoEntity> buscarTemporariosAtualizadosAntesDe(Instant threshold);

    @org.springframework.data.jpa.repository.Query("select f from StoredFileEntity f order by f.updatedAt desc")
    List<ArquivoArmazenadoEntity> buscarTodosPorAtualizacaoDecrescente(Pageable pageable);
}
