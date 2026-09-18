package com.folhio.api.repository;

import com.folhio.api.entity.EventoAuditoria;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EventoAuditoriaRepository extends JpaRepository<EventoAuditoria, String> {
    @org.springframework.data.jpa.repository.Query("select e from AuditEvent e where (:acao is null or e.action = :acao) and (:ator is null or e.actorId = :ator) order by e.createdAt desc")
    org.springframework.data.domain.Page<EventoAuditoria> consultar(
            @org.springframework.data.repository.query.Param("acao") com.folhio.api.enums.AcaoAuditoria acao,
            @org.springframework.data.repository.query.Param("ator") String ator,
            org.springframework.data.domain.Pageable pagina);
}
