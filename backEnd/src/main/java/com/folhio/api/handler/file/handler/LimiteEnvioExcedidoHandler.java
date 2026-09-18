package com.folhio.api.handler.file.handler;

import com.folhio.api.handler.file.exception.LimiteEnvioExcedidoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class LimiteEnvioExcedidoHandler {
    @ExceptionHandler(LimiteEnvioExcedidoException.class)
    public ResponseEntity<RespostaErro> tratarLimiteEnvio(LimiteEnvioExcedidoException erro, HttpServletRequest request) {
        return RespostaErro.responder(413, "LIMITE_ENVIO_EXCEDIDO", erro.getMessage(), request);
    }
}
