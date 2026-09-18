package com.folhio.api.processing.ocr;

import com.folhio.api.progress.ProgressoTracker;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class DocumentoMineruClient {

    private static final Pattern ENV_PLACEHOLDER = Pattern.compile("\\$\\{([A-Za-z_][A-Za-z0-9_]*)}");

    private final Path projectRoot;
    private final Path runtimeRoot;
    private final ObjectMapper objectMapper;

    public DocumentoMineruClient() {
        this.projectRoot = buscarRaizProjeto();
        this.runtimeRoot = projectRoot.resolve("document-processing").resolve("mineru-runtime");
        this.objectMapper = new ObjectMapper();
    }

    @com.fasterxml.jackson.annotation.JsonProperty("available")
    public boolean estaDisponivel() {
        try {
            DocumentoMineruConfig config = carregarConfiguracao();
            return config.enabled() && config.mineruExe() != null && Files.exists(config.mineruExe());
        } catch (Exception ignored) {
            return false;
        }
    }

    public DocumentoMineru analisar(Path filePath) throws IOException, InterruptedException {
        DocumentoMineruConfig config = carregarConfiguracao();
        validar(filePath, config);

        Path runOutput = config.outputDir().resolve("run-" + UUID.randomUUID());
        Files.createDirectories(runOutput);

        List<String> command = new ArrayList<>();
        command.add(config.mineruExe().toAbsolutePath().toString());
        command.add("-p");
        command.add(filePath.toAbsolutePath().toString());
        command.add("-o");
        command.add(runOutput.toAbsolutePath().toString());
        command.add("-m");
        command.add(config.method());
        command.add("-b");
        command.add(config.backend());
        command.add("-l");
        command.add(config.language());

        Path logFile = runOutput.resolve("mineru.log");
        ProcessBuilder builder = new ProcessBuilder(command);
        builder.redirectErrorStream(true);
        builder.redirectOutput(logFile.toFile());
        configurarAmbiente(builder.environment());

        Process process = builder.start();
        boolean finished = aguardarComProgresso(process, config.timeout());
        String output = Files.exists(logFile) ? Files.readString(logFile, StandardCharsets.UTF_8) : "";
        if (!finished) {
            process.destroyForcibly();
            throw new IOException("MinerU demorou demais para terminar.");
        }
        if (process.exitValue() != 0) {
            throw new IOException("MinerU retornou erro. Codigo: " + process.exitValue() + System.lineSeparator() + output);
        }

        Path contentList = buscarListaConteudoV2(runOutput)
                .orElseThrow(() -> new IOException("MinerU não gerou content_list_v2.json."));
        return interpretarListaConteudo(contentList, runOutput);
    }

    private boolean aguardarComProgresso(Process process, Duration timeout) throws InterruptedException {
        long started = System.nanoTime();
        long timeoutNanos = timeout.toNanos();
        while (process.isAlive()) {
            long elapsed = System.nanoTime() - started;
            if (elapsed > timeoutNanos) {
                return false;
            }
            double fraction = Math.min(0.62, elapsed / (double) timeoutNanos * 0.62);
            com.folhio.api.progress.ProgressoTracker.atualizar(0.20 + fraction, "Analisando layout e texto");
            process.waitFor(2, TimeUnit.SECONDS);
        }
        return true;
    }

    private DocumentoMineru interpretarListaConteudo(Path contentList, Path runOutput) throws IOException {
        JsonNode root = objectMapper.readTree(contentList.toFile());
        List<List<ElementoMineru>> pages = new ArrayList<>();
        if (root.isArray() && root.size() > 0 && root.get(0).isArray()) {
            for (JsonNode pageNode : root) {
                pages.add(interpretarPagina(pageNode, contentList.getParent()));
            }
        } else if (root.isArray()) {
            pages.add(interpretarPagina(root, contentList.getParent()));
        }
        return new DocumentoMineru(pages, runOutput);
    }

    private List<ElementoMineru> interpretarPagina(JsonNode pageNode, Path baseDir) {
        List<ElementoMineru> elements = new ArrayList<>();
        for (JsonNode node : iteravel(pageNode)) {
            String type = textoDe(node, "type");
            JsonNode content = node.path("content");
            String text = textoConteudo(type, content);
            String html = textoDe(content, "html");
            Path imagePath = caminhoImagem(content, baseDir);
            int level = (int) Math.round(numeroDe(content, "level", 0));
            elements.add(new ElementoMineru(type, normalizarTexto(text), level, html, imagePath, numerosDe(node.path("bbox"))));
        }
        elements.sort(Comparator.comparingDouble(DocumentoMineruClient::topo).thenComparingDouble(DocumentoMineruClient::esquerda));
        return elements;
    }

    private String textoConteudo(String type, JsonNode content) {
        if ("title".equals(type)) {
            return juntarTextoEmLinha(content.path("title_content"));
        }
        if ("paragraph".equals(type)) {
            return juntarTextoEmLinha(content.path("paragraph_content"));
        }
        if ("text".equals(type)) {
            return juntarTextoEmLinha(content.path("text"));
        }
        return textoDe(content, "text");
    }

    private String juntarTextoEmLinha(JsonNode node) {
        if (node == null || node.isMissingNode()) {
            return "";
        }
        if (node.isTextual()) {
            return node.asText("");
        }
        List<String> parts = new ArrayList<>();
        for (JsonNode item : iteravel(node)) {
            String value = textoDe(item, "content");
            if (!value.isBlank()) {
                parts.add(value);
            }
        }
        return String.join("", parts);
    }

    private Path caminhoImagem(JsonNode content, Path baseDir) {
        String relative = textoDe(content.path("image_source"), "path");
        return relative.isBlank() ? null : baseDir.resolve(relative).normalize();
    }

    private Optional<Path> buscarListaConteudoV2(Path outputDir) throws IOException {
        try (var stream = Files.walk(outputDir)) {
            return stream
                    .filter(path -> path.getFileName().toString().endsWith("_content_list_v2.json"))
                    .findFirst();
        }
    }

    private DocumentoMineruConfig carregarConfiguracao() throws IOException {
        Path localConfig = runtimeRoot.resolve("config").resolve("mineru.local.json");
        Path defaultConfig = runtimeRoot.resolve("config").resolve("mineru.json");
        Path configPath = Files.exists(localConfig) ? localConfig : defaultConfig;
        JsonNode root = objectMapper.readTree(configPath.toFile());
        return new DocumentoMineruConfig(
                booleanoDe(root, "enabled", true),
                caminhoConfigurado(textoDe(root, "mineruExe"), runtimeRoot),
                caminhoConfigurado(textoDe(root, "outputDir", "output"), runtimeRoot),
                textoDe(root, "backend", "pipeline"),
                textoDe(root, "method", "ocr"),
                textoDe(root, "language", "latin"),
                Duration.ofSeconds((long) numeroDe(root, "timeoutSeconds", 900))
        );
    }

    private void validar(Path filePath, DocumentoMineruConfig config) {
        if (!Files.exists(runtimeRoot)) {
            throw new IllegalStateException("Configuracao do MinerU não encontrada.");
        }
        if (filePath == null || !Files.exists(filePath)) {
            throw new IllegalArgumentException("Arquivo para OCR não encontrado.");
        }
        if (!config.enabled()) {
            throw new IllegalStateException("MinerU desativado.");
        }
        if (config.mineruExe() == null) {
            throw new IllegalStateException("Executavel do MinerU nao configurado. Defina MINERU_EXE ou use config/mineru.local.json.");
        }
        if (!Files.exists(config.mineruExe())) {
            throw new IllegalStateException("Executavel do MinerU não encontrado: " + config.mineruExe());
        }
    }

    private void configurarAmbiente(Map<String, String> environment) throws IOException {
        environment.putIfAbsent("MINERU_MODEL_SOURCE", "huggingface");
    }

    private static Path caminhoConfigurado(String rawValue, Path baseDir) {
        String value = expandirVariaveisAmbiente(rawValue).trim();
        if (value.isBlank()) {
            return null;
        }
        Path path = Path.of(value);
        return path.isAbsolute() ? path.normalize() : baseDir.resolve(path).normalize();
    }

    private static String expandirVariaveisAmbiente(String rawValue) {
        String value = rawValue == null ? "" : rawValue;
        Matcher matcher = ENV_PLACEHOLDER.matcher(value);
        StringBuilder expanded = new StringBuilder();
        while (matcher.find()) {
            matcher.appendReplacement(expanded, Matcher.quoteReplacement(System.getenv().getOrDefault(matcher.group(1), "")));
        }
        matcher.appendTail(expanded);
        return expanded.toString();
    }

    private static Iterable<JsonNode> iteravel(JsonNode node) {
        return node != null && node.isArray() ? node : Collections.emptyList();
    }

    private static List<Double> numerosDe(JsonNode node) {
        List<Double> values = new ArrayList<>();
        for (JsonNode item : iteravel(node)) {
            values.add(item.asDouble());
        }
        return values;
    }

    private static double topo(ElementoMineru element) {
        return element.bbox() == null || element.bbox().size() < 2 ? 0 : element.bbox().get(1);
    }

    private static double esquerda(ElementoMineru element) {
        return element.bbox() == null || element.bbox().isEmpty() ? 0 : element.bbox().get(0);
    }

    private static String normalizarTexto(String text) {
        if (text == null) {
            return "";
        }
        return text.replace(" M 0U N", " M OU N").trim();
    }

    private static String textoDe(JsonNode node, String field) {
        return textoDe(node, field, "");
    }

    private static String textoDe(JsonNode node, String field, String fallback) {
        JsonNode value = node == null ? null : node.path(field);
        return value == null || value.isMissingNode() || value.isNull() ? fallback : value.asText(fallback);
    }

    private static boolean booleanoDe(JsonNode node, String field, boolean fallback) {
        JsonNode value = node == null ? null : node.path(field);
        return value == null || !value.isBoolean() ? fallback : value.asBoolean();
    }

    private static double numeroDe(JsonNode node, String field, double fallback) {
        JsonNode value = node == null ? null : node.path(field);
        return value == null || !value.isNumber() ? fallback : value.asDouble();
    }

    private record DocumentoMineruConfig(
            boolean enabled,
            Path mineruExe,
            Path outputDir,
            String backend,
            String method,
            String language,
            Duration timeout
    ) {
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

