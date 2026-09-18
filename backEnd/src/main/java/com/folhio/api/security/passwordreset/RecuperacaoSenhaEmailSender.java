package com.folhio.api.security.passwordreset;

import com.folhio.api.entity.Usuario;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

@Component
public class RecuperacaoSenhaEmailSender {
    private final JavaMailSender mailSender;
    private final boolean enabled;
    private final String from;
    private final String resetUrlTemplate;

    public RecuperacaoSenhaEmailSender(
            ObjectProvider<JavaMailSender> mailSender,
            @Value("${folhio.mail.enabled:false}") boolean enabled,
            @Value("${folhio.mail.from:no-reply@folhio.app}") String from,
            @Value("${folhio.auth.reset-url-template:folhio://reset-password?token={token}}") String resetUrlTemplate
    ) {
        this.mailSender = mailSender.getIfAvailable();
        this.enabled = enabled;
        this.from = from;
        this.resetUrlTemplate = resetUrlTemplate;
    }

    public void enviar(Usuario user, String rawToken) {
        exigirDisponibilidade();
        String link = resetUrlTemplate.replace("{token}", rawToken);
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(user.obterEmail());
        message.setSubject("Recuperacao de senha do Folhio");
        message.setText("""
                Ola,

                Recebemos um pedido para recuperar sua senha no Folhio.
                Abra o link abaixo para criar uma nova senha:

                %s

                Se voce nao pediu isso, ignore este email.
                """.formatted(link));
        mailSender.send(message);
    }

    public void exigirDisponibilidade() {
        if (!enabled || mailSender == null) {
            throw new com.folhio.api.handler.integration.exception.ServicoEmailIndisponivelException();
        }
    }
}
