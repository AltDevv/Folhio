package com.folhio.api.security.config;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class SegurancaProducaoConfigValidator implements ApplicationRunner {

    private final Environment environment;

    public SegurancaProducaoConfigValidator(Environment environment) {
        this.environment = environment;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!configuracaoSeguraObrigatoria()) {
            return;
        }

        Map<String, String> problems = new LinkedHashMap<>();
        String origins = valor("folhio.websocket.allowed-origins");
        if (origins.isBlank() || Arrays.stream(origins.split(","))
                .anyMatch(origin -> !origin.trim().startsWith("https://") || origin.contains("*"))) {
            problems.put("FOLHIO_WEBSOCKET_ALLOWED_ORIGINS", "Defina as origens HTTPS explicitas do site.");
        }
        if (!Boolean.parseBoolean(valor("folhio.file-scanner.enabled"))
                || !Boolean.parseBoolean(valor("folhio.file-scanner.required"))) {
            problems.put("FOLHIO_FILE_SCANNER", "O antivirus deve estar ativo e obrigatorio em producao.");
        }
        exigirPresenca(problems, "folhio.security.app-api-key", "FOLHIO_APP_API_KEY");
        exigirPresenca(problems, "folhio.security.admin-api-key", "FOLHIO_APP_API_KEY");
        exigirPresenca(problems, "folhio.auth.access-token-secret", "FOLHIO_AUTH_ACCESS_TOKEN_SECRET");
        exigirPresenca(problems, "folhio.auth.password-pepper", "FOLHIO_AUTH_PASSWORD_PEPPER");
        exigirPresenca(problems, "folhio.auth.google-client-id", "FOLHIO_GOOGLE_CLIENT_ID");
        if (valor("folhio.auth.access-token-secret").length() < 32) {
            problems.put("FOLHIO_AUTH_ACCESS_TOKEN_SECRET", "Use um segredo aleatorio com pelo menos 32 bytes.");
        }
        if (valor("folhio.auth.password-pepper").length() < 24) {
            problems.put("FOLHIO_AUTH_PASSWORD_PEPPER", "Use um pepper aleatorio com pelo menos 24 bytes.");
        }
        if (Boolean.parseBoolean(valor("folhio.mail.enabled"))) {
            exigirPresenca(problems, "spring.mail.host", "FOLHIO_SMTP_HOST");
            exigirPresenca(problems, "spring.mail.username", "FOLHIO_SMTP_USERNAME");
            exigirPresenca(problems, "spring.mail.password", "FOLHIO_SMTP_PASSWORD");
            exigirPresenca(problems, "folhio.mail.from", "FOLHIO_MAIL_FROM");
        }

        String datasourcePassword = valor("spring.datasource.password");
        if (datasourcePassword.isBlank() || "postgres".equals(datasourcePassword)) {
            problems.put("POSTGRES_PASSWORD", "Use uma senha real do banco em producao.");
        }

        String ddlAuto = valor("spring.jpa.hibernate.ddl-auto");
        if (ddlAuto.equals("update") || ddlAuto.equals("create") || ddlAuto.equals("create-drop")) {
            problems.put("FOLHIO_DDL_AUTO", "Nao use ddl-auto=" + ddlAuto + " em producao; prefira validate e migrations.");
        }

        if (Boolean.parseBoolean(valor("spring.jpa.show-sql"))) {
            problems.put("FOLHIO_SHOW_SQL", "SQL detalhado deve ficar desligado em producao.");
        }

        if (Boolean.parseBoolean(valor("folhio.logs.detailed-errors"))) {
            problems.put("FOLHIO_LOGS_DETAILED_ERRORS", "Stack trace e erro bruto devem ficar desligados em producao.");
        }

        if (!problems.isEmpty()) {
            throw new IllegalStateException("Configuracao insegura para producao: " + problems);
        }
    }

    private boolean configuracaoSeguraObrigatoria() {
        boolean explicit = Boolean.parseBoolean(valor("folhio.security.require-secure-config"));
        boolean prodProfile = Arrays.stream(environment.getActiveProfiles()).anyMatch("prod"::equalsIgnoreCase);
        return explicit || prodProfile;
    }

    private void exigirPresenca(Map<String, String> problems, String property, String envName) {
        if (valor(property).isBlank()) {
            problems.put(envName, "Valor obrigatorio em producao.");
        }
    }

    private String valor(String property) {
        return environment.getProperty(property, "").trim();
    }
}
