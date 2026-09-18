package com.folhio.api.files.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

@Component
public class CaminhosArmazenamentoArquivo {

    private final Path root;
    private final Path users;

    public CaminhosArmazenamentoArquivo(@Value("${folhio.storage.root:storage/folhio}") String storageRoot) {
        this.root = Path.of(storageRoot).toAbsolutePath().normalize();
        this.users = root.resolve("users");
    }

    public Path raiz() {
        return root;
    }

    public Path caminhoPara(String storageKey) {
        Path path = root.resolve(storageKey).normalize();
        validarDentroRaiz(path);
        return path;
    }

    public String chaveRelativaArmazenamento(Path target) {
        validarDentroRaiz(target);
        Path relative = root.relativize(target.normalize());
        return relative.toString().replace('\\', '/');
    }

    public Path caminhoArmazenamentoProprietario(String ownerClientId, String area, String id, String fileName) {
        Path path = users
                .resolve(pastaProprietario(ownerClientId))
                .resolve(area)
                .resolve(id)
                .resolve("content")
                .normalize();
        validarDentroRaiz(path);
        return path;
    }

    public Path caminhoEnvioTemporario(String id, String fileName) {
        Path path = root
                .resolve("scan-temp")
                .resolve(id)
                .resolve("content")
                .normalize();
        validarDentroRaiz(path);
        return path;
    }

    public void validarDentroRaiz(Path path) {
        if (path == null || !path.toAbsolutePath().normalize().startsWith(root)
                || path.toAbsolutePath().normalize().equals(root)) {
            throw new IllegalArgumentException("Caminho de arquivo inválido.");
        }
    }

    private String pastaProprietario(String ownerClientId) {
        String clean = ownerClientId
                .trim()
                .replaceAll("[^A-Za-z0-9._-]", "_");
        if (clean.isBlank()) {
            clean = "user";
        }
        if (clean.length() > 48) {
            clean = clean.substring(0, 48);
        }
        return clean + "-" + calcularSha256(ownerClientId).substring(0, 12);
    }

    private String calcularSha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder builder = new StringBuilder(hash.length * 2);
            for (byte item : hash) {
                builder.append("%02x".formatted(item));
            }
            return builder.toString();
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA-256 indisponível.", error);
        }
    }
}
