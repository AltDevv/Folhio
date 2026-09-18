package com.folhio.api.handler.file.handler;

import com.folhio.api.handler.file.exception.ArquivoInvalidoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class ArquivoInvalidoHandler {
    @ExceptionHandler(ArquivoInvalidoException.class)
    public ResponseEntity<RespostaErro> tratarArquivoInvalido(ArquivoInvalidoException erro, HttpServletRequest request) {
        return RespostaErro.responder(422, "ARQUIVO_INVALIDO", erro.getMessage(), request);
    }
}
