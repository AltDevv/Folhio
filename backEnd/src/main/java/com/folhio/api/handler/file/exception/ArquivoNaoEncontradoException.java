package com.folhio.api.handler.file.exception;

import com.folhio.api.handler.NegocioException;

public class ArquivoNaoEncontradoException extends NegocioException {
    public ArquivoNaoEncontradoException() { super("Arquivo nao encontrado."); }
    public ArquivoNaoEncontradoException(String mensagem) { super(mensagem); }
    public ArquivoNaoEncontradoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
