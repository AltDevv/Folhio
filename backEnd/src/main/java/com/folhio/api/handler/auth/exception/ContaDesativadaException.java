package com.folhio.api.handler.auth.exception;

import com.folhio.api.handler.NegocioException;

public class ContaDesativadaException extends NegocioException {
    public ContaDesativadaException() { super("Conta desativada."); }
    public ContaDesativadaException(String mensagem) { super(mensagem); }
    public ContaDesativadaException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
