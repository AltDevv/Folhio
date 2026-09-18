package com.folhio.api.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SerializacaoJacksonConfig {

    @Bean
    public ObjectMapper mapeadorObjetosFolhio() {
        return new ObjectMapper().findAndRegisterModules();
    }
}
