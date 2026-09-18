package com.folhio.api.handler.file.exception;

import com.folhio.api.handler.NegocioException;

public class ArmazenamentoArquivoException extends NegocioException {
    public ArmazenamentoArquivoException() { super("Nao foi possivel salvar ou ler o arquivo. Tente novamente."); }
    public ArmazenamentoArquivoException(String mensagem) { super(mensagem); }
    public ArmazenamentoArquivoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
