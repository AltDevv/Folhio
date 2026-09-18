package com.folhio.api.handler.integration.handler;

import com.folhio.api.handler.integration.exception.ServicoEmailIndisponivelException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class ServicoEmailIndisponivelHandler {
    @ExceptionHandler(ServicoEmailIndisponivelException.class)
    public ResponseEntity<RespostaErro> tratarServicoEmailIndisponivel(ServicoEmailIndisponivelException erro, HttpServletRequest request) {
        return RespostaErro.responder(503, "EMAIL_INDISPONIVEL", "O envio de email esta indisponivel no momento. Tente novamente mais tarde.", request);
    }
}
