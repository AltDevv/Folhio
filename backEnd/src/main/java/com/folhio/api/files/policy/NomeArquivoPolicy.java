package com.folhio.api.files.policy;

import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Set;

public class NomeArquivoPolicy {

    private static final int MAX_FILE_NAME_LENGTH = 160;
    private static final Set<String> ALLOWED_UPLOAD_EXTENSIONS = Set.of(
            "pdf",
            "png",
            "jpg",
            "jpeg",
            "doc",
            "docx",
            "ppt",
            "pptx",
            "xls",
            "xlsx",
            "webm",
            "mp4",
            "mov",
            "m4v",
            "avi",
            "mkv",
            "3gp",
            "mpeg",
            "mpg",
            "mts",
            "m2ts",
            "ts",
            "wmv",
            "flv"
    );
    private static final Set<String> ALLOWED_OUTPUT_EXTENSIONS = Set.of(
            "pdf",
            "png",
            "jpg",
            "jpeg",
            "docx",
            "pptx",
            "xlsx",
            "zip"
    );

    public String prepararNomeEnvio(MultipartFile file) throws IOException {
        String fileName = limpar(file.getOriginalFilename(), "arquivo");
        fileName = garantirExtensaoEnvio(fileName, file);
        validarExtensaoPermitida(fileName, ALLOWED_UPLOAD_EXTENSIONS);
        return fileName;
    }

    public String prepararNomeSaida(String suggestedName) {
        String fileName = limpar(suggestedName, "resultado");
        validarExtensaoPermitida(fileName, ALLOWED_OUTPUT_EXTENSIONS);
        return fileName;
    }

    public String limpar(String fileName, String fallback) {
        String clean = StringUtils.cleanPath(fileName == null ? fallback : fileName);
        clean = clean
                .replace('\\', '_')
                .replace('/', '_')
                .replace(':', '_')
                .replace('"', '_')
                .replace('\'', '_')
                .replaceAll("[\\r\\n\\t\\x00-\\x1F]", "_")
                .trim();
        if (clean.isBlank() || clean.contains("..")) {
            return fallback;
        }
        return clean.length() <= MAX_FILE_NAME_LENGTH ? clean : clean.substring(0, MAX_FILE_NAME_LENGTH);
    }

    public String normalizarTipoConteudo(String contentType) {
        return contentType == null || contentType.isBlank() ? "application/octet-stream" : contentType;
    }

    public static String extensaoDe(String fileName) {
        if (fileName == null) {
            return "";
        }
        int dot = fileName.lastIndexOf('.');
        return dot >= 0 ? fileName.substring(dot + 1).toLowerCase() : "";
    }

    public static String semExtensao(String fileName) {
        if (fileName == null || fileName.isBlank()) {
            return "arquivo";
        }
        int dot = fileName.lastIndexOf('.');
        return dot > 0 ? fileName.substring(0, dot) : fileName;
    }

    private void validarExtensaoPermitida(String fileName, Set<String> allowedExtensions) {
        String extension = extensaoDe(fileName);
        if (!allowedExtensions.contains(extension)) {
            throw new com.folhio.api.handler.file.exception.FormatoArquivoNaoSuportadoException("Tipo de arquivo não permitido.");
        }
    }

    private String garantirExtensaoEnvio(String fileName, MultipartFile file) throws IOException {
        String extension = extensaoDe(fileName);
        if (ALLOWED_UPLOAD_EXTENSIONS.contains(extension)) {
            return fileName;
        }

        String detectedExtension = detectarExtensaoEnvio(primeirosBytes(file, 16));
        if (detectedExtension.isBlank()) {
            return fileName;
        }

        String baseName = fileName;
        int dotIndex = baseName.lastIndexOf('.');
        if (dotIndex > 0) {
            baseName = baseName.substring(0, dotIndex);
        }
        baseName = limpar(baseName, "arquivo");
        return limpar(baseName + "." + detectedExtension, "arquivo." + detectedExtension);
    }

    private String detectarExtensaoEnvio(byte[] header) {
        if (comecaComAscii(header, "%PDF")) return "pdf";
        if (comecaCom(header, 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)) return "png";
        if (comecaCom(header, 0xFF, 0xD8, 0xFF)) return "jpg";
        if (comecaCom(header, 0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1)) return "doc";
        if (comecaCom(header, 0x1A, 0x45, 0xDF, 0xA3)) return "webm";
        if (temAsciiNaPosicao(header, 4, "ftyp")) {
            String brand = trechoAscii(header, 8, 12);
            if (brand.startsWith("M4A")) return "";
            return "mp4";
        }
        if (comecaComAscii(header, "RIFF") && temAsciiNaPosicao(header, 8, "AVI ")) return "avi";
        if (comecaCom(header, 0x00, 0x00, 0x01)) return "mpeg";
        if (comecaCom(header, 0x47) || temByteNaPosicao(header, 4, 0x47)) return "ts";
        if (comecaCom(header, 0x30, 0x26, 0xB2, 0x75, 0x8E, 0x66, 0xCF, 0x11)) return "wmv";
        if (comecaComAscii(header, "FLV")) return "flv";
        return "";
    }

    private byte[] primeirosBytes(MultipartFile file, int limit) throws IOException {
        byte[] buffer = new byte[limit];
        try (InputStream input = file.getInputStream()) {
            int read = input.read(buffer);
            if (read <= 0) {
                return new byte[0];
            }
            if (read == limit) {
                return buffer;
            }
            byte[] exact = new byte[read];
            System.arraycopy(buffer, 0, exact, 0, read);
            return exact;
        }
    }

    private boolean comecaComAscii(byte[] data, String value) {
        return comecaComBytes(data, value.getBytes(StandardCharsets.US_ASCII), 0);
    }

    private boolean temAsciiNaPosicao(byte[] data, int offset, String value) {
        return comecaComBytes(data, value.getBytes(StandardCharsets.US_ASCII), offset);
    }

    private String trechoAscii(byte[] data, int start, int end) {
        if (data.length <= start) {
            return "";
        }
        int safeEnd = Math.min(data.length, end);
        return new String(data, start, safeEnd - start, StandardCharsets.US_ASCII);
    }

    private boolean comecaCom(byte[] data, int... values) {
        if (data.length < values.length) {
            return false;
        }
        for (int index = 0; index < values.length; index++) {
            if ((data[index] & 0xFF) != values[index]) {
                return false;
            }
        }
        return true;
    }

    private boolean temByteNaPosicao(byte[] data, int offset, int value) {
        return data.length > offset && (data[offset] & 0xFF) == value;
    }

    private boolean comecaComBytes(byte[] data, byte[] values, int offset) {
        if (data.length < offset + values.length) {
            return false;
        }
        for (int index = 0; index < values.length; index++) {
            if (data[offset + index] != values[index]) {
                return false;
            }
        }
        return true;
    }
}
