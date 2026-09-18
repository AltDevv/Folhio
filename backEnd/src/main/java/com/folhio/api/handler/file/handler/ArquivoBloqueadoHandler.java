package com.folhio.api.handler.file.handler;

import com.folhio.api.handler.file.exception.ArquivoBloqueadoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class ArquivoBloqueadoHandler {
    @ExceptionHandler(ArquivoBloqueadoException.class)
    public ResponseEntity<RespostaErro> tratarArquivoBloqueado(ArquivoBloqueadoException erro, HttpServletRequest request) {
        return RespostaErro.responder(422, "ARQUIVO_BLOQUEADO", erro.getMessage(), request);
    }
}
