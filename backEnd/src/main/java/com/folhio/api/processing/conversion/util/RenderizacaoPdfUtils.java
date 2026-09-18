package com.folhio.api.processing.conversion.util;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.pdmodel.graphics.image.LosslessFactory;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.geom.AffineTransform;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

public final class RenderizacaoPdfUtils {

    private RenderizacaoPdfUtils() {
    }

    public static BufferedImage converterParaRgb(BufferedImage source) {
        if (source.getType() == BufferedImage.TYPE_INT_RGB) {
            return source;
        }

        BufferedImage rgb = new BufferedImage(source.getWidth(), source.getHeight(), BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = rgb.createGraphics();
        try {
            graphics.setColor(Color.WHITE);
            graphics.fillRect(0, 0, rgb.getWidth(), rgb.getHeight());
            graphics.drawImage(source, 0, 0, null);
        } finally {
            graphics.dispose();
        }
        return rgb;
    }

    public static BufferedImage lerImagemComOrientacao(Path imagePath) throws IOException {
        BufferedImage image = ImageIO.read(imagePath.toFile());
        if (image == null) {
            return null;
        }
        return aplicarOrientacaoExif(image, lerOrientacaoExif(imagePath));
    }

    public static void escreverPdfTexto(Path target, String text, String title) throws IOException {
        try (PDDocument document = new PDDocument()) {
            PDType1Font titleFont = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
            PDType1Font bodyFont = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
            PDPage page = new PDPage(PDRectangle.A4);
            document.addPage(page);
            PDPageContentStream stream = new PDPageContentStream(document, page);
            float y = 780;
            if (title != null && !title.isBlank()) {
                escreverLinhaPdf(stream, titleFont, 16, title, y);
                y -= 32;
            }

            for (String rawLine : text.split("\\R")) {
                for (String line : quebrarLinhas(rawLine, 92)) {
                    if (y < 50) {
                        stream.close();
                        page = new PDPage(PDRectangle.A4);
                        document.addPage(page);
                        stream = new PDPageContentStream(document, page);
                        y = 780;
                    }
                    escreverLinhaPdf(stream, bodyFont, 10, line, y);
                    y -= 16;
                }
            }
            stream.close();
            document.save(target.toFile());
        }
    }

    public static void escreverLinhaPdf(PDPageContentStream stream, PDType1Font font, int size, String text, float y) throws IOException {
        escreverLinhaPdfNaPosicao(stream, font, size, text, 42, y);
    }

    public static void escreverLinhaPdfNaPosicao(PDPageContentStream stream, PDType1Font font, int size, String text, float x, float y) throws IOException {
        stream.beginText();
        stream.setFont(font, size);
        stream.newLineAtOffset(x, y);
        stream.showText(limparTextoPdf(text));
        stream.endText();
    }

    public static List<String> quebrarLinhas(String text, int maxLength) {
        if (text == null || text.isBlank()) {
            return List.of(" ");
        }
        List<String> lines = new ArrayList<>();
        String remaining = text.trim();
        while (remaining.length() > maxLength) {
            int split = remaining.lastIndexOf(' ', maxLength);
            if (split < 20) {
                split = maxLength;
            }
            lines.add(remaining.substring(0, split).trim());
            remaining = remaining.substring(split).trim();
        }
        lines.add(remaining);
        return lines;
    }

    public static String limparTextoPdf(String text) {
        return (text == null ? "" : text)
                .replace("\u2013", "-")
                .replace("\u2014", "-")
                .replace("\u201c", "\"")
                .replace("\u201d", "\"")
                .replace("\u2018", "'")
                .replace("\u2019", "'")
                .replaceAll("[^\\x09\\x0A\\x0D\\x20-\\x7E\\p{L}\\p{N}\\p{Punct}]", "");
    }

    public static PDRectangle tamanhoPaginaExibida(PDPage page) {
        PDRectangle box = page.getMediaBox();
        int rotation = ((page.getRotation() % 360) + 360) % 360;
        if (rotation == 90 || rotation == 270) {
            return new PDRectangle(box.getHeight(), box.getWidth());
        }
        return box;
    }

    public static PDImageXObject converterImagemParaImagemPdf(BufferedImage image, PDDocument document) throws IOException {
        return LosslessFactory.createFromImage(document, image);
    }

    private static int lerOrientacaoExif(Path imagePath) {
        try (InputStream input = Files.newInputStream(imagePath)) {
            if (input.read() != 0xFF || input.read() != 0xD8) {
                return 1;
            }

            while (true) {
                int prefix;
                do {
                    prefix = input.read();
                    if (prefix < 0) return 1;
                } while (prefix != 0xFF);

                int marker;
                do {
                    marker = input.read();
                    if (marker < 0) return 1;
                } while (marker == 0xFF);

                if (marker == 0xDA || marker == 0xD9) {
                    return 1;
                }

                int high = input.read();
                int low = input.read();
                if (high < 0 || low < 0) return 1;
                int length = (high << 8) | low;
                if (length < 2) return 1;

                byte[] segment = input.readNBytes(length - 2);
                if (marker == 0xE1 && segment.length > 14 &&
                        segment[0] == 'E' && segment[1] == 'x' &&
                        segment[2] == 'i' && segment[3] == 'f') {
                    return interpretarOrientacaoExif(segment);
                }
            }
        } catch (IOException | RuntimeException ignored) {
            return 1;
        }
    }

    private static int interpretarOrientacaoExif(byte[] exif) {
        int tiff = 6;
        boolean littleEndian = exif[tiff] == 'I' && exif[tiff + 1] == 'I';
        boolean bigEndian = exif[tiff] == 'M' && exif[tiff + 1] == 'M';
        if (!littleEndian && !bigEndian) {
            return 1;
        }

        int ifdOffset = lerInteiroExif(exif, tiff + 4, littleEndian);
        int ifd = tiff + ifdOffset;
        if (ifd < 0 || ifd + 2 > exif.length) {
            return 1;
        }

        int entries = lerInteiroCurtoExif(exif, ifd, littleEndian);
        for (int index = 0; index < entries; index++) {
            int entry = ifd + 2 + (index * 12);
            if (entry + 12 > exif.length) {
                return 1;
            }
            int tag = lerInteiroCurtoExif(exif, entry, littleEndian);
            if (tag == 0x0112) {
                int orientation = lerInteiroCurtoExif(exif, entry + 8, littleEndian);
                return orientation >= 1 && orientation <= 8 ? orientation : 1;
            }
        }
        return 1;
    }

    private static int lerInteiroCurtoExif(byte[] bytes, int offset, boolean littleEndian) {
        if (littleEndian) {
            return (bytes[offset] & 0xFF) | ((bytes[offset + 1] & 0xFF) << 8);
        }
        return ((bytes[offset] & 0xFF) << 8) | (bytes[offset + 1] & 0xFF);
    }

    private static int lerInteiroExif(byte[] bytes, int offset, boolean littleEndian) {
        if (littleEndian) {
            return (bytes[offset] & 0xFF) |
                    ((bytes[offset + 1] & 0xFF) << 8) |
                    ((bytes[offset + 2] & 0xFF) << 16) |
                    ((bytes[offset + 3] & 0xFF) << 24);
        }
        return ((bytes[offset] & 0xFF) << 24) |
                ((bytes[offset + 1] & 0xFF) << 16) |
                ((bytes[offset + 2] & 0xFF) << 8) |
                (bytes[offset + 3] & 0xFF);
    }

    private static BufferedImage aplicarOrientacaoExif(BufferedImage source, int orientation) {
        if (orientation == 1) {
            return source;
        }

        int width = source.getWidth();
        int height = source.getHeight();
        boolean swapSize = orientation == 5 || orientation == 6 || orientation == 7 || orientation == 8;
        BufferedImage output = new BufferedImage(
                swapSize ? height : width,
                swapSize ? width : height,
                source.getColorModel().hasAlpha() ? BufferedImage.TYPE_INT_ARGB : BufferedImage.TYPE_INT_RGB
        );

        AffineTransform transform = new AffineTransform();
        switch (orientation) {
            case 2 -> {
                transform.scale(-1, 1);
                transform.translate(-width, 0);
            }
            case 3 -> {
                transform.translate(width, height);
                transform.rotate(Math.PI);
            }
            case 4 -> {
                transform.scale(1, -1);
                transform.translate(0, -height);
            }
            case 5 -> {
                transform.rotate(Math.PI / 2);
                transform.scale(1, -1);
            }
            case 6 -> {
                transform.translate(height, 0);
                transform.rotate(Math.PI / 2);
            }
            case 7 -> {
                transform.translate(height, width);
                transform.rotate(Math.PI / 2);
                transform.scale(-1, 1);
            }
            case 8 -> {
                transform.translate(0, width);
                transform.rotate(-Math.PI / 2);
            }
            default -> {
                return source;
            }
        }

        Graphics2D graphics = output.createGraphics();
        graphics.drawImage(source, transform, null);
        graphics.dispose();
        return output;
    }
}
