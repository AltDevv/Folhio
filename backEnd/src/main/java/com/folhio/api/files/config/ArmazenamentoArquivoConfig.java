package com.folhio.api.files.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class ArmazenamentoArquivoConfig {
    private final long maxUploadBytes;

    public ArmazenamentoArquivoConfig(@Value("${folhio.files.max-upload-bytes:262144000}") long maxUploadBytes) {
        if (maxUploadBytes <= 0) throw new IllegalArgumentException("Upload limit must be positive.");
        this.maxUploadBytes = maxUploadBytes;
    }

    public long limiteBytesEnvio() {
        return maxUploadBytes;
    }

    public void validarTamanho(long size) {
        if (size <= 0) throw new com.folhio.api.handler.file.exception.ArquivoInvalidoException("Arquivo vazio.");
        if (size >= maxUploadBytes) throw new com.folhio.api.handler.file.exception.LimiteEnvioExcedidoException();
    }
}
