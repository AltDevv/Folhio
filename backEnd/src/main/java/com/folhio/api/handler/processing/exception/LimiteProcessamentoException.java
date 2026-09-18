package com.folhio.api.handler.processing.exception;

import com.folhio.api.handler.NegocioException;

public class LimiteProcessamentoException extends NegocioException {
    public LimiteProcessamentoException() { super("O arquivo excede os limites desta operacao."); }
    public LimiteProcessamentoException(String mensagem) { super(mensagem); }
    public LimiteProcessamentoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
