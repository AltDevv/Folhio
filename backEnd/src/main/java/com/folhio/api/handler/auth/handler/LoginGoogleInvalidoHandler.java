package com.folhio.api.handler.auth.handler;

import com.folhio.api.handler.auth.exception.LoginGoogleInvalidoException;
import com.folhio.api.handler.RespostaErro;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Order(0)
@RestControllerAdvice
public class LoginGoogleInvalidoHandler {
    @ExceptionHandler(LoginGoogleInvalidoException.class)
    public ResponseEntity<RespostaErro> tratarLoginGoogleInvalido(LoginGoogleInvalidoException erro, HttpServletRequest request) {
        return RespostaErro.responder(401, "LOGIN_GOOGLE_INVALIDO", erro.getMessage(), request);
    }
}
