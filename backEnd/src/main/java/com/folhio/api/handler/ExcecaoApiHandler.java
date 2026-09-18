package com.folhio.api.handler;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartException;
import org.springframework.web.ErrorResponse;
import org.springframework.mail.MailException;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.dao.DataIntegrityViolationException;
import java.util.LinkedHashMap;
import java.util.Map;

@Order(Ordered.LOWEST_PRECEDENCE)
@RestControllerAdvice
public class ExcecaoApiHandler {
    @ExceptionHandler(org.springframework.dao.OptimisticLockingFailureException.class)
    public ResponseEntity<RespostaErro> tratarEdicaoConcorrente(Exception erro, HttpServletRequest request) {
        return RespostaErro.responder(409, "EDICAO_CONCORRENTE",
                "Este layout foi alterado em outra sessao. Recarregue antes de salvar.", request);
    }
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<RespostaErro> tratarLimiteEnvio(Exception erro, HttpServletRequest request) {
        return RespostaErro.responder(413, "LIMITE_ENVIO_EXCEDIDO", "O arquivo excede o limite permitido de envio.", request);
    }

    @ExceptionHandler(MultipartException.class)
    public ResponseEntity<RespostaErro> tratarEnvioInvalido(Exception erro, HttpServletRequest request) {
        return RespostaErro.responder(400, "ENVIO_INVALIDO", "Nao foi possivel receber o arquivo. Tente enviar novamente.", request);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<RespostaErro> tratarValidacao(MethodArgumentNotValidException erro, HttpServletRequest request) {
        Map<String, String> campos = new LinkedHashMap<>();
        erro.getBindingResult().getFieldErrors().forEach(campo ->
                campos.putIfAbsent(campo.getField(), campo.getDefaultMessage() == null ? "Valor invalido." : campo.getDefaultMessage()));
        RespostaErro resposta = RespostaErro.criar(400, "DADOS_INVALIDOS", "Revise os campos informados.", request, campos);
        return ResponseEntity.badRequest().header("X-Request-Id", resposta.requestId()).body(resposta);
    }

    @ExceptionHandler({HttpMessageNotReadableException.class, ConstraintViolationException.class})
    public ResponseEntity<RespostaErro> tratarRequisicaoInvalida(Exception erro, HttpServletRequest request) {
        return RespostaErro.responder(400, "REQUISICAO_INVALIDA", "A requisicao possui dados ausentes ou invalidos.", request);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<RespostaErro> tratarArgumentoInvalido(Exception erro, HttpServletRequest request) {
        return RespostaErro.responder(400, "DADOS_INVALIDOS", "Revise os dados informados.", request);
    }

    @ExceptionHandler(MailException.class)
    public ResponseEntity<RespostaErro> tratarEmail(Exception erro, HttpServletRequest request) {
        return RespostaErro.responder(503, "EMAIL_INDISPONIVEL", "Nao foi possivel enviar o email. Tente novamente mais tarde.", request);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<RespostaErro> tratarConflito(Exception erro, HttpServletRequest request) {
        return RespostaErro.responder(409, "CONFLITO_DADOS", "Os dados entram em conflito com um registro existente.", request);
    }

    @ExceptionHandler(DataAccessResourceFailureException.class)
    public ResponseEntity<RespostaErro> tratarPersistenciaIndisponivel(Exception erro, HttpServletRequest request) {
        return RespostaErro.responder(503, "PERSISTENCIA_INDISPONIVEL", "O servico esta temporariamente indisponivel.", request);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<RespostaErro> tratarErroInesperado(Exception erro, HttpServletRequest request) {
        // Preserve HTTP errors raised by Spring, without exposing internal exception details.
        if (erro instanceof ErrorResponse resposta) {
            int status = resposta.getStatusCode().value();
            String mensagem = switch (status) {
                case 404 -> "Recurso nao encontrado.";
                case 405 -> "Metodo nao permitido para esta operacao.";
                case 415 -> "Formato da requisicao nao suportado.";
                default -> "Nao foi possivel atender a requisicao.";
            };
            return RespostaErro.responder(status, "HTTP_" + status, mensagem, request);
        }
        ResponseEntity<RespostaErro> resposta = RespostaErro.responder(500, "ERRO_INTERNO",
                "Ocorreu uma falha interna. Tente novamente mais tarde.", request);
        org.slf4j.LoggerFactory.getLogger(getClass()).error("Erro interno requestId={}", resposta.getBody().requestId(), erro);
        return resposta;
    }
}
