package com.folhio.api.handler;

public abstract class NegocioException extends RuntimeException {
    protected NegocioException(String mensagem) { super(mensagem); }
    protected NegocioException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
