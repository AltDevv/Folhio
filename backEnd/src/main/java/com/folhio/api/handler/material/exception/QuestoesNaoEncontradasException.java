package com.folhio.api.handler.material.exception;

import com.folhio.api.handler.NegocioException;

public class QuestoesNaoEncontradasException extends NegocioException {
    public QuestoesNaoEncontradasException() { super("Nenhuma questao encontrada para os filtros escolhidos."); }
    public QuestoesNaoEncontradasException(String mensagem) { super(mensagem); }
    public QuestoesNaoEncontradasException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
