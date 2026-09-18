package com.folhio.api.security.twofactor;

import com.folhio.api.entity.Usuario;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

@Component
public class DoisFatoresEmailSender {
    private final JavaMailSender mailSender;
    private final boolean enabled;
    private final String from;

    public DoisFatoresEmailSender(
            ObjectProvider<JavaMailSender> mailSender,
            @Value("${folhio.mail.enabled:false}") boolean enabled,
            @Value("${folhio.mail.from:no-reply@folhio.app}") String from
    ) {
        this.mailSender = mailSender.getIfAvailable();
        this.enabled = enabled;
        this.from = from;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("available")
    public boolean estaDisponivel() {
        return enabled && mailSender != null;
    }

    public void enviar(Usuario user, String code, String purpose) {
        if (!estaDisponivel()) {
            throw new com.folhio.api.handler.integration.exception.ServicoEmailIndisponivelException("Envio de email de seguranca nao configurado no servidor.");
        }
        ConteudoEmail copy = conteudoPara(purpose);
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(user.obterEmail());
        message.setSubject(copy.subject());
        message.setText("""
                Olá, %s!

                %s

                Para confirmar com segurança, use o código abaixo:

                %s

                Esse código é válido por alguns minutos e deve ser usado apenas no app Folhio.

                %s

                Com carinho,
                Equipe Folhio
                """.formatted(user.obterNomeExibicao(), copy.message(), code, copy.warning()));
        mailSender.send(message);
    }

    private ConteudoEmail conteudoPara(String purpose) {
        return switch (purpose == null ? "login" : purpose) {
            case "disable_2fa" -> new ConteudoEmail(
                    "Confirme a desativação da verificação em 2 etapas",
                    "Recebemos uma solicitação para desativar a verificação em 2 etapas da sua conta do Folhio.",
                    "Se você não pediu para desativar essa proteção, não informe este código a ninguém e mantenha a verificação em 2 etapas ativa."
            );
            case "change_password" -> new ConteudoEmail(
                    "Confirme a troca de senha do Folhio",
                    "Recebemos uma solicitação para trocar a senha da sua conta do Folhio.",
                    "Se você não pediu para trocar sua senha, ignore este email e revise a segurança da sua conta."
            );
            case "change_email" -> new ConteudoEmail(
                    "Confirme a troca de email do Folhio",
                    "Recebemos uma solicitação para trocar o email usado na sua conta do Folhio.",
                    "Se você não pediu para trocar seu email, ignore este email e troque sua senha para proteger a conta."
            );
            case "delete_account" -> new ConteudoEmail(
                    "Confirme a exclusão da sua conta Folhio",
                    "Recebemos uma solicitação para apagar sua conta do Folhio e remover seus dados da nuvem.",
                    "Se você não pediu para apagar sua conta, não informe este código a ninguém e troque sua senha imediatamente."
            );
            default -> new ConteudoEmail(
                    "Seu código de segurança do Folhio",
                    "Recebemos uma tentativa de entrada na sua conta do Folhio.",
                    "Se você não tentou entrar agora, ignore este email e troque sua senha para proteger a conta."
            );
        };
    }

    private record ConteudoEmail(String subject, String message, String warning) {
    }
}
