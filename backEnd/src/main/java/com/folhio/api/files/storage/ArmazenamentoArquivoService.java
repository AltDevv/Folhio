package com.folhio.api.files.storage;

import org.springframework.stereotype.Service;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Comparator;

@Service
public class ArmazenamentoArquivoService {
    private final CaminhosArmazenamentoArquivo paths;

    public ArmazenamentoArquivoService(CaminhosArmazenamentoArquivo paths) {
        this.paths = paths;
    }

    public long salvar(InputStream input, Path target, long exclusiveLimit) throws IOException {
        validar(target);
        Files.createDirectories(target.getParent());
        long total = 0;
        try (OutputStream output = Files.newOutputStream(target)) {
            byte[] buffer = new byte[64 * 1024];
            int read;
            while ((read = input.read(buffer)) != -1) {
                total += read;
                if (total >= exclusiveLimit) {
                    throw new com.folhio.api.handler.file.exception.LimiteEnvioExcedidoException();
                }
                output.write(buffer, 0, read);
            }
        }
        return total;
    }

    public void mover(Path source, Path target) throws IOException {
        validar(source);
        validar(target);
        Files.createDirectories(target.getParent());
        Files.move(source, target, StandardCopyOption.REPLACE_EXISTING);
    }

    public void escrever(Path target, ArquivoWriter writer) throws IOException {
        validar(target);
        Files.createDirectories(target.getParent());
        try {
            writer.escrever(target);
        } catch (IOException | RuntimeException error) {
            excluirSilenciosamente(target);
            throw error;
        }
    }

    public InputStream abrir(Path path) throws IOException {
        validar(path);
        return Files.newInputStream(path);
    }

    public long tamanho(Path path) throws IOException {
        validar(path);
        return Files.size(path);
    }

    public boolean existe(Path path) {
        validar(path);
        return Files.isRegularFile(path);
    }

    public void excluirSilenciosamente(Path path) {
        if (path == null) return;
        validar(path);
        try {
            Files.deleteIfExists(path);
            Path parent = path.getParent();
            if (!parent.equals(paths.raiz())) {
                try (var children = Files.list(parent)) {
                    if (children.findAny().isPresent()) return;
                }
                Files.deleteIfExists(parent);
            }
        } catch (IOException ignored) {
            // Cleanup must not replace the original processing error.
        }
    }

    public void excluirDiretorioSilenciosamente(Path directory) {
        validar(directory);
        if (!Files.isDirectory(directory)) return;
        try (var entries = Files.walk(directory)) {
            for (Path path : entries.sorted(Comparator.reverseOrder()).toList()) {
                validar(path);
                Files.deleteIfExists(path);
            }
        } catch (IOException ignored) {
            // Expired temporary files are retried on the next cleanup run.
        }
    }

    private void validar(Path path) {
        paths.validarDentroRaiz(path);
        for (Path item = path.toAbsolutePath().normalize(); item != null; item = item.getParent()) {
            if (Files.isSymbolicLink(item)) {
                throw new com.folhio.api.handler.file.exception.ArquivoInvalidoException("Links simbolicos nao sao permitidos no storage.");
            }
        }
    }

    @FunctionalInterface
    public interface ArquivoWriter {
        void escrever(Path target) throws IOException;
    }
}
