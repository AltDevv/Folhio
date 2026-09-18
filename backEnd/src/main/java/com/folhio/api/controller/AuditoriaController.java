package com.folhio.api.controller;

import com.folhio.api.repository.EventoAuditoriaRepository;
import com.folhio.api.enums.AcaoAuditoria;
import org.springframework.web.bind.annotation.*;
import org.springframework.data.domain.PageRequest;
import java.util.*;

@RestController
@RequestMapping("/api/folhio/admin/audit")
public class AuditoriaController {
    private final com.folhio.api.service.AuditoriaProcessoService processos;
    public AuditoriaController(com.folhio.api.service.AuditoriaProcessoService processos) { this.processos=processos; }
    @GetMapping public Map<String,Object> listar(
            @RequestParam(required=false) String categoria,
            @RequestParam(required=false) String requestId,
            @RequestParam(defaultValue="0") int pagina) {
        return processos.listar(categoria, requestId, pagina);
    }
    public static String titulo(AcaoAuditoria acao) {
        return acao.obterDescricao();
    }
}
