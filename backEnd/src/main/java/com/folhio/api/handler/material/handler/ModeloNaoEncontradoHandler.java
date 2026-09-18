package com.folhio.api.handler.material.handler;

import com.folhio.api.handler.material.exception.ModeloNaoEncontradoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class ModeloNaoEncontradoHandler {
    @ExceptionHandler(ModeloNaoEncontradoException.class)
    public ResponseEntity<RespostaErro> tratarModeloNaoEncontrado(ModeloNaoEncontradoException erro, HttpServletRequest request) {
        return RespostaErro.responder(404, "MODELO_NAO_ENCONTRADO", erro.getMessage(), request);
    }
}
