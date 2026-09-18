package com.folhio.api.handler.user.exception;

import com.folhio.api.handler.NegocioException;

public class EmailJaCadastradoException extends NegocioException {
    public EmailJaCadastradoException() { super("Ja existe uma conta com este email."); }
    public EmailJaCadastradoException(String mensagem) { super(mensagem); }
    public EmailJaCadastradoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
