package com.folhio.api.handler.validation.handler;

import com.folhio.api.handler.validation.exception.DadosInvalidosException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class DadosInvalidosHandler {
    @ExceptionHandler(DadosInvalidosException.class)
    public ResponseEntity<RespostaErro> tratarDadosInvalidos(DadosInvalidosException erro, HttpServletRequest request) {
        return RespostaErro.responder(400, "DADOS_INVALIDOS", erro.getMessage(), request);
    }
}
