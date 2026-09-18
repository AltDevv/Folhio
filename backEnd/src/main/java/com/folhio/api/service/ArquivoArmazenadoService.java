package com.folhio.api.service;
import java.util.Map;

import com.folhio.api.entity.ArquivoArmazenadoEntity;
import com.folhio.api.entity.ArquivoUsuario;
import com.folhio.api.files.model.ArquivoArmazenado;
import com.folhio.api.files.policy.NomeArquivoPolicy;
import com.folhio.api.files.storage.CaminhosArmazenamentoArquivo;
import com.folhio.api.repository.ArquivoArmazenadoRepository;
import com.folhio.api.repository.ArquivoUsuarioRepository;
import com.folhio.api.files.storage.ArmazenamentoArquivoService;

import com.folhio.api.audit.AuditoriaService;
import com.folhio.api.enums.AcaoAuditoria;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.function.Supplier;
import java.util.regex.Pattern;

@Service
public class ArquivoArmazenadoService {

    private static final Pattern STORAGE_ID_PATTERN = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
    );

    private final CaminhosArmazenamentoArquivo storagePaths;
    private final NomeArquivoPolicy fileNames = new NomeArquivoPolicy();
    private final ArquivoArmazenadoRepository storedFiles;
    private final ArquivoUsuarioRepository userFiles;
    private final ArmazenamentoArquivoService physicalStorage;
    private final AuditoriaService audit;
    private final ThreadLocal<String> currentOwnerClientId = new ThreadLocal<>();
    private final ThreadLocal<String> currentOwnerUserId = new ThreadLocal<>();

    public ArquivoArmazenadoService(
            CaminhosArmazenamentoArquivo storagePaths,
            ArquivoArmazenadoRepository storedFiles,
            ArquivoUsuarioRepository userFiles,
            ArmazenamentoArquivoService physicalStorage,
            AuditoriaService audit
    ) {
        this.storagePaths = storagePaths;
        this.storedFiles = storedFiles;
        this.userFiles = userFiles;
        this.physicalStorage = physicalStorage;
        this.audit = audit;
    }

    public <T> T comProprietario(String ownerClientId, Supplier<T> operation) {
        return comProprietario(ownerClientId, null, operation);
    }

    public <T> T comProprietario(String ownerClientId, String ownerUserId, Supplier<T> operation) {
        String owner = exigirProprietario(ownerClientId);
        String userId = normalizarIdentificadorUsuarioProprietario(ownerUserId);
        String previousOwner = currentOwnerClientId.get();
        String previousUser = currentOwnerUserId.get();
        currentOwnerClientId.set(owner);
        definirOuRemover(currentOwnerUserId, userId);
        try {
            return operation.get();
        } finally {
            definirOuRemover(currentOwnerClientId, previousOwner);
            definirOuRemover(currentOwnerUserId, previousUser);
        }
    }

    @Transactional
    public ArquivoArmazenado registrarEnvio(String id, String name, String contentType, long size,
                                     Path target, boolean persistent, String ownerClientId, String ownerUserId) {
        String owner = exigirProprietario(ownerClientId);
        ArquivoArmazenadoEntity entity = registrarArquivoArmazenado(id, name, contentType, size, "upload",
                target, persistent, owner, ownerUserId);
        return converterParaArquivoArmazenado(entity, owner);
    }

    @Transactional
    public ArquivoArmazenado salvarSaida(String suggestedName, String contentType, ArquivoWriter writer) {
        return salvarSaida(suggestedName, contentType, writer, false);
    }

    @Transactional
    public ArquivoArmazenado salvarSaida(String suggestedName, String contentType, ArquivoWriter writer, boolean persistent) {
        String ownerClientId = proprietarioAtualObrigatorio();
        String fileName = fileNames.prepararNomeSaida(suggestedName);
        String id = UUID.randomUUID().toString();
        Path target = storagePaths.caminhoArmazenamentoProprietario(ownerClientId, "outputs", id, fileName);

        try {
            physicalStorage.escrever(target, writer::escrever);
            if (TransactionSynchronizationManager.isSynchronizationActive()) {
                TransactionSynchronizationManager.registerSynchronization(
                        new TransactionSynchronization() {
                            @Override
                            public void afterCompletion(int status) {
                                if (status != STATUS_COMMITTED) physicalStorage.excluirSilenciosamente(target);
                            }
                        });
            }
            ArquivoArmazenadoEntity entity = registrarArquivoArmazenado(
                    id,
                    fileName,
                    fileNames.normalizarTipoConteudo(contentType),
                    physicalStorage.tamanho(target),
                    "output",
                    target,
                    persistent,
                    ownerClientId,
                    currentOwnerUserId.get()
            );
            return converterParaArquivoArmazenado(entity, ownerClientId);
        } catch (IOException error) {
            physicalStorage.excluirSilenciosamente(target);
            throw new com.folhio.api.handler.file.exception.ArmazenamentoArquivoException("Não foi possível salvar o arquivo gerado.", error);
        } catch (RuntimeException error) {
            physicalStorage.excluirSilenciosamente(target);
            throw error;
        }
    }

    public ArquivoArmazenado buscar(String id) {
        String validId = identificadorArmazenamentoValido(id);
        return storedFiles.findById(validId)
                .map(entity -> {
                    validarAcessoProprietarioAtual(entity);
                    return converterParaArquivoArmazenado(entity, proprietarioAtualObrigatorio());
                })
                .orElseThrow(() -> new com.folhio.api.handler.file.exception.ArquivoNaoEncontradoException("Arquivo não encontrado."));
    }

    public ArquivoArmazenado buscarParaAdministrador(String id) {
        String validId = identificadorArmazenamentoValido(id);
        return storedFiles.findById(validId)
                .map(entity -> converterParaArquivoArmazenado(entity, proprietarioDoArquivoUsuario(entity.obterId())))
                .orElseThrow(() -> new com.folhio.api.handler.file.exception.ArquivoNaoEncontradoException("Arquivo não encontrado."));
    }

    public List<ArquivoArmazenado> listarArquivosArmazenados(String ownerClientId, int limit) {
        int safeLimit = Math.max(1, Math.min(limit, 200));
        return comProprietario(ownerClientId, () -> {
            Pageable page = PageRequest.of(0, safeLimit);
            return userFiles.buscarPorClienteProprietarioOrdenadosPorCriacao(ownerClientId, page)
                    .stream()
                    .map(ArquivoUsuario::obterArquivoArmazenado)
                    .map(entity -> converterParaArquivoArmazenado(entity, ownerClientId))
                    .toList();
        });
    }

    public List<ArquivoArmazenado> listarTodosArquivosArmazenados(int limit) {
        int safeLimit = Math.max(1, Math.min(limit, 500));
        return storedFiles.buscarTodosPorAtualizacaoDecrescente(PageRequest.of(0, safeLimit))
                .stream()
                .map(entity -> new ArquivoArmazenado(entity.obterId(), entity.obterNomeOriginalArquivo(),
                        entity.obterTipoConteudo(), entity.obterTamanhoBytes(),
                        storagePaths.caminhoPara(entity.obterChaveArmazenamento()), proprietarioDoArquivoUsuario(entity.obterId())))
                .toList();
    }

    public Map<String, Object> resumoArmazenamento() {
        return Map.of("filesTotal", storedFiles.count(), "filesSizeBytes", storedFiles.somarTamanhoRegistrado());
    }

    public void excluirEnvioSilenciosamente(String id) {
        if (ehIdentificadorArmazenamento(id)) {
            excluirArquivoArmazenadoSilenciosamente(id);
        }
    }

    @Transactional
    public void excluirArquivoArmazenadoSilenciosamente(String id) {
        if (!ehIdentificadorArmazenamento(id)) {
            return;
        }
        String validId = identificadorArmazenamentoValido(id);
        storedFiles.findById(validId).ifPresent(entity -> {
            try {
                validarAcessoProprietarioAtual(entity);
                excluirDiretorioRecursivamenteSilenciosamente(storagePaths.caminhoPara(entity.obterChaveArmazenamento()).getParent());
                userFiles.excluirPorIdentificadorArquivo(validId);
                storedFiles.delete(entity);
            } catch (RuntimeException ignored) {
                // Best effort.
            }
        });
    }

    public void excluirArquivoArmazenadoSilenciosamente(String id, String ownerClientId) {
        comProprietario(ownerClientId, () -> {
            excluirArquivoArmazenadoSilenciosamente(id);
            return null;
        });
    }

    @Transactional
    public int limparArquivosTemporariosExpirados(Duration maxAge) {
        Instant threshold = Instant.now().minus(maxAge);
        int deleted = 0;
        for (ArquivoArmazenadoEntity entity : storedFiles.buscarTemporariosAtualizadosAntesDe(threshold)) {
            try {
                excluirDiretorioRecursivamenteSilenciosamente(storagePaths.caminhoPara(entity.obterChaveArmazenamento()).getParent());
                userFiles.excluirPorIdentificadorArquivo(entity.obterId());
                storedFiles.delete(entity);
                deleted++;
            } catch (RuntimeException ignored) {
                // Best effort.
            }
        }
        return deleted;
    }

    public static String extensaoDe(String fileName) {
        return NomeArquivoPolicy.extensaoDe(fileName);
    }

    public static String semExtensao(String fileName) {
        return NomeArquivoPolicy.semExtensao(fileName);
    }

    private ArquivoArmazenadoEntity registrarArquivoArmazenado(
            String id,
            String fileName,
            String contentType,
            long sizeBytes,
            String storageArea,
            Path target,
            boolean persistent,
            String ownerClientId,
            String ownerUserId
    ) {
        ArquivoArmazenadoEntity entity = new ArquivoArmazenadoEntity(
                id,
                fileName,
                contentType,
                sizeBytes,
                storageArea,
                storagePaths.chaveRelativaArmazenamento(target),
                persistent
        );
        ArquivoArmazenadoEntity saved = storedFiles.save(entity);
        if (!userFiles.existePorArquivoEClienteProprietario(saved.obterId(), ownerClientId)) {
            userFiles.save(new ArquivoUsuario(saved, ownerClientId, normalizarIdentificadorUsuarioProprietario(ownerUserId), "owner"));
        }
        audit.registrar("upload".equals(storageArea) ? AcaoAuditoria.UPLOAD
                : AcaoAuditoria.GENERATE_FILE,
                ownerUserId == null ? ownerClientId : ownerUserId, saved.obterId());
        return saved;
    }

    private ArquivoArmazenado converterParaArquivoArmazenado(ArquivoArmazenadoEntity entity, String ownerClientId) {
        Path path = storagePaths.caminhoPara(entity.obterChaveArmazenamento());
        if (!physicalStorage.existe(path)) {
            throw new com.folhio.api.handler.file.exception.ArquivoNaoEncontradoException("Arquivo não encontrado.");
        }
        try {
            long size = physicalStorage.tamanho(path);
            String contentType = fileNames.normalizarTipoConteudo(entity.obterTipoConteudo());
            if (size != entity.obterTamanhoBytes()) {
                entity.atualizarDataModificacao(size, contentType);
                storedFiles.save(entity);
            }
            return new ArquivoArmazenado(
                    entity.obterId(),
                    entity.obterNomeOriginalArquivo(),
                    contentType,
                    size,
                    path,
                    ownerClientId
            );
        } catch (IOException error) {
            throw new com.folhio.api.handler.file.exception.ArmazenamentoArquivoException("Não foi possível ler o arquivo.", error);
        }
    }

    private void validarAcessoProprietarioAtual(ArquivoArmazenadoEntity entity) {
        String currentOwner = proprietarioAtualObrigatorio();
        if (!userFiles.existePorArquivoEClienteProprietario(entity.obterId(), currentOwner)) {
            throw new com.folhio.api.handler.file.exception.ArquivoNaoEncontradoException("Arquivo não encontrado.");
        }
    }

    private String proprietarioDoArquivoUsuario(String fileId) {
        return userFiles.buscarPorIdentificadorArquivo(fileId)
                .stream()
                .findFirst()
                .map(ArquivoUsuario::obterIdentificadorClienteProprietario)
                .orElse("");
    }

    private String exigirProprietario(String ownerClientId) {
        if (ownerClientId == null || ownerClientId.isBlank()) {
            throw new com.folhio.api.handler.auth.exception.IdentificadorClienteInvalidoException("Identificador do app ausente.");
        }
        return ownerClientId;
    }

    private String proprietarioAtualObrigatorio() {
        return exigirProprietario(currentOwnerClientId.get());
    }

    private String normalizarIdentificadorUsuarioProprietario(String ownerUserId) {
        if (ownerUserId == null || ownerUserId.isBlank()) {
            return null;
        }
        return ownerUserId.trim();
    }

    private void definirOuRemover(ThreadLocal<String> holder, String value) {
        if (value == null || value.isBlank()) {
            holder.remove();
        } else {
            holder.set(value);
        }
    }

    private String identificadorArmazenamentoValido(String id) {
        if (!ehIdentificadorArmazenamento(id)) {
            throw new com.folhio.api.handler.validation.exception.DadosInvalidosException("Id de arquivo inválido.");
        }
        return id;
    }

    private boolean ehIdentificadorArmazenamento(String id) {
        return id != null && !id.isBlank() && STORAGE_ID_PATTERN.matcher(id).matches();
    }

    private void excluirDiretorioRecursivamenteSilenciosamente(Path directory) {
        physicalStorage.excluirDiretorioSilenciosamente(directory);
    }

    @FunctionalInterface
    public interface ArquivoWriter {
        void escrever(Path target) throws IOException;
    }
}
