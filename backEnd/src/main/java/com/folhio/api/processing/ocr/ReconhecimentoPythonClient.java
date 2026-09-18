package com.folhio.api.processing.ocr;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class ReconhecimentoPythonClient {

    private static final Pattern ITEMS_PATTERN = Pattern.compile("\"items\"\\s*:\\s*\\[", Pattern.DOTALL);

    private final Path projectRoot;
    private final Path ocrRoot;
    private final Path python;
    private final Path runner;
    private final ObjectMapper objectMapper;

    public ReconhecimentoPythonClient() {
        this.projectRoot = buscarRaizProjeto();
        this.ocrRoot = projectRoot.resolve("document-processing").resolve("ocr-python");
        this.python = ocrRoot.resolve(".venv").resolve("Scripts").resolve("python.exe");
        this.runner = ocrRoot.resolve("scripts").resolve("run_ocr.py");
        this.objectMapper = new ObjectMapper();
    }

    public List<ItemTextoOcr> reconhecer(Path imagePath) throws IOException, InterruptedException {
        return reconhecerDocumento(imagePath).items();
    }

    public DocumentoOcr reconhecerDocumento(Path imagePath) throws IOException, InterruptedException {
        String json = reconhecerComoJson(imagePath);
        return interpretarDocumento(json);
    }

    public String reconhecerComoJson(Path imagePath) throws IOException, InterruptedException {
        validar(imagePath);

        Path outputJson = Files.createTempFile("folhio-ocr-", ".json");
        List<String> command = List.of(
                python.toAbsolutePath().toString(),
                runner.toAbsolutePath().toString(),
                imagePath.toAbsolutePath().toString(),
                outputJson.toAbsolutePath().toString(),
                "--lang",
                "pt"
        );

        ProcessBuilder builder = new ProcessBuilder(command);
        builder.directory(ocrRoot.toFile());
        builder.redirectErrorStream(true);
        configurarAmbiente(builder.environment());

        Process process = builder.start();
        String processOutput = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        int code = process.waitFor();
        if (code != 0) {
            throw new IOException("OCR Python retornou erro. Codigo: " + code + System.lineSeparator() + processOutput);
        }

        return Files.readString(outputJson, StandardCharsets.UTF_8);
    }

    private void validar(Path imagePath) {
        if (!Files.exists(ocrRoot)) {
            throw new IllegalStateException("Pasta OCR Python não encontrada: " + ocrRoot);
        }
        if (!Files.exists(python)) {
            throw new IllegalStateException("Python do OCR não encontrado. Crie o ambiente em: " + python);
        }
        if (!Files.exists(runner)) {
            throw new IllegalStateException("Script OCR não encontrado: " + runner);
        }
        if (imagePath == null || !Files.exists(imagePath)) {
            throw new IllegalArgumentException("Imagem para OCR não encontrada.");
        }
    }

    private void configurarAmbiente(Map<String, String> environment) throws IOException {
        Path cache = ocrRoot.resolve(".cache");
        Files.createDirectories(cache);
        environment.putIfAbsent("USERPROFILE", cache.resolve("home").toString());
        environment.putIfAbsent("HOME", cache.resolve("home").toString());
        environment.putIfAbsent("XDG_CACHE_HOME", cache.resolve("xdg").toString());
        environment.putIfAbsent("PADDLE_HOME", cache.resolve("paddle").toString());
        environment.putIfAbsent("PADDLE_PDX_CACHE_HOME", cache.resolve("paddlex").toString());
        environment.putIfAbsent("YOLO_CONFIG_DIR", cache.resolve("yolo").toString());
        environment.putIfAbsent("DISABLE_MODEL_SOURCE_CHECK", "True");
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

    private static List<ItemTextoOcr> interpretarItens(String json) {
        List<ItemTextoOcr> items = new ArrayList<>();
        String array = extrairListaItens(json);
        for (String object : separarObjetos(array)) {
            items.add(new ItemTextoOcr(
                    extrairTexto(object, "text"),
                    extrairNumero(object, "confidence"),
                    extrairNumero(object, "x"),
                    extrairNumero(object, "y"),
                    extrairNumero(object, "width"),
                    extrairNumero(object, "height"),
                    extrairTexto(object, "lineText"),
                    (int) extrairNumero(object, "lineIndex"),
                    (int) extrairNumero(object, "wordIndex")
            ));
        }
        return items;
    }

    private DocumentoOcr interpretarDocumento(String json) throws IOException {
        JsonNode root = objectMapper.readTree(json);
        List<BlocoOcr> blocks = new ArrayList<>();
        for (JsonNode node : iteravel(root.path("blocks"))) {
            blocks.add(new BlocoOcr(
                    textoDe(node, "type"),
                    textoDe(node, "text"),
                    textosDe(node.path("lines")),
                    numeroDe(node, "x"),
                    numeroDe(node, "y"),
                    numeroDe(node, "width"),
                    numeroDe(node, "height"),
                    textoDe(node, "alignment"),
                    numeroDe(node, "fontSizePt"),
                    numeroDe(node, "confidence")
            ));
        }
        List<ItemTextoOcr> items = interpretarItens(json);
        return new DocumentoOcr(
                textoDe(root, "documentType", "activity_document"),
                textoDe(root, "recommendedMode", "editable"),
                blocks,
                items
        );
    }

    private static Iterable<JsonNode> iteravel(JsonNode node) {
        return node != null && node.isArray() ? node : Collections.emptyList();
    }

    private static List<String> textosDe(JsonNode node) {
        List<String> values = new ArrayList<>();
        for (JsonNode item : iteravel(node)) {
            values.add(item.asText(""));
        }
        return values;
    }

    private static String textoDe(JsonNode node, String field) {
        return textoDe(node, field, "");
    }

    private static String textoDe(JsonNode node, String field, String fallback) {
        JsonNode value = node == null ? null : node.path(field);
        return value == null || value.isMissingNode() || value.isNull() ? fallback : value.asText(fallback);
    }

    private static double numeroDe(JsonNode node, String field) {
        JsonNode value = node == null ? null : node.path(field);
        return value == null || !value.isNumber() ? 0.0d : value.asDouble();
    }

    private static String extrairListaItens(String json) {
        Matcher matcher = ITEMS_PATTERN.matcher(json == null ? "" : json);
        if (!matcher.find()) {
            return "";
        }
        int start = matcher.end();
        int depth = 1;
        boolean inString = false;
        boolean escaped = false;
        for (int index = start; index < json.length(); index++) {
            char ch = json.charAt(index);
            if (escaped) {
                escaped = false;
                continue;
            }
            if (ch == '\\') {
                escaped = true;
                continue;
            }
            if (ch == '"') {
                inString = !inString;
                continue;
            }
            if (inString) {
                continue;
            }
            if (ch == '[') {
                depth++;
            } else if (ch == ']') {
                depth--;
                if (depth == 0) {
                    return json.substring(start, index);
                }
            }
        }
        return "";
    }

    private static List<String> separarObjetos(String arrayJson) {
        List<String> objects = new ArrayList<>();
        int start = -1;
        int depth = 0;
        boolean inString = false;
        boolean escaped = false;
        for (int index = 0; index < arrayJson.length(); index++) {
            char ch = arrayJson.charAt(index);
            if (escaped) {
                escaped = false;
                continue;
            }
            if (ch == '\\') {
                escaped = true;
                continue;
            }
            if (ch == '"') {
                inString = !inString;
                continue;
            }
            if (inString) {
                continue;
            }
            if (ch == '{') {
                if (depth == 0) {
                    start = index;
                }
                depth++;
            } else if (ch == '}') {
                depth--;
                if (depth == 0 && start >= 0) {
                    objects.add(arrayJson.substring(start, index + 1));
                    start = -1;
                }
            }
        }
        return objects;
    }

    private static String extrairTexto(String objectJson, String field) {
        Pattern pattern = Pattern.compile("\"" + Pattern.quote(field) + "\"\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"");
        Matcher matcher = pattern.matcher(objectJson);
        return matcher.find() ? removerEscapeJson(matcher.group(1)) : "";
    }

    private static double extrairNumero(String objectJson, String field) {
        Pattern pattern = Pattern.compile("\"" + Pattern.quote(field) + "\"\\s*:\\s*(-?\\d+(?:\\.\\d+)?)");
        Matcher matcher = pattern.matcher(objectJson);
        return matcher.find() ? Double.parseDouble(matcher.group(1)) : 0.0d;
    }

    private static String removerEscapeJson(String value) {
        return value
                .replace("\\\"", "\"")
                .replace("\\\\", "\\")
                .replace("\\n", "\n")
                .replace("\\r", "\r")
                .replace("\\t", "\t");
    }
}

