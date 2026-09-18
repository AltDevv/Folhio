package com.folhio.api.handler.auth.exception;

import com.folhio.api.handler.NegocioException;

public class SenhaAtualInvalidaException extends NegocioException {
    public SenhaAtualInvalidaException() { super("Senha atual invalida."); }
    public SenhaAtualInvalidaException(String mensagem) { super(mensagem); }
    public SenhaAtualInvalidaException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
