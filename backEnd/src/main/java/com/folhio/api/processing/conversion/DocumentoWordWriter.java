package com.folhio.api.processing.conversion;

import com.fasterxml.jackson.databind.JsonNode;
import com.folhio.api.service.ArquivoArmazenadoService;
import com.folhio.api.processing.ocr.BlocoOcr;
import com.folhio.api.processing.ocr.ItemTextoOcr;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;
import org.apache.poi.util.Units;
import org.apache.poi.xwpf.usermodel.ParagraphAlignment;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.apache.poi.xwpf.usermodel.XWPFRun;
import org.apache.poi.xwpf.usermodel.XWPFTable;
import org.apache.poi.xwpf.usermodel.XWPFTableCell;
import org.apache.poi.xwpf.usermodel.XWPFTableRow;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTTblBorders;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTTblPr;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.STBorder;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

final class DocumentoWordWriter {

    private static final int EMU_PER_INCH = 914400;

    void escreverTextoSimples(XWPFDocument document, String text) {
        for (String line : text.split("\\R")) {
            XWPFParagraph paragraph = document.createParagraph();
            XWPFRun run = paragraph.createRun();
            run.setText(line.isBlank() ? " " : line);
        }
    }

    void escreverTabelaHtml(XWPFDocument document, String html) {
        List<List<String>> rows = interpretarTabelaHtml(html);
        if (rows.isEmpty()) {
            return;
        }

        int columns = rows.stream().mapToInt(List::size).max().orElse(1);
        XWPFTable table = document.createTable(rows.size(), columns);
        table.setWidth("100%");
        for (int rowIndex = 0; rowIndex < rows.size(); rowIndex++) {
            XWPFTableRow row = table.getRow(rowIndex);
            List<String> cells = rows.get(rowIndex);
            for (int cellIndex = 0; cellIndex < columns; cellIndex++) {
                XWPFTableCell cell = row.getCell(cellIndex);
                XWPFParagraph paragraph = primeiroParagrafoCelula(cell);
                XWPFRun run = paragraph.createRun();
                run.setFontSize(11);
                String value = cellIndex < cells.size() ? cells.get(cellIndex) : "";
                run.setText(value.isBlank() ? " " : value);
            }
        }
        document.createParagraph();
    }

    void ocultarBordasTabela(XWPFTable table) {
        CTTblPr tableProperties = table.getCTTbl().getTblPr();
        if (tableProperties == null) {
            tableProperties = table.getCTTbl().addNewTblPr();
        }
        CTTblBorders borders = tableProperties.isSetTblBorders()
                ? tableProperties.getTblBorders()
                : tableProperties.addNewTblBorders();
        borders.addNewTop().setVal(STBorder.NONE);
        borders.addNewBottom().setVal(STBorder.NONE);
        borders.addNewLeft().setVal(STBorder.NONE);
        borders.addNewRight().setVal(STBorder.NONE);
        borders.addNewInsideH().setVal(STBorder.NONE);
        borders.addNewInsideV().setVal(STBorder.NONE);
    }

    void adicionarImagemMineruAoWord(XWPFDocument document, Path imagePath, double widthInches) {
        try {
            XWPFParagraph paragraph = document.createParagraph();
            paragraph.setAlignment(ParagraphAlignment.CENTER);
            adicionarImagemMineruAoTrecho(paragraph.createRun(), imagePath, widthInches);
        } catch (Exception ignored) {
            // A conversão deve continuar mesmo se uma imagem recortada vier ilegível.
        }
    }

    void adicionarImagemMineruAoTrecho(XWPFRun run, Path imagePath, double widthInches) {
        try {
            BufferedImage image = ImageIO.read(imagePath.toFile());
            if (image == null) {
                return;
            }
            BufferedImage prepared = recortarImagemAtividade(image);
            int widthEmu = converterPolegadasParaEmu(widthInches);
            int heightEmu = (int) Math.round(widthEmu * prepared.getHeight() / Math.max(prepared.getWidth(), 1));
            ByteArrayOutputStream buffer = new ByteArrayOutputStream();
            ImageIO.write(prepared, "png", buffer);
            try (InputStream in = new java.io.ByteArrayInputStream(buffer.toByteArray())) {
                run.addPicture(in, XWPFDocument.PICTURE_TYPE_PNG, imagePath.getFileName().toString(), widthEmu, heightEmu);
            }
        } catch (Exception ignored) {
            // A conversão deve continuar mesmo se uma imagem recortada vier ilegível.
        }
    }

    void escreverPlanoDiagrama(XWPFDocument document, JsonNode layoutPlan) {
        for (JsonNode element : layoutPlan.path("elements")) {
            String text = element.path("text").asText("").trim();
            String type = element.path("type").asText("paragraph");
            if (text.isBlank() || "ignored".equals(type) || "image".equals(type)) {
                continue;
            }
            switch (type) {
                case "title" -> escreverParagrafo(document, text, "center", true, 18);
                case "heading" -> escreverParagrafo(document, text, "left", true, 14);
                case "instruction" -> escreverParagrafo(document, text, "left", true, 12);
                case "question" -> escreverParagrafo(document, text, "left", true, 12);
                case "alternative" -> escreverParagrafo(document, "   " + text, "left", false, 11);
                case "header_field" -> escreverParagrafo(document, text, "left", true, 11);
                case "word_bank", "table" -> escreverTabelaDiagramaComoTexto(document, text);
                case "answer_line" -> escreverParagrafo(document, "________________________________________", "left", false, 11);
                default -> escreverParagrafo(document, text, "left", false, 11);
            }
        }
    }

    void escreverBlocosEditaveis(XWPFDocument document, List<BlocoOcr> blocks, List<ItemTextoOcr> fallbackItems) {
        if (blocks == null || blocks.isEmpty()) {
            escreverItensOcr(document, fallbackItems);
            return;
        }

        for (BlocoOcr block : blocks) {
            if (block == null || block.text() == null || block.text().isBlank()) {
                continue;
            }
            switch (block.type() == null ? "paragraph" : block.type()) {
                case "title" -> escreverParagrafo(document, block.text(), block.alignment(), true, 18);
                case "heading" -> escreverParagrafo(document, block.text(), block.alignment(), true, 14);
                case "table" -> escreverBlocoComoTabela(document, block);
                default -> escreverLinhasBloco(document, block);
            }
        }
    }

    void escreverTextoVisualAlternativo(XWPFDocument document, List<BlocoOcr> blocks, List<ItemTextoOcr> fallbackItems) {
        XWPFParagraph separator = document.createParagraph();
        XWPFRun separatorRun = separator.createRun();
        separatorRun.setBold(true);
        separatorRun.setText("Texto reconhecido para edição");

        if (blocks != null && !blocks.isEmpty()) {
            escreverBlocosEditaveis(document, blocks, fallbackItems);
        } else {
            escreverItensOcr(document, fallbackItems);
        }
    }

    void escreverParagrafo(XWPFDocument document, String text, String alignment, boolean bold, int fontSize) {
        XWPFParagraph paragraph = document.createParagraph();
        paragraph.setAlignment(alinhamentoWord(alignment));
        XWPFRun run = paragraph.createRun();
        run.setBold(bold);
        run.setFontSize(Math.max(8, fontSize));
        escreverTextoComTabulacoes(run, text == null || text.isBlank() ? " " : text);
    }

    void adicionarImagem(XWPFDocument document, Path imagePath) throws IOException {
        BufferedImage image = ImageIO.read(imagePath.toFile());
        if (image == null) {
            return;
        }

        int maxWidthEmu = converterPolegadasParaEmu(6.5);
        int widthEmu = Units.pixelToEMU(image.getWidth());
        int heightEmu = Units.pixelToEMU(image.getHeight());
        if (widthEmu > maxWidthEmu) {
            double scale = maxWidthEmu / (double) widthEmu;
            widthEmu = maxWidthEmu;
            heightEmu = (int) Math.round(heightEmu * scale);
        }

        XWPFParagraph paragraph = document.createParagraph();
        XWPFRun run = paragraph.createRun();
        try (InputStream in = Files.newInputStream(imagePath)) {
            run.addPicture(in, tipoImagem(imagePath), imagePath.getFileName().toString(), widthEmu, heightEmu);
        } catch (InvalidFormatException error) {
            throw new IOException("Não foi possível inserir a imagem no Word.", error);
        }
    }

    private void escreverTabelaDiagramaComoTexto(XWPFDocument document, String text) {
        if (text.contains("\t") || text.contains("|")) {
            escreverBlocoComoTabela(document, new BlocoOcr("table", text, List.of(text), 0, 0, 0, 0, "left", 11, 0.8));
            return;
        }
        escreverParagrafo(document, text, "left", false, 11);
    }

    private void escreverLinhasBloco(XWPFDocument document, BlocoOcr block) {
        List<String> lines = block.lines() == null || block.lines().isEmpty()
                ? List.of(block.text())
                : block.lines();
        for (String line : lines) {
            if (line != null && !line.isBlank()) {
                escreverParagrafo(document, line, block.alignment(), false, tamanhoFonteWord(block));
            }
        }
    }

    private void escreverBlocoComoTabela(XWPFDocument document, BlocoOcr block) {
        List<String> lines = block.lines() == null || block.lines().isEmpty()
                ? List.of(block.text())
                : block.lines();

        List<String[]> rows = new ArrayList<>();
        int columns = 1;
        for (String line : lines) {
            String normalized = line == null ? "" : line.replace(" | ", "\t").replace("|", "\t");
            String[] cells = normalized.split("\\t");
            rows.add(cells);
            columns = Math.max(columns, cells.length);
        }

        if (columns <= 1) {
            for (String line : lines) {
                escreverParagrafo(document, line, block.alignment(), false, tamanhoFonteWord(block));
            }
            return;
        }

        XWPFTable table = document.createTable(rows.size(), columns);
        table.setWidth("100%");
        for (int rowIndex = 0; rowIndex < rows.size(); rowIndex++) {
            XWPFTableRow row = table.getRow(rowIndex);
            String[] cells = rows.get(rowIndex);
            for (int cellIndex = 0; cellIndex < columns; cellIndex++) {
                XWPFTableCell cell = row.getCell(cellIndex);
                String value = cellIndex < cells.length ? cells[cellIndex].trim() : "";
                XWPFParagraph paragraph = primeiroParagrafoCelula(cell);
                XWPFRun run = paragraph.createRun();
                run.setFontSize(tamanhoFonteWord(block));
                run.setText(value.isBlank() ? " " : value);
            }
        }
    }

    private void escreverItensOcr(XWPFDocument document, List<ItemTextoOcr> items) {
        if (items == null || items.isEmpty()) {
            XWPFParagraph paragraph = document.createParagraph();
            paragraph.createRun().setText("Nenhum texto reconhecido pelo OCR.");
            return;
        }

        for (String line : agruparLinhasOcr(items)) {
            if (line.isBlank()) {
                continue;
            }
            XWPFParagraph paragraph = document.createParagraph();
            XWPFRun run = paragraph.createRun();
            run.setText(line);
        }
    }

    private List<String> agruparLinhasOcr(List<ItemTextoOcr> items) {
        Map<Integer, List<ItemTextoOcr>> byLine = new LinkedHashMap<>();
        items.stream()
                .filter(item -> item != null && item.text() != null && !item.text().isBlank())
                .sorted(Comparator.comparingDouble(ItemTextoOcr::y).thenComparingDouble(ItemTextoOcr::x))
                .forEach(item -> byLine.computeIfAbsent(item.lineIndex(), ignored -> new ArrayList<>()).add(item));

        List<String> lines = new ArrayList<>();
        for (List<ItemTextoOcr> lineItems : byLine.values()) {
            String lineText = textoPrimeiraLinhaPreenchida(lineItems);
            if (!lineText.isBlank()) {
                lines.add(lineText);
                continue;
            }
            lineItems.sort(Comparator.comparingDouble(ItemTextoOcr::x));
            List<String> words = new ArrayList<>();
            for (ItemTextoOcr item : lineItems) {
                words.add(item.text());
            }
            lines.add(String.join(" ", words));
        }
        return lines;
    }

    private String textoPrimeiraLinhaPreenchida(List<ItemTextoOcr> items) {
        for (ItemTextoOcr item : items) {
            if (item.lineText() != null && !item.lineText().isBlank()) {
                return item.lineText().trim();
            }
        }
        return "";
    }

    private List<List<String>> interpretarTabelaHtml(String html) {
        List<List<String>> rows = new ArrayList<>();
        Matcher rowMatcher = Pattern.compile("<tr[^>]*>(.*?)</tr>", Pattern.CASE_INSENSITIVE | Pattern.DOTALL)
                .matcher(html == null ? "" : html);
        while (rowMatcher.find()) {
            List<String> cells = new ArrayList<>();
            Matcher cellMatcher = Pattern.compile("<t[dh][^>]*>(.*?)</t[dh]>", Pattern.CASE_INSENSITIVE | Pattern.DOTALL)
                    .matcher(rowMatcher.group(1));
            while (cellMatcher.find()) {
                cells.add(limparTextoHtml(cellMatcher.group(1)));
            }
            if (!cells.isEmpty()) {
                rows.add(cells);
            }
        }
        return rows;
    }

    private String limparTextoHtml(String html) {
        return (html == null ? "" : html)
                .replaceAll("<[^>]+>", "")
                .replace("&nbsp;", " ")
                .replace("&amp;", "&")
                .replace("&lt;", "<")
                .replace("&gt;", ">")
                .replace("&quot;", "\"")
                .trim();
    }

    private BufferedImage recortarImagemAtividade(BufferedImage source) {
        int minX = source.getWidth();
        int minY = source.getHeight();
        int maxX = -1;
        int maxY = -1;

        for (int y = 0; y < source.getHeight(); y++) {
            for (int x = 0; x < source.getWidth(); x++) {
                int rgb = source.getRGB(x, y);
                int alpha = (rgb >>> 24) & 0xff;
                if (alpha < 20) {
                    continue;
                }
                int luminance = luminancia(rgb);
                if (luminance < 248) {
                    minX = Math.min(minX, x);
                    minY = Math.min(minY, y);
                    maxX = Math.max(maxX, x);
                    maxY = Math.max(maxY, y);
                }
            }
        }

        if (maxX < minX || maxY < minY) {
            return source;
        }

        int pad = 8;
        minX = Math.max(0, minX - pad);
        minY = Math.max(0, minY - pad);
        maxX = Math.min(source.getWidth() - 1, maxX + pad);
        maxY = Math.min(source.getHeight() - 1, maxY + pad);

        int width = Math.max(1, maxX - minX + 1);
        int height = Math.max(1, maxY - minY + 1);
        return source.getSubimage(minX, minY, width, height);
    }

    private int tipoImagem(Path imagePath) {
        return switch (ArquivoArmazenadoService.extensaoDe(imagePath.getFileName().toString())) {
            case "jpg", "jpeg" -> XWPFDocument.PICTURE_TYPE_JPEG;
            case "gif" -> XWPFDocument.PICTURE_TYPE_GIF;
            case "bmp" -> XWPFDocument.PICTURE_TYPE_BMP;
            default -> XWPFDocument.PICTURE_TYPE_PNG;
        };
    }

    private ParagraphAlignment alinhamentoWord(String alignment) {
        return switch (alignment == null ? "left" : alignment) {
            case "center" -> ParagraphAlignment.CENTER;
            case "right" -> ParagraphAlignment.RIGHT;
            default -> ParagraphAlignment.LEFT;
        };
    }

    private int tamanhoFonteWord(BlocoOcr block) {
        int size = (int) Math.round(block.fontSizePt() <= 0 ? 11 : block.fontSizePt());
        return Math.max(9, Math.min(18, size));
    }

    private XWPFParagraph primeiroParagrafoCelula(XWPFTableCell cell) {
        return cell.getParagraphs().isEmpty()
                ? cell.addParagraph()
                : cell.getParagraphs().get(0);
    }

    private void escreverTextoComTabulacoes(XWPFRun run, String text) {
        String[] parts = text.split("\\t", -1);
        for (int index = 0; index < parts.length; index++) {
            if (index > 0) {
                run.addTab();
            }
            run.setText(parts[index].isBlank() ? " " : parts[index], index);
        }
    }

    private int converterPolegadasParaEmu(double inches) {
        return (int) Math.round(inches * EMU_PER_INCH);
    }

    private int luminancia(int rgb) {
        int red = (rgb >> 16) & 0xff;
        int green = (rgb >> 8) & 0xff;
        int blue = rgb & 0xff;
        return (red * 299 + green * 587 + blue * 114) / 1000;
    }
}
