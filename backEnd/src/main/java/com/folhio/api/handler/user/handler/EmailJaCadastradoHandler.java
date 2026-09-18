package com.folhio.api.handler.user.handler;

import com.folhio.api.handler.user.exception.EmailJaCadastradoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class EmailJaCadastradoHandler {
    @ExceptionHandler(EmailJaCadastradoException.class)
    public ResponseEntity<RespostaErro> tratarEmailJaCadastrado(EmailJaCadastradoException erro, HttpServletRequest request) {
        return RespostaErro.responder(409, "EMAIL_JA_CADASTRADO", erro.getMessage(), request);
    }
}
