package com.folhio.api.handler.auth.handler;

import com.folhio.api.handler.auth.exception.SessaoInvalidaException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class SessaoInvalidaHandler {
    @ExceptionHandler(SessaoInvalidaException.class)
    public ResponseEntity<RespostaErro> tratarSessaoInvalida(SessaoInvalidaException erro, HttpServletRequest request) {
        return RespostaErro.responder(401, "SESSAO_INVALIDA", erro.getMessage(), request);
    }
}
