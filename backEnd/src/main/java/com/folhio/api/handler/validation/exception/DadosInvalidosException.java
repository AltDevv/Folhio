package com.folhio.api.handler.validation.exception;

import com.folhio.api.handler.NegocioException;

public class DadosInvalidosException extends NegocioException {
    public DadosInvalidosException() { super("Revise os dados informados."); }
    public DadosInvalidosException(String mensagem) { super(mensagem); }
    public DadosInvalidosException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
