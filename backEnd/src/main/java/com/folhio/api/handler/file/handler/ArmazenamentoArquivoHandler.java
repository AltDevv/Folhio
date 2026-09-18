package com.folhio.api.handler.file.handler;

import com.folhio.api.handler.file.exception.ArmazenamentoArquivoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class ArmazenamentoArquivoHandler {
    @ExceptionHandler(ArmazenamentoArquivoException.class)
    public ResponseEntity<RespostaErro> tratarArmazenamentoArquivo(ArmazenamentoArquivoException erro, HttpServletRequest request) {
        return RespostaErro.responder(500, "FALHA_ARMAZENAMENTO", "Nao foi possivel salvar ou ler o arquivo. Tente novamente.", request);
    }
}
