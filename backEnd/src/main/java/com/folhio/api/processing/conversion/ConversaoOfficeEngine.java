package com.folhio.api.processing.conversion;

import com.folhio.api.processing.conversion.util.RenderizacaoPdfUtils;
import com.folhio.api.service.ArquivoArmazenadoService;
import com.folhio.api.files.model.ArquivoArmazenado;
import com.folhio.api.progress.ProgressoTracker;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.graphics.image.LosslessFactory;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.apache.poi.xslf.usermodel.XMLSlideShow;
import org.apache.poi.xslf.usermodel.XSLFShape;
import org.apache.poi.xslf.usermodel.XSLFSlide;
import org.apache.poi.xslf.usermodel.XSLFTextShape;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class ConversaoOfficeEngine {

    private static final int DPI = 200;

    private final ArquivoArmazenadoService storageService;
    private final ExportacaoWordEngine wordExportEngine;
    private final com.folhio.api.processing.conversion.office.ConversaoLibreOfficeService libreOffice;

    public ConversaoOfficeEngine(
            ArquivoArmazenadoService storageService,
            ExportacaoWordEngine wordExportEngine,
            com.folhio.api.processing.conversion.office.ConversaoLibreOfficeService libreOffice
    ) {
        this.storageService = storageService;
        this.wordExportEngine = wordExportEngine;
        this.libreOffice = libreOffice;
    }

    public ResultadoConversao converterPdfParaImagens(ArquivoArmazenado input, String format, String mimeType) {
        String baseName = ArquivoArmazenadoService.semExtensao(input.originalFileName());
        try (PDDocument document = Loader.loadPDF(input.path().toFile())) {
            int pageCount = document.getNumberOfPages();
            if (pageCount == 1) {
                ArquivoArmazenado output = storageService.salvarSaida(baseName + "." + format, mimeType, target -> {
                    PDFRenderer renderer = new PDFRenderer(document);
                    BufferedImage image = renderer.renderImageWithDPI(0, DPI);
                    ImageIO.write(image, format, target.toFile());
                });
                return new ResultadoConversao(output, "PDF convertido para imagem " + format.toUpperCase() + ".");
            }
        } catch (IOException error) {
            throw new IllegalStateException("Não foi possível ler o PDF.", error);
        }

        ArquivoArmazenado output = storageService.salvarSaida(baseName + "-" + format + ".zip", "application/zip", target -> {
            try (PDDocument document = Loader.loadPDF(input.path().toFile());
                 ZipOutputStream zip = new ZipOutputStream(Files.newOutputStream(target))) {
                PDFRenderer renderer = new PDFRenderer(document);
                for (int i = 0; i < document.getNumberOfPages(); i++) {
                    ProgressoTracker.atualizar(0.10 + (i * 0.80 / document.getNumberOfPages()), "Convertendo página " + (i + 1));
                    BufferedImage image = renderer.renderImageWithDPI(i, DPI);
                    ByteArrayOutputStream buffer = new ByteArrayOutputStream();
                    ImageIO.write(image, format, buffer);
                    zip.putNextEntry(new ZipEntry(baseName + "_page_" + (i + 1) + "." + format));
                    zip.write(buffer.toByteArray());
                    zip.closeEntry();
                }
                ProgressoTracker.atualizar(0.94, "Compactando imagens");
            }
        });

        return new ResultadoConversao(output, "PDF convertido para imagens " + format.toUpperCase() + " em ZIP.");
    }

    public ResultadoConversao converterImagemParaPdf(ArquivoArmazenado input) {
        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + ".pdf";
        ArquivoArmazenado output = storageService.salvarSaida(outputName, "application/pdf", target -> {
            BufferedImage image = RenderizacaoPdfUtils.lerImagemComOrientacao(input.path());
            if (image == null) {
                throw new IOException("Não foi possível ler a imagem.");
            }

            try (PDDocument document = new PDDocument()) {
                PDPage page = new PDPage(new PDRectangle(image.getWidth(), image.getHeight()));
                document.addPage(page);
                PDImageXObject pdImage = LosslessFactory.createFromImage(document, image);
                try (PDPageContentStream stream = new PDPageContentStream(document, page)) {
                    stream.drawImage(pdImage, 0, 0, image.getWidth(), image.getHeight());
                }
                document.save(target.toFile());
            }
        });

        return new ResultadoConversao(output, "Imagem convertida para PDF.");
    }

    public ResultadoConversao converterPdfParaExcel(ArquivoArmazenado input) {
        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + ".xlsx";
        ArquivoArmazenado output = storageService.salvarSaida(outputName,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", target -> {
                    String text = wordExportEngine.extrairTextoPdf(input);
                    try (XSSFWorkbook workbook = new XSSFWorkbook();
                         OutputStream out = Files.newOutputStream(target)) {
                        XSSFSheet sheet = workbook.createSheet("Conversão");
                        String[] lines = text.split("\\R");
                        for (int i = 0; i < lines.length; i++) {
                            XSSFRow row = sheet.createRow(i);
                            row.createCell(0).setCellValue(lines[i]);
                        }
                        sheet.autoSizeColumn(0);
                        workbook.write(out);
                    }
                });
        return new ResultadoConversao(output, "PDF convertido para Excel com o texto extraido.");
    }

    public ResultadoConversao converterWordParaPdf(ArquivoArmazenado input) {
        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + ".pdf";
        if (podeUsarLibreOffice(input)) {
            try {
                ArquivoArmazenado output = storageService.salvarSaida(outputName, "application/pdf", target -> {
                    libreOffice.converterParaPdf(input.path(), input.originalFileName(), target);
                });
                return new ResultadoConversao(output, "Word convertido para PDF com LibreOffice.");
            } catch (RuntimeException ignored) {
                // Mantem o fallback textual quando LibreOffice nao estiver disponivel ou travar.
            }
        }
        ArquivoArmazenado output = storageService.salvarSaida(outputName, "application/pdf", target -> {
            StringBuilder text = new StringBuilder();
            try (InputStream in = Files.newInputStream(input.path());
                 XWPFDocument document = new XWPFDocument(in)) {
                for (XWPFParagraph paragraph : document.getParagraphs()) {
                    text.append(paragraph.getText()).append('\n');
                }
            }
            RenderizacaoPdfUtils.escreverPdfTexto(target, text.toString(), "");
        });
        return new ResultadoConversao(output, "Word convertido para PDF.");
    }

    private boolean podeUsarLibreOffice(ArquivoArmazenado input) {
        String extension = ArquivoArmazenadoService.extensaoDe(input.originalFileName()).toLowerCase(Locale.ROOT);
        return "doc".equals(extension) || "docx".equals(extension);
    }

    public ResultadoConversao converterExcelParaPdf(ArquivoArmazenado input) {
        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + ".pdf";
        ArquivoArmazenado output = storageService.salvarSaida(outputName, "application/pdf", target -> {
            StringBuilder text = new StringBuilder();
            try (InputStream in = Files.newInputStream(input.path());
                 XSSFWorkbook workbook = new XSSFWorkbook(in)) {
                for (int sheetIndex = 0; sheetIndex < workbook.getNumberOfSheets(); sheetIndex++) {
                    XSSFSheet sheet = workbook.getSheetAt(sheetIndex);
                    text.append("Aba: ").append(sheet.getSheetName()).append('\n');
                    sheet.forEach(row -> {
                        for (int cellIndex = 0; cellIndex < Math.max(row.getLastCellNum(), 0); cellIndex++) {
                            if (cellIndex > 0) {
                                text.append(" | ");
                            }
                            text.append(row.getCell(cellIndex) == null ? "" : row.getCell(cellIndex).toString());
                        }
                        text.append('\n');
                    });
                    text.append('\n');
                }
            }
            RenderizacaoPdfUtils.escreverPdfTexto(target, text.toString(), "Planilha convertida");
        });
        return new ResultadoConversao(output, "Excel convertido para PDF.");
    }

    public ResultadoConversao converterPptParaPdf(ArquivoArmazenado input) {
        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + ".pdf";
        ArquivoArmazenado output = storageService.salvarSaida(outputName, "application/pdf", target -> {
            StringBuilder text = new StringBuilder();
            try (InputStream in = Files.newInputStream(input.path());
                 XMLSlideShow slideShow = new XMLSlideShow(in)) {
                int slideNumber = 1;
                for (XSLFSlide slide : slideShow.getSlides()) {
                    text.append("Slide ").append(slideNumber++).append('\n');
                    for (XSLFShape shape : slide.getShapes()) {
                        if (shape instanceof XSLFTextShape textShape) {
                            text.append(textShape.getText()).append('\n');
                        }
                    }
                    text.append('\n');
                }
            }
            RenderizacaoPdfUtils.escreverPdfTexto(target, text.toString(), "Apresentação convertida");
        });
        return new ResultadoConversao(output, "PPT convertido para PDF.");
    }
}
