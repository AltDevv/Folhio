package com.folhio.api.handler.integration.exception;

import com.folhio.api.handler.NegocioException;

public class ServicoGoogleIndisponivelException extends NegocioException {
    public ServicoGoogleIndisponivelException() { super("Login com Google indisponivel no momento."); }
    public ServicoGoogleIndisponivelException(String mensagem) { super(mensagem); }
    public ServicoGoogleIndisponivelException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
