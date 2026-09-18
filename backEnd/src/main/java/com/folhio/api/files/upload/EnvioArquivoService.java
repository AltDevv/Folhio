package com.folhio.api.files.upload;

import com.folhio.api.files.config.ArmazenamentoArquivoConfig;
import com.folhio.api.files.model.ArquivoArmazenado;
import com.folhio.api.files.policy.NomeArquivoPolicy;
import com.folhio.api.files.policy.ConteudoArquivoValidator;
import com.folhio.api.files.storage.CaminhosArmazenamentoArquivo;
import com.folhio.api.files.storage.ArmazenamentoArquivoService;
import com.folhio.api.security.antivirus.VerificacaoArquivoService;
import com.folhio.api.service.ArquivoArmazenadoService;
import com.folhio.api.progress.ProgressoTracker;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.nio.file.Path;
import java.util.UUID;

@Service
public class EnvioArquivoService {
    private final CaminhosArmazenamentoArquivo paths;
    private final ArmazenamentoArquivoService storage;
    private final ArquivoArmazenadoService files;
    private final VerificacaoArquivoService scanner;
    private final ArmazenamentoArquivoConfig config;
    private final ConteudoArquivoValidator validator;
    private final NomeArquivoPolicy names = new NomeArquivoPolicy();

    public EnvioArquivoService(CaminhosArmazenamentoArquivo paths, ArmazenamentoArquivoService storage, ArquivoArmazenadoService files,
                             VerificacaoArquivoService scanner, ArmazenamentoArquivoConfig config, ConteudoArquivoValidator validator) {
        this.paths = paths;
        this.storage = storage;
        this.files = files;
        this.scanner = scanner;
        this.config = config;
        this.validator = validator;
    }

    public ArquivoArmazenado salvarEnvio(MultipartFile file, String owner, String userId, boolean persistent) {
        if (owner == null || owner.isBlank()) throw new com.folhio.api.handler.auth.exception.IdentificadorClienteInvalidoException("Identificador ausente.");
        if (file == null) throw new com.folhio.api.handler.file.exception.ArquivoInvalidoException("Arquivo de upload vazio.");
        config.validarTamanho(file.getSize());
        String id = UUID.randomUUID().toString();
        Path temporary = paths.caminhoEnvioTemporario(id, "content");
        Path target = paths.caminhoArmazenamentoProprietario(owner, "uploads", id, "content");
        boolean registered = false;
        try {
            String name = names.prepararNomeEnvio(file);
            ProgressoTracker.atualizar(0.30, "Arquivo recebido");
            long size;
            try (var input = file.getInputStream()) {
                size = storage.salvar(input, temporary, config.limiteBytesEnvio());
            }
            config.validarTamanho(size);
            validator.validar(temporary, name, file.getContentType());
            ProgressoTracker.atualizar(0.42, "Verificando arquivo");
            scanner.verificarEnvio(temporary, name, size);
            ProgressoTracker.atualizar(0.72, "Salvando arquivo");
            storage.mover(temporary, target);
            ArquivoArmazenado result = files.registrarEnvio(id, name, names.normalizarTipoConteudo(file.getContentType()),
                    size, target, persistent, owner, userId);
            registered = true;
            return result;
        } catch (IOException error) {
            throw new com.folhio.api.handler.file.exception.ArmazenamentoArquivoException("Nao foi possivel salvar o upload.", error);
        } finally {
            storage.excluirSilenciosamente(temporary);
            if (!registered) storage.excluirSilenciosamente(target);
        }
    }
}
