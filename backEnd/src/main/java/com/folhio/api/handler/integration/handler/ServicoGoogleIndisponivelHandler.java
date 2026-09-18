package com.folhio.api.handler.integration.handler;

import com.folhio.api.handler.integration.exception.ServicoGoogleIndisponivelException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class ServicoGoogleIndisponivelHandler {
    @ExceptionHandler(ServicoGoogleIndisponivelException.class)
    public ResponseEntity<RespostaErro> tratarServicoGoogleIndisponivel(ServicoGoogleIndisponivelException erro, HttpServletRequest request) {
        return RespostaErro.responder(503, "GOOGLE_INDISPONIVEL", "Login com Google indisponivel no momento.", request);
    }
}
