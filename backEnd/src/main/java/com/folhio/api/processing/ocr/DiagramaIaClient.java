package com.folhio.api.processing.ocr;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Component
public class DiagramaIaClient {

    private final Path projectRoot;
    private final Path layoutRoot;
    private final Path defaultPython;
    private final Path runner;
    private final ObjectMapper objectMapper;

    public DiagramaIaClient() {
        this.projectRoot = buscarRaizProjeto();
        this.layoutRoot = projectRoot.resolve("document-processing").resolve("layout-ai");
        this.defaultPython = projectRoot.resolve("document-processing").resolve("ocr-python")
                .resolve(".venv").resolve("Scripts").resolve("python.exe");
        this.runner = layoutRoot.resolve("scripts").resolve("analyze_layout.py");
        this.objectMapper = new ObjectMapper();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("available")
    public boolean estaDisponivel() {
        return Files.exists(layoutRoot) && Files.exists(executavelPython()) && Files.exists(runner);
    }

    public JsonNode analisar(Path imagePath, DocumentoOcr ocrDocument) throws IOException, InterruptedException {
        if (!estaDisponivel()) {
            return objectMapper.createObjectNode();
        }
        Path tempDir = Files.createTempDirectory("folhio-layout-ai-");
        Path ocrJson = tempDir.resolve("ocr.json");
        Path outputJson = tempDir.resolve("layout-plan.json");
        objectMapper.writeValue(ocrJson.toFile(), ocrDocument);

        ProcessBuilder builder = new ProcessBuilder(
                executavelPython().toAbsolutePath().toString(),
                runner.toAbsolutePath().toString(),
                "--image",
                imagePath.toAbsolutePath().toString(),
                "--ocr-json",
                ocrJson.toAbsolutePath().toString(),
                "--output",
                outputJson.toAbsolutePath().toString(),
                "--preferred-mode",
                "auto"
        );
        builder.directory(layoutRoot.toFile());
        builder.redirectErrorStream(true);
        configurarAmbiente(builder.environment());

        Process process = builder.start();
        String output = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        boolean finished = process.waitFor(Duration.ofSeconds(75).toMillis(), TimeUnit.MILLISECONDS);
        if (!finished) {
            process.destroyForcibly();
            throw new IOException("Layout AI demorou demais para responder.");
        }
        if (process.exitValue() != 0) {
            throw new IOException("Layout AI retornou erro. Codigo: " + process.exitValue() + System.lineSeparator() + output);
        }
        if (!Files.exists(outputJson)) {
            throw new IOException("Layout AI nao gerou layout-plan.json.");
        }
        return objectMapper.readTree(outputJson.toFile());
    }

    private Path executavelPython() {
        String configured = System.getenv("FOLHIO_LAYOUT_AI_PYTHON");
        if (configured != null && !configured.isBlank()) {
            return Path.of(configured);
        }
        return defaultPython;
    }

    private void configurarAmbiente(Map<String, String> environment) {
        environment.put("PYTHONPATH", layoutRoot.toAbsolutePath().toString());
        environment.putIfAbsent("OLLAMA_HOST", "http://localhost:11434");
    }

    private static Path buscarRaizProjeto() {
        Path current = Path.of("").toAbsolutePath();
        while (current != null) {
            if (Files.isRegularFile(current.resolve("pom.xml"))
                    && Files.isDirectory(current.resolve("document-processing"))) {
                return current;
            }
            Path backend = current.resolve("backEnd");
            if (Files.isRegularFile(backend.resolve("pom.xml"))
                    && Files.isDirectory(backend.resolve("document-processing"))) {
                return backend;
            }
            current = current.getParent();
        }
        return Path.of("").toAbsolutePath();
    }
}
