package com.folhio.api.handler.file.exception;

import com.folhio.api.handler.NegocioException;

public class ArquivoInvalidoException extends NegocioException {
    public ArquivoInvalidoException() { super("O arquivo esta vazio, ilegivel ou corrompido."); }
    public ArquivoInvalidoException(String mensagem) { super(mensagem); }
    public ArquivoInvalidoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
