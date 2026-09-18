package com.folhio.api.handler.auth.handler;

import com.folhio.api.handler.auth.exception.SenhaAtualInvalidaException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class SenhaAtualInvalidaHandler {
    @ExceptionHandler(SenhaAtualInvalidaException.class)
    public ResponseEntity<RespostaErro> tratarSenhaAtualInvalida(SenhaAtualInvalidaException erro, HttpServletRequest request) {
        return RespostaErro.responder(403, "SENHA_ATUAL_INVALIDA", erro.getMessage(), request);
    }
}
