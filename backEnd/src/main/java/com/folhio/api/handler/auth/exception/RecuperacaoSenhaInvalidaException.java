package com.folhio.api.handler.auth.exception;

import com.folhio.api.handler.NegocioException;

public class RecuperacaoSenhaInvalidaException extends NegocioException {
    public RecuperacaoSenhaInvalidaException() { super("Codigo de recuperacao invalido ou expirado."); }
    public RecuperacaoSenhaInvalidaException(String mensagem) { super(mensagem); }
    public RecuperacaoSenhaInvalidaException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
