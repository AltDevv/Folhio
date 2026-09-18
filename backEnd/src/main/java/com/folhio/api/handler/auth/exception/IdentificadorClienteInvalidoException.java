package com.folhio.api.handler.auth.exception;

import com.folhio.api.handler.NegocioException;

public class IdentificadorClienteInvalidoException extends NegocioException {
    public IdentificadorClienteInvalidoException() { super("Identificador do app ausente ou invalido."); }
    public IdentificadorClienteInvalidoException(String mensagem) { super(mensagem); }
    public IdentificadorClienteInvalidoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
