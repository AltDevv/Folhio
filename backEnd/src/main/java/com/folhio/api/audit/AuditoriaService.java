package com.folhio.api.audit;

import com.folhio.api.entity.EventoAuditoria;
import com.folhio.api.enums.AcaoAuditoria;
import com.folhio.api.repository.EventoAuditoriaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuditoriaService {
    private final EventoAuditoriaRepository events;
    private final com.folhio.api.service.RegistroSistemaService registros;

    public AuditoriaService(EventoAuditoriaRepository events, com.folhio.api.service.RegistroSistemaService registros) {
        this.events = events;
        this.registros = registros;
    }

    @Transactional
    public void registrar(AcaoAuditoria action, String actor, String resource) {
        events.save(new EventoAuditoria(action, actor, resource));
        registros.informacao("AUDITORIA", "auditoria." + action.name().toLowerCase(),
                action.obterDescricao(),
                java.util.Map.of("acao",action.name(),"atorId",actor==null?"sistema":actor,
                        "recursoId",resource==null?"":resource));
    }
}
