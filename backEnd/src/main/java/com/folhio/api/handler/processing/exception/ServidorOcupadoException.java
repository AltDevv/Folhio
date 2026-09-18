package com.folhio.api.handler.processing.exception;

import com.folhio.api.handler.NegocioException;

public class ServidorOcupadoException extends NegocioException {
    public ServidorOcupadoException() { super("O servidor esta ocupado. Aguarde e tente novamente."); }
    public ServidorOcupadoException(String mensagem) { super(mensagem); }
    public ServidorOcupadoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
