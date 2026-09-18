package com.folhio.api.handler.file.handler;

import com.folhio.api.handler.file.exception.ArquivoNaoEncontradoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class ArquivoNaoEncontradoHandler {
    @ExceptionHandler(ArquivoNaoEncontradoException.class)
    public ResponseEntity<RespostaErro> tratarArquivoNaoEncontrado(ArquivoNaoEncontradoException erro, HttpServletRequest request) {
        return RespostaErro.responder(404, "ARQUIVO_NAO_ENCONTRADO", erro.getMessage(), request);
    }
}
