package com.folhio.api.handler.auth.exception;

import com.folhio.api.handler.NegocioException;

public class LoginGoogleInvalidoException extends NegocioException {
    public LoginGoogleInvalidoException() { super("Nao foi possivel validar o login do Google."); }
    public LoginGoogleInvalidoException(String mensagem) { super(mensagem); }
    public LoginGoogleInvalidoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
