package com.folhio.api.handler.auth.handler;

import com.folhio.api.handler.auth.exception.ContaDesativadaException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class ContaDesativadaHandler {
    @ExceptionHandler(ContaDesativadaException.class)
    public ResponseEntity<RespostaErro> tratarContaDesativada(ContaDesativadaException erro, HttpServletRequest request) {
        return RespostaErro.responder(403, "CONTA_DESATIVADA", erro.getMessage(), request);
    }
}
