package com.folhio.api.handler.integration.exception;

import com.folhio.api.handler.NegocioException;

public class VerificacaoArquivoIndisponivelException extends NegocioException {
    public VerificacaoArquivoIndisponivelException() { super("A verificacao de seguranca esta indisponivel no momento."); }
    public VerificacaoArquivoIndisponivelException(String mensagem) { super(mensagem); }
    public VerificacaoArquivoIndisponivelException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
