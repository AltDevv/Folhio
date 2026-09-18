package com.folhio.api.logs;

import com.folhio.api.service.RegistroSistemaService;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Map;

@Component
public class RegistroInicializacaoListener {

    private static final String EVENTO_BACKEND_INICIADO = "backend.iniciado";
    private static final Duration INTERVALO_MINIMO_ENTRE_REGISTROS = Duration.ofMinutes(5);

    private final RegistroSistemaService registros;

    public RegistroInicializacaoListener(RegistroSistemaService registros) {
        this.registros = registros;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void quandoAplicacaoEstiverPronta() {
        registros.limparLogsExpirados();
        if (registros.existeEventoRecente(EVENTO_BACKEND_INICIADO, INTERVALO_MINIMO_ENTRE_REGISTROS)) {
            return;
        }

        registros.informacao(
                "SISTEMA",
                EVENTO_BACKEND_INICIADO,
                "Backend iniciado e pronto para receber requisicoes.",
                Map.of(
                        "javaVersion", System.getProperty("java.version"),
                        "diretorio", System.getProperty("user.dir")
                )
        );
    }
}
