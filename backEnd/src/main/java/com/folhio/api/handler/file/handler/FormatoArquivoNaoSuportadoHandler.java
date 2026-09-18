package com.folhio.api.handler.file.handler;

import com.folhio.api.handler.file.exception.FormatoArquivoNaoSuportadoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class FormatoArquivoNaoSuportadoHandler {
    @ExceptionHandler(FormatoArquivoNaoSuportadoException.class)
    public ResponseEntity<RespostaErro> tratarFormatoArquivoNaoSuportado(FormatoArquivoNaoSuportadoException erro, HttpServletRequest request) {
        return RespostaErro.responder(415, "FORMATO_ARQUIVO_NAO_SUPORTADO", erro.getMessage(), request);
    }
}
