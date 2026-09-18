package com.folhio.api.files.policy;

import org.springframework.stereotype.Component;
import org.apache.poi.openxml4j.opc.OPCPackage;
import org.apache.poi.openxml4j.opc.PackageAccess;
import org.apache.poi.openxml4j.opc.TargetMode;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.zip.CRC32;
import java.util.zip.ZipFile;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;

@Component
public class ConteudoArquivoValidator {
    private static final Map<String, String> OFFICE_PARTS = Map.of(
            "docx", "/word/document.xml", "xlsx", "/xl/workbook.xml", "pptx", "/ppt/presentation.xml");
    private static final Map<String, String> OFFICE_TYPES = Map.of(
            "docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml",
            "xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml",
            "pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml");
    private static final Map<String, String> MIME_TYPES = Map.of(
            "docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation");

    public void validar(Path path, String name, String mimeType) {
        String extension = NomeArquivoPolicy.extensaoDe(name);
        if (OFFICE_PARTS.containsKey(extension)) {
            validarOffice(path, extension, mimeType);
            return;
        }
        try (var input = Files.newInputStream(path)) {
            byte[] header = input.readNBytes(16);
            boolean valid = switch (extension) {
                case "pdf" -> comeca(header, 0x25, 0x50, 0x44, 0x46, 0x2D);
                case "png" -> comeca(header, 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a);
                case "jpg", "jpeg" -> comeca(header, 0xff, 0xd8, 0xff);
                case "doc", "xls", "ppt" -> comeca(header, 0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1);
                default -> header.length > 0;
            };
            if (!valid) throw invalido();
        } catch (IOException error) {
            throw new com.folhio.api.handler.file.exception.ArquivoInvalidoException("Arquivo ilegivel.", error);
        }
    }

    private void validarOffice(Path path, String extension, String mimeType) {
        String mime = mimeType == null ? "" : mimeType.split(";", 2)[0].trim().toLowerCase(Locale.ROOT);
        if (!mime.isEmpty() && !mime.equals("application/octet-stream") && !mime.equals(MIME_TYPES.get(extension))) {
            throw invalido();
        }
        try {
            validarZip(path);
            try (OPCPackage document = OPCPackage.open(path.toFile(), PackageAccess.READ)) {
                var relations = document.getRelationshipsByType(
                        "http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument");
                if (relations.size() != 1) throw invalido();
                var relation = relations.getRelationship(0);
                if (relation.getTargetMode() != TargetMode.INTERNAL) throw invalido();
                var part = document.getPart(relation);
                if (part == null || !part.getPartName().getName().equals(OFFICE_PARTS.get(extension))
                        || !part.getContentType().equals(OFFICE_TYPES.get(extension))) throw invalido();
                DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
                factory.setNamespaceAware(true);
                factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
                factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
                factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
                factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
                factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
                try (var input = part.getInputStream()) {
                    var root = factory.newDocumentBuilder().parse(input).getDocumentElement();
                    String expected = switch (extension) {
                        case "docx" -> "document";
                        case "xlsx" -> "workbook";
                        default -> "presentation";
                    };
                    if (!expected.equals(root.getLocalName())) throw invalido();
                }
            }
        } catch (Exception error) {
            throw new com.folhio.api.handler.file.exception.ArquivoInvalidoException("Documento Office invalido ou corrompido.", error);
        }
    }

    private void validarZip(Path path) throws IOException {
        Set<String> names = new HashSet<>();
        long total = 0;
        try (ZipFile zip = new ZipFile(path.toFile())) {
            var entries = zip.entries();
            while (entries.hasMoreElements()) {
                var entry = entries.nextElement();
                String name = entry.getName();
                if (!names.add(name) || names.size() > 4096 || name.startsWith("/")
                        || name.contains("\\") || name.contains("../") || name.contains(":")
                        || name.toLowerCase(Locale.ROOT).endsWith("vbaproject.bin")) throw invalido();
                if (entry.isDirectory()) continue;
                long size = 0;
                CRC32 crc = new CRC32();
                try (var input = zip.getInputStream(entry)) {
                    byte[] buffer = new byte[8192];
                    int count;
                    while ((count = input.read(buffer)) != -1) {
                        size += count;
                        total += count;
                        if (total > 512L * 1024 * 1024 || size > 64L * 1024 * 1024
                                || size > Math.max(1L, entry.getCompressedSize()) * 200L) throw invalido();
                        crc.update(buffer, 0, count);
                    }
                }
                if (crc.getValue() != entry.getCrc() || size != entry.getSize()) throw invalido();
            }
        }
        if (!names.contains("[Content_Types].xml") || !names.contains("_rels/.rels")) throw invalido();
    }

    private boolean comeca(byte[] header, int... prefix) {
        if (header.length < prefix.length) return false;
        for (int i = 0; i < prefix.length; i++) if ((header[i] & 255) != prefix[i]) return false;
        return true;
    }

    private com.folhio.api.handler.file.exception.ArquivoInvalidoException invalido() {
        return new com.folhio.api.handler.file.exception.ArquivoInvalidoException("Conteudo incompativel com o formato declarado.");
    }
}
