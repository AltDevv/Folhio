package com.folhio.api.processing.conversion.office;

import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.TimeUnit;

@Service
public class ConversaoLibreOfficeService {
    private final String configuredSofficePath;

    public ConversaoLibreOfficeService(@Value("${folhio.office.soffice-path:}") String configuredSofficePath) {
        this.configuredSofficePath = configuredSofficePath;
    }

    public void converterParaPdf(Path input, String originalName, Path target) throws IOException {
        Path tempDir = Files.createTempDirectory("folhio-libreoffice-");
        try {
            String extension = com.folhio.api.files.policy.NomeArquivoPolicy.extensaoDe(originalName);
            Path source = tempDir.resolve("source." + extension);
            Files.copy(input, source, StandardCopyOption.REPLACE_EXISTING);
            Path profile = Files.createDirectories(tempDir.resolve("profile"));
            String executable = resolverExecutavelSoffice();
            List<String> command = List.of(
                    executable,
                    "--headless",
                    "--nologo",
                    "--nofirststartwizard",
                    "--nolockcheck",
                    "--nodefault",
                    "-env:UserInstallation=" + profile.toUri(),
                    "--convert-to",
                    "pdf",
                    "--outdir",
                    tempDir.toString(),
                    source.toAbsolutePath().toString()
            );
            Process process = new ProcessBuilder(command)
                    .redirectErrorStream(true)
                    .redirectOutput(ProcessBuilder.Redirect.DISCARD)
                    .start();
            try {
                if (!process.waitFor(75, TimeUnit.SECONDS)) {
                    process.destroyForcibly();
                    throw new IOException("LibreOffice demorou demais para converter o documento.");
                }
            } catch (InterruptedException error) {
                process.destroyForcibly();
                Thread.currentThread().interrupt();
                throw new IOException("Conversao com LibreOffice interrompida.", error);
            }
            if (process.exitValue() != 0) {
                throw new IOException("LibreOffice nao conseguiu converter o documento.");
            }
            Path converted = buscarPdfConvertido(tempDir);
            Files.copy(converted, target, StandardCopyOption.REPLACE_EXISTING);
        } finally {
            excluirDiretorioSilenciosamente(tempDir);
        }
    }

    private Path buscarPdfConvertido(Path tempDir) throws IOException {
        try (var files = Files.list(tempDir)) {
            return files
                    .filter(Files::isRegularFile)
                    .filter(path -> path.getFileName().toString().toLowerCase(Locale.ROOT).endsWith(".pdf"))
                    .findFirst()
                    .orElseThrow(() -> new IOException("LibreOffice nao gerou PDF."));
        }
    }

    private String resolverExecutavelSoffice() {
        if (configuredSofficePath != null && !configuredSofficePath.isBlank() && Files.isRegularFile(Path.of(configuredSofficePath))) {
            return configuredSofficePath;
        }
        for (String candidate : List.of(
                "C:\\Program Files\\LibreOffice\\program\\soffice.exe",
                "C:\\Program Files (x86)\\LibreOffice\\program\\soffice.exe",
                "C:\\Program Files\\OpenOffice 4\\program\\soffice.exe",
                "C:\\Program Files (x86)\\OpenOffice 4\\program\\soffice.exe"
        )) {
            if (Files.isRegularFile(Path.of(candidate))) {
                return candidate;
            }
        }
        return "soffice";
    }

    private void excluirDiretorioSilenciosamente(Path directory) {
        try (var paths = Files.walk(directory)) {
            paths.sorted(Comparator.reverseOrder()).forEach(path -> {
                try {
                    Files.deleteIfExists(path);
                } catch (IOException ignored) {
                    // Best effort cleanup.
                }
            });
        } catch (IOException ignored) {
            // Best effort cleanup.
        }
    }

}
