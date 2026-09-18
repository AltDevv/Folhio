package com.folhio.api.handler.processing.exception;

import com.folhio.api.handler.NegocioException;

public class OperacaoNaoSuportadaException extends NegocioException {
    public OperacaoNaoSuportadaException() { super("Essa operacao ainda nao e suportada."); }
    public OperacaoNaoSuportadaException(String mensagem) { super(mensagem); }
    public OperacaoNaoSuportadaException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
