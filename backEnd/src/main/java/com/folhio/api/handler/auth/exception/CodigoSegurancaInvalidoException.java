package com.folhio.api.handler.auth.exception;

import com.folhio.api.handler.NegocioException;

public class CodigoSegurancaInvalidoException extends NegocioException {
    public CodigoSegurancaInvalidoException() { super("Codigo de seguranca invalido ou expirado."); }
    public CodigoSegurancaInvalidoException(String mensagem) { super(mensagem); }
    public CodigoSegurancaInvalidoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
