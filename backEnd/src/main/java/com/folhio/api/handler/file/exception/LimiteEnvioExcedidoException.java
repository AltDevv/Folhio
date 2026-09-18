package com.folhio.api.handler.file.exception;

public class LimiteEnvioExcedidoException extends com.folhio.api.handler.NegocioException {
    public LimiteEnvioExcedidoException() {
        super("O arquivo deve ser menor que o limite configurado de upload.");
    }
}
