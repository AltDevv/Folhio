package com.folhio.api.handler.auth.handler;

import com.folhio.api.handler.auth.exception.CredenciaisInvalidasException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class CredenciaisInvalidasHandler {
    @ExceptionHandler(CredenciaisInvalidasException.class)
    public ResponseEntity<RespostaErro> tratarCredenciaisInvalidas(CredenciaisInvalidasException erro, HttpServletRequest request) {
        return RespostaErro.responder(401, "CREDENCIAIS_INVALIDAS", erro.getMessage(), request);
    }
}
