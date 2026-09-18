package com.folhio.api.handler.auth.handler;

import com.folhio.api.handler.auth.exception.SessaoObrigatoriaException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class SessaoObrigatoriaHandler {
    @ExceptionHandler(SessaoObrigatoriaException.class)
    public ResponseEntity<RespostaErro> tratarSessaoObrigatoria(SessaoObrigatoriaException erro, HttpServletRequest request) {
        return RespostaErro.responder(401, "SESSAO_OBRIGATORIA", erro.getMessage(), request);
    }
}
