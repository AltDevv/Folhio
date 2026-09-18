package com.folhio.api.handler.processing.handler;

import com.folhio.api.handler.processing.exception.LimiteProcessamentoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class LimiteProcessamentoHandler {
    @ExceptionHandler(LimiteProcessamentoException.class)
    public ResponseEntity<RespostaErro> tratarLimiteProcessamento(LimiteProcessamentoException erro, HttpServletRequest request) {
        return RespostaErro.responder(422, "LIMITE_PROCESSAMENTO", erro.getMessage(), request);
    }
}
