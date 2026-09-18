package com.folhio.api.handler.auth.exception;

import com.folhio.api.handler.NegocioException;

public class SessaoInvalidaException extends NegocioException {
    public SessaoInvalidaException() { super("Sessao invalida. Entre novamente."); }
    public SessaoInvalidaException(String mensagem) { super(mensagem); }
    public SessaoInvalidaException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
