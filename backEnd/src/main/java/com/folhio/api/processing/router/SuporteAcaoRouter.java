package com.folhio.api.processing.router;

import com.folhio.api.dto.action.AcaoResponse;
import com.folhio.api.common.util.MapasJson;
import com.folhio.api.files.model.ArquivoArmazenado;

import java.util.Map;

final class SuporteAcaoRouter {

    private SuporteAcaoRouter() {
    }

    static String identificadorArquivoObrigatorio(Map<String, Object> payload, String key) {
        String id = MapasJson.texto(MapasJson.filho(payload, key), "id", "");
        if (id.isBlank()) {
            throw new com.folhio.api.handler.validation.exception.DadosInvalidosException("Informe payload." + key + ".id com o fileId retornado pelo upload.");
        }
        return id;
    }

    static Map<String, Object> dadosArquivo(ArquivoArmazenado file) {
        return Map.of(
                "id", file.id(),
                "name", file.originalFileName(),
                "mimeType", file.contentType(),
                "sizeBytes", file.sizeBytes()
        );
    }

    static AcaoResponse.ArquivoSaida arquivoSaida(ArquivoArmazenado file) {
        String downloadUrl = "/api/folhio/files/" + file.id() + "/download";
        return new AcaoResponse.ArquivoSaida(
                file.originalFileName(),
                file.contentType(),
                file.sizeBytes(),
                downloadUrl,
                file.id()
        );
    }
}
