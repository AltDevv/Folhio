package com.folhio.api.handler.user.exception;

import com.folhio.api.handler.NegocioException;

public class ContaAmbiguaException extends NegocioException {
    public ContaAmbiguaException() { super("Nao foi possivel identificar uma unica conta. Entre em contato com o suporte."); }
    public ContaAmbiguaException(String mensagem) { super(mensagem); }
    public ContaAmbiguaException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
