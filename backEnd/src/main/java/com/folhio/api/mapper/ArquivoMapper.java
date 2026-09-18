package com.folhio.api.mapper;

import com.folhio.api.dto.file.ArquivoResponse;
import com.folhio.api.files.model.ArquivoArmazenado;
import com.folhio.api.processing.conversion.PreviaPdfService.InformacoesPdf;
import org.springframework.stereotype.Component;

@Component
public class ArquivoMapper {
    public ArquivoResponse paraResposta(ArquivoArmazenado file, InformacoesPdf pdf, String requestId) {
        return new ArquivoResponse(true, file.id(), file.originalFileName(), file.contentType(),
                file.sizeBytes(), "/api/folhio/files/" + file.id() + "/download",
                pdf == null ? null : pdf.pages(), pdf == null ? null : pdf.width(),
                pdf == null ? null : pdf.height(), requestId);
    }
}
