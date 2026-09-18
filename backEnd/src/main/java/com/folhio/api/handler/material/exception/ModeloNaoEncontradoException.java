package com.folhio.api.handler.material.exception;

import com.folhio.api.handler.NegocioException;

public class ModeloNaoEncontradoException extends NegocioException {
    public ModeloNaoEncontradoException() { super("Modelo de material nao encontrado."); }
    public ModeloNaoEncontradoException(String mensagem) { super(mensagem); }
    public ModeloNaoEncontradoException(String mensagem, Throwable causa) { super(mensagem, causa); }
}
