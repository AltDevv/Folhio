package com.folhio.api.handler.processing.handler;

import com.folhio.api.handler.processing.exception.OperacaoNaoSuportadaException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class OperacaoNaoSuportadaHandler {
    @ExceptionHandler(OperacaoNaoSuportadaException.class)
    public ResponseEntity<RespostaErro> tratarOperacaoNaoSuportada(OperacaoNaoSuportadaException erro, HttpServletRequest request) {
        return RespostaErro.responder(422, "OPERACAO_NAO_SUPORTADA", erro.getMessage(), request);
    }
}
