package com.folhio.api.service;

import com.folhio.api.entity.RegistroSistema;
import com.folhio.api.repository.RegistroSistemaRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import java.time.Instant;
import java.time.Duration;
import java.util.*;

@Service
public class AuditoriaProcessoService {
    private final RegistroSistemaRepository repository;
    public AuditoriaProcessoService(RegistroSistemaRepository repository) { this.repository = repository; }

    public Map<String, Object> listar(String categoria, String requestId, int pagina) {
        var resultados = repository.consultarProcessos(categoria == null ? "" : categoria.trim(),
                requestId == null ? "" : requestId.trim(), Instant.now().minus(Duration.ofDays(10)),
                PageRequest.of(Math.max(0, pagina), 50));
        return Map.of("itens", resultados.map(this::resposta).getContent(),
                "pagina", resultados.getNumber(), "totalPaginas", resultados.getTotalPages(),
                "total", resultados.getTotalElements(), "retencaoDias", 10);
    }

    public Map<String, Object> resumo() {
        long concluidos = 0, falhas = 0, medidos = 0;
        double duracao = 0;
        for (Object[] linha : repository.resumirProcessos(Instant.now().minus(Duration.ofHours(24)))) {
            String evento = (String) linha[0];
            long quantidade = ((Number) linha[1]).longValue();
            if ("acao.concluida".equals(evento)) concluidos = quantidade;
            if ("acao.erro".equals(evento)) falhas = quantidade;
            if (linha[2] != null && ("acao.concluida".equals(evento) || "acao.erro".equals(evento))) {
                long quantidadeMedida = ((Number) linha[3]).longValue();
                duracao += ((Number) linha[2]).doubleValue() * quantidadeMedida;
                medidos += quantidadeMedida;
            }
        }
        Map<String, Object> resumo = new LinkedHashMap<>();
        resumo.put("concluidos", concluidos); resumo.put("falhas", falhas);
        resumo.put("duracaoMediaMs", medidos == 0 ? null : Math.round(duracao / medidos));
        resumo.put("periodoHoras", 24);
        resumo.put("recentes", repository.consultarProcessos("", "", Instant.now().minus(Duration.ofDays(10)),
                PageRequest.of(0, 8)).map(this::resposta).getContent());
        return resumo;
    }

    private Map<String, Object> resposta(RegistroSistema evento) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", evento.obterId()); item.put("quando", evento.obterCriadoEm());
        item.put("componente", evento.obterCategoria()); item.put("evento", evento.obterEvento());
        item.put("titulo", evento.obterMensagem()); item.put("requestId", evento.obterIdentificadorRequisicao());
        item.put("duracaoMs", evento.obterDuracaoMs()); item.put("statusHttp", evento.obterStatusHttp());
        String resultado = "ERRO".equals(evento.obterNivel()) ? "Falha"
                : "AVISO".equals(evento.obterNivel()) ? "Aviso"
                : "acao.iniciada".equals(evento.obterEvento()) ? "Iniciado"
                : "acao.concluida".equals(evento.obterEvento()) ? "Concluído" : "Registrado";
        item.put("resultado", resultado);
        return item;
    }
}
