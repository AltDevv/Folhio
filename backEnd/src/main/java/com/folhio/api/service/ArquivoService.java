package com.folhio.api.service;

import com.folhio.api.dto.file.ArquivoResponse;
import com.folhio.api.files.model.ArquivoArmazenado;
import com.folhio.api.files.policy.NomeArquivoPolicy;
import com.folhio.api.files.storage.ArmazenamentoArquivoService;
import com.folhio.api.files.upload.EnvioArquivoService;
import com.folhio.api.mapper.ArquivoMapper;
import com.folhio.api.processing.conversion.PreviaPdfService;
import com.folhio.api.progress.ProgressoRegistry;
import com.folhio.api.progress.ProgressoTracker;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.io.OutputStream;
import java.util.UUID;

@Service
public class ArquivoService {
    private final ArquivoArmazenadoService files;
    private final EnvioArquivoService uploads;
    private final ArmazenamentoArquivoService storage;
    private final PreviaPdfService pdf;
    private final ArquivoMapper mapper;
    private final ProgressoRegistry progress;
    private final com.folhio.api.audit.AuditoriaService audit;

    public ArquivoService(ArquivoArmazenadoService files, EnvioArquivoService uploads, ArmazenamentoArquivoService storage,
                       PreviaPdfService pdf, ArquivoMapper mapper, ProgressoRegistry progress,
                       com.folhio.api.audit.AuditoriaService audit) {
        this.files = files;
        this.uploads = uploads;
        this.storage = storage;
        this.pdf = pdf;
        this.mapper = mapper;
        this.progress = progress;
        this.audit = audit;
    }

    public ArquivoResponse enviarArquivo(MultipartFile input, String owner, String user, boolean persistent, String requestId) {
        String id = requestId == null || requestId.isBlank() ? "upload-" + UUID.randomUUID() : requestId;
        progress.iniciar(id, "Arquivo recebido");
        try {
            ArquivoArmazenado file = ProgressoTracker.comOuvinte(
                    (value, message) -> progress.atualizar(id, value, message),
                    () -> uploads.salvarEnvio(input, owner, user, persistent));
            ArquivoResponse response = resposta(file, id);
            progress.concluir(id, "Arquivo enviado");
            return response;
        } catch (RuntimeException error) {
            progress.concluir(id, "Nao foi possivel enviar o arquivo");
            throw error;
        }
    }

    public ArquivoArmazenado buscar(String id, String owner, String user) {
        return files.comProprietario(owner, user, () -> files.buscar(id));
    }

    public ArquivoResponse metadados(String id, String owner, String user) {
        return resposta(buscar(id, owner, user), null);
    }

    public byte[] visualizarPrevia(String id, String owner, String user, int page) {
        ArquivoArmazenado file = buscar(id, owner, user);
        if (!"pdf".equals(NomeArquivoPolicy.extensaoDe(file.originalFileName()))) {
            throw new com.folhio.api.handler.file.exception.FormatoArquivoNaoSuportadoException("A previa exige um PDF.");
        }
        return pdf.visualizarPrevia(file.path(), page);
    }

    public void baixar(ArquivoArmazenado file, OutputStream output) throws IOException {
        audit.registrar(com.folhio.api.enums.AcaoAuditoria.DOWNLOAD, file.ownerClientId(), file.id());
        try (var input = storage.abrir(file.path())) {
            input.transferTo(output);
        }
    }

    private ArquivoResponse resposta(ArquivoArmazenado file, String requestId) {
        var info = "pdf".equals(NomeArquivoPolicy.extensaoDe(file.originalFileName()))
                ? pdf.inspecionar(file.path()) : null;
        return mapper.paraResposta(file, info, requestId);
    }
}
