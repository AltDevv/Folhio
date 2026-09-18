package com.folhio.api.handler.file.exception;

import com.folhio.api.handler.NegocioException;

public class ArquivoBloqueadoException extends NegocioException {
    public ArquivoBloqueadoException() { super("Arquivo bloqueado pela verificacao de seguranca."); }
    public ArquivoBloqueadoException(String mensagem) { super(mensagem); }
    public ArquivoBloqueadoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
