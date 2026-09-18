package com.folhio.api.handler.processing.exception;

import com.folhio.api.handler.NegocioException;

public class ProcessamentoArquivoException extends NegocioException {
    public ProcessamentoArquivoException() { super("Nao foi possivel processar o arquivo. Tente novamente."); }
    public ProcessamentoArquivoException(String mensagem) { super(mensagem); }
    public ProcessamentoArquivoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
