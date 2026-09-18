package com.folhio.api.handler.auth.handler;

import com.folhio.api.handler.auth.exception.RecuperacaoSenhaInvalidaException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class RecuperacaoSenhaInvalidaHandler {
    @ExceptionHandler(RecuperacaoSenhaInvalidaException.class)
    public ResponseEntity<RespostaErro> tratarRecuperacaoSenhaInvalida(RecuperacaoSenhaInvalidaException erro, HttpServletRequest request) {
        return RespostaErro.responder(400, "RECUPERACAO_SENHA_INVALIDA", erro.getMessage(), request);
    }
}
