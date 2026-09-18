package com.folhio.api.handler.processing.handler;

import com.folhio.api.handler.processing.exception.ServidorOcupadoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class ServidorOcupadoHandler {
    @ExceptionHandler(ServidorOcupadoException.class)
    public ResponseEntity<RespostaErro> tratarServidorOcupado(ServidorOcupadoException erro, HttpServletRequest request) {
        return RespostaErro.responder(503, "SERVIDOR_OCUPADO", "O servidor esta ocupado. Aguarde e tente novamente.", request);
    }
}
