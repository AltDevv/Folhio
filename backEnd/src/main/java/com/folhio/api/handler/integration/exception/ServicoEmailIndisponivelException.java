package com.folhio.api.handler.integration.exception;

import com.folhio.api.handler.NegocioException;

public class ServicoEmailIndisponivelException extends NegocioException {
    public ServicoEmailIndisponivelException() { super("O envio de email esta indisponivel no momento. Tente novamente mais tarde."); }
    public ServicoEmailIndisponivelException(String mensagem) { super(mensagem); }
    public ServicoEmailIndisponivelException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
