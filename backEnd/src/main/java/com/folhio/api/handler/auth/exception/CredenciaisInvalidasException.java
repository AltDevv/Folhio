package com.folhio.api.handler.auth.exception;

import com.folhio.api.handler.NegocioException;

public class CredenciaisInvalidasException extends NegocioException {
    public CredenciaisInvalidasException() { super("Email ou senha invalidos."); }
    public CredenciaisInvalidasException(String mensagem) { super(mensagem); }
    public CredenciaisInvalidasException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
