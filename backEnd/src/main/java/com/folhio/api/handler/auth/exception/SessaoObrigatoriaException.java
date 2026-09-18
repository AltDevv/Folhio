package com.folhio.api.handler.auth.exception;

import com.folhio.api.handler.NegocioException;

public class SessaoObrigatoriaException extends NegocioException {
    public SessaoObrigatoriaException() { super("Entre na sua conta para continuar."); }
    public SessaoObrigatoriaException(String mensagem) { super(mensagem); }
    public SessaoObrigatoriaException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
