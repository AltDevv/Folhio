package com.folhio.api.handler.user.handler;

import com.folhio.api.handler.user.exception.ContaAmbiguaException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class ContaAmbiguaHandler {
    @ExceptionHandler(ContaAmbiguaException.class)
    public ResponseEntity<RespostaErro> tratarContaAmbigua(ContaAmbiguaException erro, HttpServletRequest request) {
        return RespostaErro.responder(409, "CONTA_AMBIGUA", erro.getMessage(), request);
    }
}
