package com.folhio.api.handler.integration.handler;

import com.folhio.api.handler.integration.exception.VerificacaoArquivoIndisponivelException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class VerificacaoArquivoIndisponivelHandler {
    @ExceptionHandler(VerificacaoArquivoIndisponivelException.class)
    public ResponseEntity<RespostaErro> tratarVerificacaoArquivoIndisponivel(VerificacaoArquivoIndisponivelException erro, HttpServletRequest request) {
        return RespostaErro.responder(503, "VERIFICACAO_ARQUIVO_INDISPONIVEL", "A verificacao de seguranca esta indisponivel no momento.", request);
    }
}
