package com.folhio.api.handler.auth.handler;

import com.folhio.api.handler.auth.exception.CodigoSegurancaInvalidoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class CodigoSegurancaInvalidoHandler {
    @ExceptionHandler(CodigoSegurancaInvalidoException.class)
    public ResponseEntity<RespostaErro> tratarCodigoSegurancaInvalido(CodigoSegurancaInvalidoException erro, HttpServletRequest request) {
        return RespostaErro.responder(400, "CODIGO_SEGURANCA_INVALIDO", erro.getMessage(), request);
    }
}
