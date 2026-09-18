package com.folhio.api.handler.auth.exception;

import com.folhio.api.handler.NegocioException;

public class SessaoExpiradaException extends NegocioException {
    public SessaoExpiradaException() { super("Sua sessao expirou. Entre novamente."); }
    public SessaoExpiradaException(String mensagem) { super(mensagem); }
    public SessaoExpiradaException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
