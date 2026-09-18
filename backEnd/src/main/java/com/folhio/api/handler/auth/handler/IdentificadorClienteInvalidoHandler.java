package com.folhio.api.handler.auth.handler;

import com.folhio.api.handler.auth.exception.IdentificadorClienteInvalidoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class IdentificadorClienteInvalidoHandler {
    @ExceptionHandler(IdentificadorClienteInvalidoException.class)
    public ResponseEntity<RespostaErro> tratarIdentificadorClienteInvalido(IdentificadorClienteInvalidoException erro, HttpServletRequest request) {
        return RespostaErro.responder(400, "IDENTIFICADOR_CLIENTE_INVALIDO", erro.getMessage(), request);
    }
}
