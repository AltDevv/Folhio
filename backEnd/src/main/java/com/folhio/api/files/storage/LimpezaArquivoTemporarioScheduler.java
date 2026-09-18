package com.folhio.api.files.storage;

import com.folhio.api.service.ArquivoArmazenadoService;

import com.folhio.api.service.RegistroSistemaService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Map;

@Component
public class LimpezaArquivoTemporarioScheduler {

    private final ArquivoArmazenadoService storageService;
    private final RegistroSistemaService registros;
    private final Duration maxAge;

    public LimpezaArquivoTemporarioScheduler(
            ArquivoArmazenadoService storageService,
            RegistroSistemaService registros,
            @Value("${folhio.storage.temp-retention-minutes:120}") long tempRetentionMinutes
    ) {
        this.storageService = storageService;
        this.registros = registros;
        this.maxAge = Duration.ofMinutes(Math.max(10, tempRetentionMinutes));
    }

    @Scheduled(fixedDelayString = "${folhio.storage.cleanup-interval-ms:900000}")
    public void limparArquivosTemporariosExpirados() {
        int deleted = storageService.limparArquivosTemporariosExpirados(maxAge);
        if (deleted > 0) {
            registros.informacao(
                    "ARQUIVO",
                    "arquivo.temporarios.limpos",
                    "Arquivos temporarios expirados foram removidos.",
                    Map.of("deletedDirectories", deleted, "retentionMinutes", maxAge.toMinutes())
            );
        }
    }
}
