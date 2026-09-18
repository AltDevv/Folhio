package com.folhio.api.handler.file.exception;

import com.folhio.api.handler.NegocioException;

public class FormatoArquivoNaoSuportadoException extends NegocioException {
    public FormatoArquivoNaoSuportadoException() { super("Esse formato de arquivo nao e aceito."); }
    public FormatoArquivoNaoSuportadoException(String mensagem) { super(mensagem); }
    public FormatoArquivoNaoSuportadoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
