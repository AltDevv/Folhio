package com.folhio.api.logs;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class ReparoEsquemaRegistro implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(ReparoEsquemaRegistro.class);

    private final JdbcTemplate jdbcTemplate;

    public ReparoEsquemaRegistro(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(ApplicationArguments args) {
        Map<String, String> colunasTexto = new LinkedHashMap<>();
        colunasTexto.put("nivel", "text");
        colunasTexto.put("origem", "text");
        colunasTexto.put("categoria", "text");
        colunasTexto.put("evento", "text");
        colunasTexto.put("mensagem", "text");
        colunasTexto.put("request_id", "text");
        colunasTexto.put("metodo", "text");
        colunasTexto.put("caminho", "text");
        colunasTexto.put("ip", "text");
        colunasTexto.put("user_agent", "text");
        colunasTexto.put("detalhes", "text");

        for (Map.Entry<String, String> coluna : colunasTexto.entrySet()) {
            ajustarColunaTexto(coluna.getKey(), coluna.getValue());
        }
    }

    private void ajustarColunaTexto(String coluna, String tipoDestino) {
        try {
            String tipo = jdbcTemplate.queryForObject("""
                    select data_type
                    from information_schema.columns
                    where table_schema = 'public'
                      and table_name = 'app_logs'
                      and column_name = ?
                    """, String.class, coluna);

            if (tipo == null || tipoEhTexto(tipo)) {
                return;
            }

            String conversao = "bytea".equalsIgnoreCase(tipo)
                    ? "encode(" + coluna + ", 'escape')"
                    : coluna + "::text";

            jdbcTemplate.execute("""
                        alter table app_logs
                        alter column %s type %s
                        using %s
                        """.formatted(coluna, tipoDestino, conversao));
        } catch (EmptyResultDataAccessException ignored) {
            // A tabela ainda nao existe; o Hibernate cria na primeira inicializacao.
        } catch (Exception error) {
            logger.warn("Nao foi possivel verificar ou ajustar a coluna app_logs.{}.", coluna, error);
        }
    }

    private boolean tipoEhTexto(String tipo) {
        return "character varying".equalsIgnoreCase(tipo)
                || "text".equalsIgnoreCase(tipo);
    }
}
