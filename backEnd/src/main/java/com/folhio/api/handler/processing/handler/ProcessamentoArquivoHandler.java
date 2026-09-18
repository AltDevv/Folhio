package com.folhio.api.handler.processing.handler;

import com.folhio.api.handler.processing.exception.ProcessamentoArquivoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class ProcessamentoArquivoHandler {
    @ExceptionHandler(ProcessamentoArquivoException.class)
    public ResponseEntity<RespostaErro> tratarProcessamentoArquivo(ProcessamentoArquivoException erro, HttpServletRequest request) {
        return RespostaErro.responder(500, "FALHA_PROCESSAMENTO", "Nao foi possivel processar o arquivo. Tente novamente.", request);
    }
}
