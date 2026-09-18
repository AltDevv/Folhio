package com.folhio.api.repository;

import com.folhio.api.entity.RegistroSistema;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface RegistroSistemaRepository extends JpaRepository<RegistroSistema, UUID> {

    @Query("""
        select r from SystemLog r
        where r.origem = 'backend' and r.categoria not in ('CLIENTE', 'AUDITORIA')
          and (r.caminho is null or r.caminho not like '/api/folhio/admin/%')
          and r.criadoEm >= :desde
          and (:categoria = '' or r.categoria = :categoria)
          and (:requestId = '' or r.requestId = :requestId)
        order by r.criadoEm desc, r.id desc
        """)
    org.springframework.data.domain.Page<RegistroSistema> consultarProcessos(
        @Param("categoria") String categoria, @Param("requestId") String requestId,
        @Param("desde") Instant desde, Pageable pageable);

    @Query("""
        select r.evento, count(r), avg(r.duracaoMs), count(r.duracaoMs) from SystemLog r
        where r.origem = 'backend' and r.categoria = 'ACAO' and r.criadoEm >= :desde
        group by r.evento
        """)
    List<Object[]> resumirProcessos(@Param("desde") Instant desde);

    @Query("select count(r) from SystemLog r where r.nivel = ?1")
    long contarPorNivel(String nivel);

    @Query("select count(r) from SystemLog r where r.categoria = ?1")
    long contarPorCategoria(String categoria);

    @Query("select (count(r) > 0) from SystemLog r where r.evento = ?1 and r.criadoEm > ?2")
    boolean existePorEventoECriadoApos(String evento, Instant criadoEm);

    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Modifying(flushAutomatically = true)
    @Query("delete from SystemLog r where r.criadoEm < ?1")
    int excluirCriadosAntesDe(Instant criadoEm);

    @Query("select r from SystemLog r where r.criadoEm > ?1 order by r.criadoEm asc")
    List<RegistroSistema> buscarCriadosAposOrdenadosPorCriacao(Instant criadoEm);

    @Query("""
            select registro
            from SystemLog registro
            where (:nivel is null or registro.nivel = :nivel)
              and (:categoria is null or registro.categoria = :categoria)
            order by registro.criadoEm desc
            """)
    List<RegistroSistema> buscarRecentesSemBusca(
            @Param("nivel") String nivel,
            @Param("categoria") String categoria,
            Pageable pageable
    );

    @Query("""
            select registro
            from SystemLog registro
            where (:nivel is null or registro.nivel = :nivel)
              and (:categoria is null or registro.categoria = :categoria)
              and (
                :busca is null
                or lower(concat(
                    coalesce(registro.evento, ''), ' ',
                    coalesce(registro.mensagem, ''), ' ',
                    coalesce(registro.requestId, ''), ' ',
                    coalesce(registro.caminho, '')
                )) like lower(concat('%', :busca, '%'))
              )
            order by registro.criadoEm desc
            """)
    List<RegistroSistema> buscarRecentes(
            @Param("nivel") String nivel,
            @Param("categoria") String categoria,
            @Param("busca") String busca,
            Pageable pageable
    );
}
