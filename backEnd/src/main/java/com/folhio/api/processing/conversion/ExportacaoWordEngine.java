package com.folhio.api.processing.conversion;

import com.fasterxml.jackson.databind.JsonNode;
import com.folhio.api.service.ArquivoArmazenadoService;
import com.folhio.api.files.model.ArquivoArmazenado;
import com.folhio.api.processing.ocr.DiagramaIaClient;
import com.folhio.api.processing.ocr.DocumentoMineruClient;
import com.folhio.api.processing.ocr.DocumentoMineru;
import com.folhio.api.processing.ocr.ElementoMineru;
import com.folhio.api.processing.ocr.BlocoOcr;
import com.folhio.api.processing.ocr.DocumentoOcr;
import com.folhio.api.processing.ocr.ReconhecimentoPythonClient;
import com.folhio.api.progress.ProgressoTracker;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.poi.xwpf.usermodel.ParagraphAlignment;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.apache.poi.xwpf.usermodel.XWPFRun;
import org.apache.poi.xwpf.usermodel.XWPFTable;
import org.apache.poi.xwpf.usermodel.XWPFTableCell;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
public class ExportacaoWordEngine {

    private static final int DPI = 200;
    private static final int LAYOUT_DPI = 120;

    private final ArquivoArmazenadoService storageService;
    private final ReconhecimentoPythonClient ocrClient;
    private final DocumentoMineruClient mineruClient;
    private final DiagramaIaClient layoutAiClient;
    private final DocumentoWordWriter wordWriter = new DocumentoWordWriter();

    public ExportacaoWordEngine(ArquivoArmazenadoService storageService, ReconhecimentoPythonClient ocrClient, DocumentoMineruClient mineruClient, DiagramaIaClient layoutAiClient) {
        this.storageService = storageService;
        this.ocrClient = ocrClient;
        this.mineruClient = mineruClient;
        this.layoutAiClient = layoutAiClient;
    }

    public ResultadoConversao converterPdfParaWord(ArquivoArmazenado input) {
        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + ".docx";
        ArquivoArmazenado output = storageService.salvarSaida(outputName,
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document", target -> {
                    try (XWPFDocument document = new XWPFDocument();
                         OutputStream out = Files.newOutputStream(target)) {
                        if (mineruClient.estaDisponivel() && escreverComMineru(input, document)) {
                            ProgressoTracker.atualizar(0.92, "Montando Word editável");
                        } else {
                            String text = extrairTextoPdf(input);
                            if (temTextoSuficiente(text)) {
                                wordWriter.escreverTextoSimples(document, text);
                            } else {
                                escreverOcrPdfNoWord(input, document);
                            }
                        }
                        document.write(out);
                    }
                });
        return new ResultadoConversao(output, "PDF convertido para Word editável.");
    }

    public ResultadoConversao converterImagemParaWord(ArquivoArmazenado input) {
        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + ".docx";
        ArquivoArmazenado output = storageService.salvarSaida(outputName,
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document", target -> {
                    try (XWPFDocument document = new XWPFDocument();
                         OutputStream out = Files.newOutputStream(target)) {
                        if (mineruClient.estaDisponivel() && escreverComMineru(input, document)) {
                            ProgressoTracker.atualizar(0.92, "Montando Word editável");
                        } else {
                            ProgressoTracker.atualizar(0.20, "Rodando OCR na imagem");
                            DocumentoOcr ocrDocument;
                            try {
                                ocrDocument = ocrClient.reconhecerDocumento(input.path());
                            } catch (InterruptedException error) {
                                Thread.currentThread().interrupt();
                                throw new IOException("OCR interrompido.", error);
                            }
                            escreverDocumentoOcrNoWord(document, input.path(), ocrDocument);
                        }
                        document.write(out);
                    }
                });
        return new ResultadoConversao(output, "Imagem convertida para Word editável.");
    }

    public String extrairTextoPdf(ArquivoArmazenado input) throws IOException {
        try (PDDocument document = Loader.loadPDF(input.path().toFile())) {
            return new PDFTextStripper().getText(document);
        }
    }

    private boolean temTextoSuficiente(String text) {
        if (text == null) {
            return false;
        }
        String compact = text.replaceAll("\\s+", "");
        return compact.length() >= 20;
    }

    private boolean escreverComMineru(ArquivoArmazenado input, XWPFDocument document) throws IOException {
        try {
            ProgressoTracker.atualizar(0.18, "Analisando arquivo");
            DocumentoMineru mineruDocument = mineruClient.analisar(input.path());
            escreverDocumentoMineruNoWord(document, mineruDocument, input.path());
            return true;
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt();
            throw new IOException("OCR interrompido.", error);
        } catch (Exception error) {
            ProgressoTracker.atualizar(0.20, "Usando conversão alternativa");
            return false;
        }
    }

    private void escreverDocumentoMineruNoWord(XWPFDocument document, DocumentoMineru mineruDocument, Path sourcePath) throws IOException {
        List<List<ElementoMineru>> pages = mineruDocument == null ? List.of() : mineruDocument.pages();
        if (pages == null || pages.isEmpty()) {
            wordWriter.escreverParagrafo(document, "Nenhum texto reconhecido.", "left", false, 11);
            return;
        }
        List<List<LinhaHorizontal>> pageLines = detectarLinhasHorizontais(sourcePath, pages.size());

        for (int pageIndex = 0; pageIndex < pages.size(); pageIndex++) {
            ProgressoTracker.atualizar(0.65 + (pageIndex * 0.25 / Math.max(pages.size(), 1)), "Montando página " + (pageIndex + 1));
            List<ElementoMineru> elements = pages.get(pageIndex);
            List<LinhaHorizontal> lines = pageIndex < pageLines.size() ? pageLines.get(pageIndex) : List.of();
            for (int index = 0; index < elements.size(); index++) {
                ElementoMineru element = elements.get(index);
                if (ehImagemExercicio(element)) {
                    List<ElementoMineru> images = new ArrayList<>();
                    while (index < elements.size() && ehImagemExercicio(elements.get(index))) {
                        images.add(elements.get(index));
                        index++;
                    }
                    index--;
                    escreverGradeImagensExercicio(document, images, lines);
                    continue;
                }
                escreverElementoMineruNoWord(document, element);
            }
            if (pageIndex < pages.size() - 1) {
                document.createParagraph().createRun().addBreak(org.apache.poi.xwpf.usermodel.BreakType.PAGE);
            }
        }
    }

    private void escreverElementoMineruNoWord(XWPFDocument document, ElementoMineru element) throws IOException {
        if (element == null) {
            return;
        }

        String type = element.type() == null ? "" : element.type();
        if ("table".equals(type) && element.temTabela()) {
            wordWriter.escreverTabelaHtml(document, element.html());
            return;
        }
        if ("image".equals(type) && element.temImagem()) {
            if (!ehImagemDecorativaSuperior(element)) {
                wordWriter.adicionarImagemMineruAoWord(document, element.imagePath(), 1.65);
            }
            return;
        }
        if (element.temTexto()) {
            boolean title = "title".equals(type);
            wordWriter.escreverParagrafo(document, element.text(), title ? "center" : "left", title, title ? 14 : 11);
        }
    }

    private boolean ehImagemDecorativaSuperior(ElementoMineru element) {
        return topoCaixa(element) < 150 && larguraCaixa(element) < 180 && alturaCaixa(element) < 180;
    }

    private boolean ehImagemExercicio(ElementoMineru element) {
        return element != null && "image".equals(element.type()) && element.temImagem() && !ehImagemDecorativaSuperior(element);
    }

    private void escreverGradeImagensExercicio(XWPFDocument document, List<ElementoMineru> images, List<LinhaHorizontal> realLines) {
        if (images == null || images.isEmpty()) {
            return;
        }
        List<ElementoMineru> sorted = new ArrayList<>(images);
        sorted.sort(Comparator.comparingDouble(this::topoCaixa).thenComparingDouble(this::esquerdaCaixa));

        int columns = sorted.size() >= 8 ? 4 : 2;
        XWPFTable table = document.createTable((int) Math.ceil(sorted.size() / (double) columns), columns);
        table.setWidth("100%");
        wordWriter.ocultarBordasTabela(table);
        double imageWidth = columns == 4 ? 1.05 : 1.55;

        for (int index = 0; index < sorted.size(); index++) {
            XWPFTableCell cell = table.getRow(index / columns).getCell(index % columns);
            XWPFParagraph paragraph = cell.getParagraphs().isEmpty()
                    ? cell.addParagraph()
                    : cell.getParagraphs().get(0);
            paragraph.setAlignment(ParagraphAlignment.CENTER);
            XWPFRun imageRun = paragraph.createRun();
            ElementoMineru image = sorted.get(index);
            wordWriter.adicionarImagemMineruAoTrecho(imageRun, image.imagePath(), imageWidth);
            linhaRespostaDetectadaAbaixo(image, realLines).ifPresent(line -> escreverLinhaRespostaDetectada(cell, line));
        }
        document.createParagraph();
    }

    private void escreverLinhaRespostaDetectada(XWPFTableCell cell, LinhaHorizontal line) {
        XWPFParagraph lineParagraph = cell.addParagraph();
        lineParagraph.setAlignment(ParagraphAlignment.CENTER);
        XWPFRun lineRun = lineParagraph.createRun();
        lineRun.setFontSize(10);
        int length = (int) limitar(Math.round(line.largura() / 7.0), 8, 32);
        lineRun.setText("_".repeat(length));
    }

    private java.util.Optional<LinhaHorizontal> linhaRespostaDetectadaAbaixo(ElementoMineru image, List<LinhaHorizontal> lines) {
        if (lines == null || lines.isEmpty()) {
            return java.util.Optional.empty();
        }

        double bottom = topoCaixa(image) + alturaCaixa(image);
        double left = esquerdaCaixa(image);
        double right = left + larguraCaixa(image);
        return lines.stream()
                .filter(line -> line.top() >= bottom + 4 && line.top() <= bottom + 55)
                .filter(line -> sobreposicaoHorizontal(line.left(), line.right(), left, right) >= Math.min(larguraCaixa(image) * 0.35, line.largura() * 0.75))
                .max(Comparator.comparingDouble(LinhaHorizontal::largura));
    }

    private double sobreposicaoHorizontal(double leftA, double rightA, double leftB, double rightB) {
        return Math.max(0, Math.min(rightA, rightB) - Math.max(leftA, leftB));
    }

    private List<List<LinhaHorizontal>> detectarLinhasHorizontais(Path sourcePath, int expectedPages) {
        if (sourcePath == null || !sourcePath.getFileName().toString().toLowerCase().endsWith(".pdf")) {
            return List.of();
        }

        List<List<LinhaHorizontal>> pages = new ArrayList<>();
        try (PDDocument document = Loader.loadPDF(sourcePath.toFile())) {
            PDFRenderer renderer = new PDFRenderer(document);
            int total = Math.min(document.getNumberOfPages(), expectedPages);
            for (int pageIndex = 0; pageIndex < total; pageIndex++) {
                BufferedImage pageImage = renderer.renderImageWithDPI(pageIndex, LAYOUT_DPI);
                PDRectangle mediaBox = document.getPage(pageIndex).getMediaBox();
                pages.add(examinarLinhasHorizontais(pageImage, mediaBox));
            }
        } catch (Exception ignored) {
            return List.of();
        }
        return pages;
    }

    private List<LinhaHorizontal> examinarLinhasHorizontais(BufferedImage image, PDRectangle mediaBox) {
        List<LinhaHorizontal> lines = new ArrayList<>();
        double scaleX = image.getWidth() / mediaBox.getWidth();
        double scaleY = image.getHeight() / mediaBox.getHeight();
        int minRun = Math.max(30, image.getWidth() / 18);

        for (int y = 0; y < image.getHeight(); y++) {
            int runStart = -1;
            for (int x = 0; x < image.getWidth(); x++) {
                boolean dark = luminancia(image.getRGB(x, y)) < 90;
                if (dark && runStart < 0) {
                    runStart = x;
                }
                if ((!dark || x == image.getWidth() - 1) && runStart >= 0) {
                    int runEnd = dark && x == image.getWidth() - 1 ? x : x - 1;
                    if (runEnd - runStart + 1 >= minRun) {
                        lines.add(new LinhaHorizontal(runStart / scaleX, y / scaleY, runEnd / scaleX, (y + 1) / scaleY));
                    }
                    runStart = -1;
                }
            }
        }
        return mesclarLinhasHorizontaisProximas(lines);
    }

    private List<LinhaHorizontal> mesclarLinhasHorizontaisProximas(List<LinhaHorizontal> rawLines) {
        List<LinhaHorizontal> merged = new ArrayList<>();
        for (LinhaHorizontal line : rawLines) {
            if (!merged.isEmpty()) {
                LinhaHorizontal previous = merged.get(merged.size() - 1);
                boolean sameStroke = Math.abs(previous.top() - line.top()) <= 2
                        && sobreposicaoHorizontal(previous.left(), previous.right(), line.left(), line.right()) > 10;
                if (sameStroke) {
                    merged.set(merged.size() - 1, new LinhaHorizontal(
                            Math.min(previous.left(), line.left()),
                            Math.min(previous.top(), line.top()),
                            Math.max(previous.right(), line.right()),
                            Math.max(previous.bottom(), line.bottom())
                    ));
                    continue;
                }
            }
            merged.add(line);
        }
        return merged.stream()
                .filter(line -> line.largura() >= 35)
                .toList();
    }

    private int luminancia(int rgb) {
        int red = (rgb >> 16) & 0xff;
        int green = (rgb >> 8) & 0xff;
        int blue = rgb & 0xff;
        return (red * 299 + green * 587 + blue * 114) / 1000;
    }

    private double esquerdaCaixa(ElementoMineru element) {
        return element.bbox() == null || element.bbox().isEmpty() ? 0 : element.bbox().get(0);
    }

    private double topoCaixa(ElementoMineru element) {
        return element.bbox() == null || element.bbox().size() < 2 ? 0 : element.bbox().get(1);
    }

    private double larguraCaixa(ElementoMineru element) {
        return element.bbox() == null || element.bbox().size() < 3 ? 0 : Math.max(0, element.bbox().get(2) - element.bbox().get(0));
    }

    private double alturaCaixa(ElementoMineru element) {
        return element.bbox() == null || element.bbox().size() < 4 ? 0 : Math.max(0, element.bbox().get(3) - element.bbox().get(1));
    }

    private record LinhaHorizontal(double left, double top, double right, double bottom) {
        double largura() {
            return Math.max(0, right - left);
        }
    }

    private void escreverOcrPdfNoWord(ArquivoArmazenado input, XWPFDocument wordDocument) throws IOException {
        Path tempDir = Files.createTempDirectory("folhio-pdf-ocr-");
        try (PDDocument pdfDocument = Loader.loadPDF(input.path().toFile())) {
            PDFRenderer renderer = new PDFRenderer(pdfDocument);
            int pages = pdfDocument.getNumberOfPages();
            for (int index = 0; index < pages; index++) {
                ProgressoTracker.atualizar(
                        0.15 + (index * 0.75 / Math.max(pages, 1)),
                        "OCR página " + (index + 1) + " de " + pages
                );
                BufferedImage image = renderer.renderImageWithDPI(index, DPI);
                Path imagePath = tempDir.resolve("página-" + (index + 1) + ".png");
                ImageIO.write(image, "png", imagePath.toFile());
                DocumentoOcr ocrDocument;
                try {
                    ocrDocument = ocrClient.reconhecerDocumento(imagePath);
                } catch (InterruptedException error) {
                    Thread.currentThread().interrupt();
                    throw new IOException("OCR interrompido.", error);
                }
                escreverDocumentoOcrNoWord(wordDocument, imagePath, ocrDocument);
                if (index < pages - 1) {
                    wordDocument.createParagraph().createRun().addBreak(org.apache.poi.xwpf.usermodel.BreakType.PAGE);
                }
            }
        }
    }

    private void escreverDocumentoOcrNoWord(XWPFDocument document, Path imagePath, DocumentoOcr ocrDocument) throws IOException {
        JsonNode layoutPlan = analisarDiagrama(imagePath, ocrDocument);
        if (temElementosDiagrama(layoutPlan)) {
            String layoutMode = layoutPlan.path("recommendedMode").asText("editable");
            if ("visual".equalsIgnoreCase(layoutMode)) {
                wordWriter.adicionarImagem(document, imagePath);
                wordWriter.escreverPlanoDiagrama(document, layoutPlan);
                return;
            }
            wordWriter.escreverPlanoDiagrama(document, layoutPlan);
            return;
        }

        String mode = ocrDocument == null ? "editable" : ocrDocument.recommendedMode();
        List<BlocoOcr> blocks = ocrDocument == null ? List.of() : ocrDocument.blocks();

        if ("visual".equalsIgnoreCase(mode)) {
            wordWriter.adicionarImagem(document, imagePath);
            wordWriter.escreverTextoVisualAlternativo(document, blocks, ocrDocument == null ? List.of() : ocrDocument.items());
            return;
        }

        wordWriter.escreverBlocosEditaveis(document, blocks, ocrDocument == null ? List.of() : ocrDocument.items());
    }

    private JsonNode analisarDiagrama(Path imagePath, DocumentoOcr ocrDocument) {
        if (ocrDocument == null || !layoutAiClient.estaDisponivel()) {
            return null;
        }
        try {
            ProgressoTracker.atualizar(0.72, "Organizando layout com IA local");
            return layoutAiClient.analisar(imagePath, ocrDocument);
        } catch (Exception ignored) {
            return null;
        }
    }

    private boolean temElementosDiagrama(JsonNode layoutPlan) {
        return layoutPlan != null && layoutPlan.path("elements").isArray() && layoutPlan.path("elements").size() > 0;
    }

    private double limitar(double value, double min, double max) {
        return Math.max(min, Math.min(max, value));
    }
}

