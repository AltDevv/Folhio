package com.folhio.api.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class LimpezaBancoLegadoRunner implements ApplicationRunner {
    private static final Logger logger = LoggerFactory.getLogger(LimpezaBancoLegadoRunner.class);

    private static final List<String> LEGACY_TABLES = List.of(
            "biblioteca_colecoes",
            "biblioteca_arquivos",
            "biblioteca_pastas",
            "recuperacao_senha",
            "sessoes_usuario"
    );

    private final JdbcTemplate jdbcTemplate;
    private final boolean enabled;

    public LimpezaBancoLegadoRunner(
            JdbcTemplate jdbcTemplate,
            @Value("${folhio.database.drop-legacy-tables:true}") boolean enabled
    ) {
        this.jdbcTemplate = jdbcTemplate;
        this.enabled = enabled;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!enabled) {
            return;
        }

        for (String table : LEGACY_TABLES) {
            removerTabelaLegada(table);
        }
    }

    private void removerTabelaLegada(String tableName) {
        try {
            if (!existe(tableName)) {
                return;
            }
            jdbcTemplate.execute("drop table if exists " + tableName + " cascade");
            logger.info("[Database] tabela legada removida: {}", tableName);
        } catch (Exception error) {
            logger.warn("[Database] nao foi possivel remover tabela legada {}.", tableName, error);
        }
    }

    private boolean existe(String tableName) {
        Boolean exists = jdbcTemplate.queryForObject(
                """
                select exists (
                    select 1
                    from information_schema.tables
                    where table_schema = 'public'
                      and table_name = ?
                )
                """,
                Boolean.class,
                tableName
        );
        return Boolean.TRUE.equals(exists);
    }
}
