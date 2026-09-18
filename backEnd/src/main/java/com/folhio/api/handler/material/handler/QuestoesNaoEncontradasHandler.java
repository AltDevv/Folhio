package com.folhio.api.handler.material.handler;

import com.folhio.api.handler.material.exception.QuestoesNaoEncontradasException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class QuestoesNaoEncontradasHandler {
    @ExceptionHandler(QuestoesNaoEncontradasException.class)
    public ResponseEntity<RespostaErro> tratarQuestoesNaoEncontradas(QuestoesNaoEncontradasException erro, HttpServletRequest request) {
        return RespostaErro.responder(422, "QUESTOES_NAO_ENCONTRADAS", erro.getMessage(), request);
    }
}
