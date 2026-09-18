package com.folhio.api.processing.conversion;

import com.folhio.api.processing.conversion.util.RenderizacaoPdfUtils;
import com.folhio.api.service.ArquivoArmazenadoService;
import com.folhio.api.files.model.ArquivoArmazenado;
import com.folhio.api.progress.ProgressoTracker;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.multipdf.PDFMergerUtility;
import org.apache.pdfbox.multipdf.Splitter;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.pdmodel.graphics.image.JPEGFactory;
import org.apache.pdfbox.pdmodel.graphics.image.LosslessFactory;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.geom.AffineTransform;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Service
public class EdicaoPdfEngine {

    private static final int LAYOUT_DPI = 120;
    private static final int POSTER_TILE_DPI = 160;
    private static final int POSTER_MIN_SOURCE_DPI = 240;
    private static final int POSTER_MAX_SOURCE_DPI = 600;
    private static final float POSTER_JPEG_QUALITY = 0.88f;

    private final ArquivoArmazenadoService storageService;

    public EdicaoPdfEngine(ArquivoArmazenadoService storageService) {
        this.storageService = storageService;
    }

    public ResultadoConversao mesclarPdfs(List<ArquivoArmazenado> inputs) {
        if (inputs == null || inputs.isEmpty()) {
            throw new IllegalArgumentException("Informe pelo menos um PDF para mesclar.");
        }

        ArquivoArmazenado output = storageService.salvarSaida("pdfs-mesclados.pdf", "application/pdf", target -> {
            ProgressoTracker.atualizar(0.20, "Mesclando PDFs");
            PDFMergerUtility merger = new PDFMergerUtility();
            merger.setDestinationFileName(target.toString());
            for (int index = 0; index < inputs.size(); index++) {
                ArquivoArmazenado input = inputs.get(index);
                merger.addSource(input.path().toFile());
                ProgressoTracker.atualizar(0.20 + ((index + 1) * 0.50 / inputs.size()), "Adicionando PDF " + (index + 1));
            }
            merger.mergeDocuments(null);
            ProgressoTracker.atualizar(0.90, "Salvando PDF final");
        });

        return new ResultadoConversao(output, "PDFs mesclados com sucesso.");
    }

    public ResultadoConversao extrairPaginas(ArquivoArmazenado input, List<Integer> pagesToKeep) {
        if (pagesToKeep == null || pagesToKeep.isEmpty()) {
            throw new IllegalArgumentException("Informe as páginas para manter.");
        }

        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + "-páginas.pdf";
        ArquivoArmazenado output = storageService.salvarSaida(outputName, "application/pdf", target -> {
            try (PDDocument original = Loader.loadPDF(input.path().toFile());
                 PDDocument extracted = new PDDocument()) {
                int totalPages = original.getNumberOfPages();
                Set<Integer> normalizedPages = normalizarPaginas(pagesToKeep, totalPages);
                int current = 0;
                for (int pageNumber : normalizedPages) {
                    adicionarPagina(original, extracted, pageNumber);
                    current++;
                    ProgressoTracker.atualizar(0.20 + (current * 0.70 / normalizedPages.size()), "Extraindo página " + pageNumber);
                }
                extracted.save(target.toFile());
            }
        });

        return new ResultadoConversao(output, "Páginas extraidas com sucesso.");
    }

    public ResultadoConversao organizarPaginasPdfPorFolha(ArquivoArmazenado input, int pagesPerSheet, String orientation, int pageMargin) {
        if (pagesPerSheet != 2 && pagesPerSheet != 4 && pagesPerSheet != 6) {
            throw new IllegalArgumentException("pagesPerSheet deve ser 2, 4 ou 6.");
        }

        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + "-" + pagesPerSheet + "porfolha.pdf";
        ArquivoArmazenado output = storageService.salvarSaida(outputName, "application/pdf", target -> {
            try (PDDocument original = Loader.loadPDF(input.path().toFile());
                 PDDocument result = new PDDocument()) {
                PDFRenderer renderer = new PDFRenderer(original);
                int totalPages = original.getNumberOfPages();
                int totalSheets = Math.max(1, (int) Math.ceil(totalPages / (double) pagesPerSheet));
                int currentSheet = 0;

                for (int pageIndex = 0; pageIndex < totalPages; pageIndex += pagesPerSheet) {
                    ProgressoTracker.atualizar(0.10 + (currentSheet * 0.80 / totalSheets), "Renderizando folha " + (currentSheet + 1) + " de " + totalSheets);
                    PDRectangle pageSize = "portrait".equalsIgnoreCase(orientation)
                            ? PDRectangle.A4
                            : new PDRectangle(PDRectangle.A4.getHeight(), PDRectangle.A4.getWidth());
                    PDPage page = new PDPage(pageSize);
                    result.addPage(page);

                    int columns = colunasPaginasPorFolha(pagesPerSheet, orientation);
                    int rows = (int) Math.ceil(pagesPerSheet / (double) columns);
                    float margin = Math.max(0, pageMargin);
                    float gap = Math.max(0, pageMargin);
                    float cellWidth = (pageSize.getWidth() - (margin * 2) - (gap * (columns - 1))) / columns;
                    float cellHeight = (pageSize.getHeight() - (margin * 2) - (gap * (rows - 1))) / rows;

                    try (PDPageContentStream stream = new PDPageContentStream(result, page)) {
                        for (int offset = 0; offset < pagesPerSheet && pageIndex + offset < totalPages; offset++) {
                            BufferedImage rendered = renderer.renderImageWithDPI(pageIndex + offset, LAYOUT_DPI);
                            PDImageXObject image = RenderizacaoPdfUtils.converterImagemParaImagemPdf(rendered, result);
                            int column = offset % columns;
                            int row = offset / columns;
                            float xCell = margin + column * (cellWidth + gap);
                            float yCell = pageSize.getHeight() - margin - ((row + 1) * cellHeight) - (row * gap);
                            float scale = Math.min(cellWidth / rendered.getWidth(), cellHeight / rendered.getHeight());
                            float imageWidth = rendered.getWidth() * scale;
                            float imageHeight = rendered.getHeight() * scale;
                            float x = xCell + (cellWidth - imageWidth) / 2;
                            float y = yCell + (cellHeight - imageHeight) / 2;
                            stream.drawImage(image, x, y, imageWidth, imageHeight);
                        }
                    }
                    currentSheet++;
                    ProgressoTracker.atualizar(0.10 + (currentSheet * 0.80 / totalSheets), "Folha " + currentSheet + " pronta");
                }

                ProgressoTracker.atualizar(0.94, "Salvando PDF reorganizado");
                result.save(target.toFile());
            }
        });

        return new ResultadoConversao(output, "PDF reorganizado em " + pagesPerSheet + " páginas por folha.");
    }

    private int colunasPaginasPorFolha(int pagesPerSheet, String orientation) {
        boolean portrait = "portrait".equalsIgnoreCase(orientation);
        if (pagesPerSheet == 2) {
            return portrait ? 1 : 2;
        }
        if (pagesPerSheet == 6) {
            return portrait ? 2 : 3;
        }
        return 2;
    }

    public ResultadoConversao dividirPdfEmPoster(ArquivoArmazenado input, int sheetsWide, int sheetsTall, int pageMargin) {
        if (sheetsWide < 1 || sheetsWide > 5 || sheetsTall < 1 || sheetsTall > 5) {
            throw new IllegalArgumentException("Use de 1 até 5 folhas A4 na largura e na altura.");
        }
        int totalParts = sheetsWide * sheetsTall;
        if (totalParts < 2 || totalParts > 25) {
            throw new IllegalArgumentException("O pôster deve gerar entre 2 e 25 folhas A4.");
        }

        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName())
                + "-poster-" + sheetsWide + "x" + sheetsTall + ".pdf";
        ArquivoArmazenado output = storageService.salvarSaida(outputName, "application/pdf", target -> {
            try (PDDocument result = new PDDocument()) {
                BufferedImage source = lerOrigemPoster(input, sheetsWide, sheetsTall);
                PDRectangle pageSize = tamanhoPaginaPosterPara(source, sheetsWide, sheetsTall);
                float margin = margemPosterSegura(pageSize, pageMargin);
                float availableWidth = pageSize.getWidth() - (margin * 2);
                float availableHeight = pageSize.getHeight() - (margin * 2);
                int tilePixelWidth = converterPontosParaPixels(availableWidth, POSTER_TILE_DPI);
                int tilePixelHeight = converterPontosParaPixels(availableHeight, POSTER_TILE_DPI);
                AjustePoster fit = ajustePoster(source, tilePixelWidth * sheetsWide, tilePixelHeight * sheetsTall);

                for (int row = 0; row < sheetsTall; row++) {
                    for (int column = 0; column < sheetsWide; column++) {
                        int index = row * sheetsWide + column;
                        ProgressoTracker.atualizar(
                                0.18 + (index * 0.68 / totalParts),
                                "Preparando parte " + (index + 1) + " de " + totalParts
                        );

                        BufferedImage tile = criarFolhaPoster(
                                source,
                                column,
                                row,
                                tilePixelWidth,
                                tilePixelHeight,
                                fit
                        );

                        PDPage page = new PDPage(pageSize);
                        result.addPage(page);
                        PDImageXObject image = JPEGFactory.createFromImage(result, tile, POSTER_JPEG_QUALITY);

                        try (PDPageContentStream stream = new PDPageContentStream(result, page)) {
                            stream.drawImage(image, margin, margin, availableWidth, availableHeight);
                        }
                    }
                }

                ProgressoTracker.atualizar(0.94, "Salvando PDF em partes");
                result.save(target.toFile());
            }
        });

        return new ResultadoConversao(output, "PDF dividido em " + totalParts + " folhas A4 para pôster.");
    }

    public ResultadoConversao compactarPdf(ArquivoArmazenado input, String compressionLevel) {
        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + "-compactado.pdf";
        ArquivoArmazenado output = storageService.salvarSaida(outputName, "application/pdf", target -> {
            PredefinicaoCompressao preset = PredefinicaoCompressao.de(compressionLevel);
            try (PDDocument original = Loader.loadPDF(input.path().toFile());
                 PDDocument result = new PDDocument()) {
                PDFRenderer renderer = new PDFRenderer(original);
                int totalPages = original.getNumberOfPages();
                if (totalPages == 0) {
                    throw new IOException("O PDF não possui páginas para comprimir.");
                }

                for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
                    ProgressoTracker.atualizar(
                            0.12 + (pageIndex * 0.78 / Math.max(totalPages, 1)),
                            "Comprimindo página " + (pageIndex + 1) + " de " + totalPages
                    );

                    PDPage originalPage = original.getPage(pageIndex);
                    PDRectangle pageSize = RenderizacaoPdfUtils.tamanhoPaginaExibida(originalPage);
                    BufferedImage rendered = renderer.renderImageWithDPI(pageIndex, preset.dpi());
                    PDImageXObject image = JPEGFactory.createFromImage(result, RenderizacaoPdfUtils.converterParaRgb(rendered), preset.quality());

                    PDPage page = new PDPage(pageSize);
                    result.addPage(page);
                    try (PDPageContentStream stream = new PDPageContentStream(result, page)) {
                        stream.drawImage(image, 0, 0, pageSize.getWidth(), pageSize.getHeight());
                    }
                }

                ProgressoTracker.atualizar(0.94, "Salvando PDF compactado");
                result.save(target.toFile());
            }
        });
        return new ResultadoConversao(output, "PDF compactado no nivel " + compressionLevel + ".");
    }

    public ResultadoConversao adicionarIdentificacaoAtividade(
            ArquivoArmazenado input,
            String schoolName,
            String subject,
            String className,
            String teacherName,
            String dateText,
            boolean showStudentNameLine,
            boolean showGradeLine,
            boolean applyToAllPages
    ) {
        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + "-identificado.pdf";
        ArquivoArmazenado output = storageService.salvarSaida(outputName, "application/pdf", target -> {
            try (PDDocument document = Loader.loadPDF(input.path().toFile())) {
                PDType1Font regularFont = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
                PDType1Font boldFont = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
                int pageIndex = 0;
                for (PDPage page : document.getPages()) {
                    if (!applyToAllPages && pageIndex > 0) {
                        break;
                    }
                    PDRectangle box = page.getMediaBox();
                    try (PDPageContentStream stream = new PDPageContentStream(document, page, PDPageContentStream.AppendMode.APPEND, true, true)) {
                        float y = box.getHeight() - 24;
                        if (!schoolName.isBlank()) {
                            RenderizacaoPdfUtils.escreverLinhaPdf(stream, boldFont, 10, schoolName, y);
                            y -= 16;
                        }
                        String lineOne = juntarPreenchidos("  |  ",
                                rotulado("Disciplina", subject),
                                rotulado("Turma", className),
                                rotulado("Professor", teacherName)
                        );
                        if (!lineOne.isBlank()) {
                            RenderizacaoPdfUtils.escreverLinhaPdf(stream, regularFont, 10, lineOne, y);
                            y -= 16;
                        }
                        String lineTwo = juntarPreenchidos("  |  ",
                                rotulado("Data", dateText),
                                showGradeLine ? "Valor: ________" : ""
                        );
                        if (!lineTwo.isBlank()) {
                            RenderizacaoPdfUtils.escreverLinhaPdf(stream, regularFont, 10, lineTwo, y);
                            y -= 16;
                        }
                        if (showStudentNameLine) {
                            RenderizacaoPdfUtils.escreverLinhaPdf(stream, regularFont, 10, "Nome: ________________________________________________", y);
                        }
                    }
                    pageIndex++;
                }
                document.save(target.toFile());
            }
        });
        return new ResultadoConversao(output, "Identificação aplicada ao PDF.");
    }

    public ResultadoConversao numerarPaginas(ArquivoArmazenado input, String position, int startAtPage, int firstNumber, String format) {
        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + "-numerado.pdf";
        ArquivoArmazenado output = storageService.salvarSaida(outputName, "application/pdf", target -> {
            try (PDDocument document = Loader.loadPDF(input.path().toFile())) {
                PDType1Font font = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
                int total = document.getNumberOfPages();
                int firstPageIndex = Math.max(0, startAtPage - 1);
                int totalNumberedPages = Math.max(1, total - firstPageIndex);
                for (int index = firstPageIndex; index < total; index++) {
                    PDPage page = document.getPage(index);
                    PDRectangle box = page.getMediaBox();
                    int visibleNumber = firstNumber + (index - firstPageIndex);
                    String label = rotuloNumeroPagina(format, visibleNumber, totalNumberedPages);
                    float labelWidth = label.length() * 5.8f;
                    float x = posicaoXNumeroPagina(position, box, labelWidth);
                    float y = position.startsWith("top") ? box.getHeight() - 28 : 28;
                    try (PDPageContentStream stream = new PDPageContentStream(document, page, PDPageContentStream.AppendMode.APPEND, true, true)) {
                        stream.beginText();
                        stream.setFont(font, 10);
                        stream.newLineAtOffset(x, y);
                        stream.showText(RenderizacaoPdfUtils.limparTextoPdf(label));
                        stream.endText();
                    }
                }
                document.save(target.toFile());
            }
        });
        return new ResultadoConversao(output, "Páginas numeradas com sucesso.");
    }

    public ResultadoConversao adicionarAssinatura(
            ArquivoArmazenado input,
            ArquivoArmazenado signatureImage,
            String signerName,
            String role,
            String dateText,
            String position,
            double xRatio,
            double yRatio,
            double widthRatio,
            boolean applyToAllPages
    ) {
        if (signatureImage == null && (signerName == null || signerName.isBlank())) {
            throw new IllegalArgumentException("Informe a assinatura.");
        }

        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + "-assinado.pdf";
        ArquivoArmazenado output = storageService.salvarSaida(outputName, "application/pdf", target -> {
            try (PDDocument document = Loader.loadPDF(input.path().toFile())) {
                PDType1Font signatureFont = new PDType1Font(Standard14Fonts.FontName.HELVETICA_OBLIQUE);
                PDType1Font regularFont = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
                int totalPages = document.getNumberOfPages();
                for (int index = 0; index < totalPages; index++) {
                    if (!applyToAllPages && index < totalPages - 1) {
                        continue;
                    }
                    PDPage page = document.getPage(index);
                    PDRectangle box = page.getMediaBox();
                    try (PDPageContentStream stream = new PDPageContentStream(document, page, PDPageContentStream.AppendMode.APPEND, true, true)) {
                        if (signatureImage != null) {
                            desenharImagemAssinatura(document, stream, page, signatureImage.path(), xRatio, yRatio, widthRatio);
                        } else {
                            float blockWidth = 190;
                            float x = posicaoXAssinatura(position, box, blockWidth);
                            float y = position.startsWith("top") ? box.getHeight() - 70 : 70;
                            RenderizacaoPdfUtils.escreverLinhaPdfNaPosicao(stream, signatureFont, 16, signerName, x, y);
                            RenderizacaoPdfUtils.escreverLinhaPdfNaPosicao(stream, regularFont, 9, "______________________________", x, y - 10);
                            float detailY = y - 25;
                            if (role != null && !role.isBlank()) {
                                RenderizacaoPdfUtils.escreverLinhaPdfNaPosicao(stream, regularFont, 9, role, x, detailY);
                                detailY -= 12;
                            }
                            if (dateText != null && !dateText.isBlank()) {
                                RenderizacaoPdfUtils.escreverLinhaPdfNaPosicao(stream, regularFont, 9, "Data: " + dateText, x, detailY);
                            }
                        }
                    }
                }
                document.save(target.toFile());
            }
        });
        return new ResultadoConversao(output, "Assinatura adicionada ao PDF.");
    }

    private float posicaoXNumeroPagina(String position, PDRectangle box, float labelWidth) {
        return switch (position) {
            case "top_left", "bottom_left" -> 50;
            case "top_center", "bottom_center" -> (box.getWidth() - labelWidth) / 2;
            case "top_right", "bottom_right" -> box.getWidth() - labelWidth - 50;
            default -> box.getWidth() - labelWidth - 50;
        };
    }

    private float posicaoXAssinatura(String position, PDRectangle box, float blockWidth) {
        return switch (position) {
            case "top_left", "bottom_left" -> 50;
            case "top_center", "bottom_center" -> (box.getWidth() - blockWidth) / 2;
            case "top_right", "bottom_right" -> box.getWidth() - blockWidth - 50;
            default -> box.getWidth() - blockWidth - 50;
        };
    }

    private void desenharImagemAssinatura(
            PDDocument document,
            PDPageContentStream stream,
            PDPage page,
            Path imagePath,
            double xRatio,
            double yRatio,
            double widthRatio
    ) throws IOException {
        BufferedImage image = ImageIO.read(imagePath.toFile());
        if (image == null) {
            throw new IOException("Não foi possível ler a imagem da assinatura.");
        }

        PDRectangle box = page.getMediaBox();
        float targetWidth = (float) (box.getWidth() * limitar(widthRatio, 0.08, 0.70));
        float targetHeight = targetWidth * image.getHeight() / Math.max(image.getWidth(), 1);
        float x = (float) ((box.getWidth() - targetWidth) * limitar(xRatio, 0.0, 1.0));
        float topY = (float) ((box.getHeight() - targetHeight) * limitar(yRatio, 0.0, 1.0));
        float y = box.getHeight() - topY - targetHeight;

        PDImageXObject signature = LosslessFactory.createFromImage(document, image);
        stream.drawImage(signature, x, y, targetWidth, targetHeight);
    }

    private double limitar(double value, double min, double max) {
        return Math.max(min, Math.min(max, value));
    }

    private String rotulado(String label, String value) {
        return value == null || value.isBlank() ? "" : label + ": " + value;
    }

    private String juntarPreenchidos(String separator, String... values) {
        List<String> filled = new ArrayList<>();
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                filled.add(value);
            }
        }
        return String.join(separator, filled);
    }

    private String rotuloNumeroPagina(String format, int current, int total) {
        return switch (format) {
            case "fraction" -> current + "/" + total;
            case "page_prefix" -> "Pag. " + current;
            default -> String.valueOf(current);
        };
    }

    private BufferedImage lerOrigemPoster(ArquivoArmazenado input, int sheetsWide, int sheetsTall) throws IOException {
        String extension = ArquivoArmazenadoService.extensaoDe(input.originalFileName());
        if ("pdf".equals(extension)) {
            try (PDDocument original = Loader.loadPDF(input.path().toFile())) {
                if (original.getNumberOfPages() == 0) {
                    throw new IOException("O PDF não possui páginas para dividir.");
                }
                int dpi = resolucaoOrigemPoster(sheetsWide, sheetsTall);
                ProgressoTracker.atualizar(0.12, "Renderizando primeira página");
                BufferedImage rendered = new PDFRenderer(original).renderImageWithDPI(0, dpi);
                return RenderizacaoPdfUtils.converterParaRgb(rendered);
            }
        }

        ProgressoTracker.atualizar(0.12, "Lendo imagem");
        BufferedImage image = RenderizacaoPdfUtils.lerImagemComOrientacao(input.path());
        if (image == null) {
            throw new IOException("Não foi possível ler a imagem.");
        }
        return RenderizacaoPdfUtils.converterParaRgb(image);
    }

    private int resolucaoOrigemPoster(int sheetsWide, int sheetsTall) {
        int scale = Math.max(sheetsWide, sheetsTall);
        return Math.max(POSTER_MIN_SOURCE_DPI, Math.min(POSTER_MAX_SOURCE_DPI, POSTER_TILE_DPI * scale));
    }

    private float margemPosterSegura(PDRectangle pageSize, int pageMargin) {
        float maxMargin = Math.min(pageSize.getWidth(), pageSize.getHeight()) / 4;
        return (float) limitar(pageMargin, 0, maxMargin);
    }

    private PDRectangle tamanhoPaginaPosterPara(BufferedImage source, int sheetsWide, int sheetsTall) {
        double sourceAspect = source.getWidth() / (double) Math.max(source.getHeight(), 1);
        double portraitAspect = (PDRectangle.A4.getWidth() * sheetsWide)
                / (PDRectangle.A4.getHeight() * sheetsTall);
        double landscapeAspect = (PDRectangle.A4.getHeight() * sheetsWide)
                / (PDRectangle.A4.getWidth() * sheetsTall);
        double portraitDistance = Math.abs(Math.log(sourceAspect / portraitAspect));
        double landscapeDistance = Math.abs(Math.log(sourceAspect / landscapeAspect));
        if (landscapeDistance < portraitDistance) {
            return new PDRectangle(PDRectangle.A4.getHeight(), PDRectangle.A4.getWidth());
        }
        return PDRectangle.A4;
    }

    private int converterPontosParaPixels(float points, int dpi) {
        return Math.max(64, Math.round(points * dpi / 72f));
    }

    private AjustePoster ajustePoster(BufferedImage source, int posterWidth, int posterHeight) {
        double scale = Math.min(
                posterWidth / (double) source.getWidth(),
                posterHeight / (double) source.getHeight()
        );
        double drawWidth = source.getWidth() * scale;
        double drawHeight = source.getHeight() * scale;
        return new AjustePoster(
                scale,
                (posterWidth - drawWidth) / 2,
                (posterHeight - drawHeight) / 2
        );
    }

    private BufferedImage criarFolhaPoster(
            BufferedImage source,
            int column,
            int row,
            int tileWidth,
            int tileHeight,
            AjustePoster fit
    ) {
        BufferedImage tile = new BufferedImage(tileWidth, tileHeight, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = tile.createGraphics();
        try {
            graphics.setColor(Color.WHITE);
            graphics.fillRect(0, 0, tileWidth, tileHeight);
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            graphics.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            AffineTransform transform = new AffineTransform();
            transform.translate(fit.x() - (column * tileWidth), fit.y() - (row * tileHeight));
            transform.scale(fit.scale(), fit.scale());
            graphics.drawImage(source, transform, null);
        } finally {
            graphics.dispose();
        }
        return tile;
    }

    private record AjustePoster(double scale, double x, double y) {
    }

    private record PredefinicaoCompressao(int dpi, float quality) {
        private static PredefinicaoCompressao de(String level) {
            return switch (level == null ? "medium" : level) {
                case "light" -> new PredefinicaoCompressao(150, 0.82f);
                case "strong" -> new PredefinicaoCompressao(90, 0.48f);
                default -> new PredefinicaoCompressao(120, 0.65f);
            };
        }
    }

    private Set<Integer> normalizarPaginas(List<Integer> pages, int totalPages) {
        Set<Integer> normalized = new LinkedHashSet<>();
        for (Integer page : pages) {
            if (page == null || page < 1 || page > totalPages) {
                throw new IllegalArgumentException("Página invalida: " + page + ". O PDF possui páginas de 1 até " + totalPages + ".");
            }
            normalized.add(page);
        }
        return normalized;
    }

    private void adicionarPagina(PDDocument original, PDDocument destination, int pageNumber) throws IOException {
        Splitter splitter = new Splitter();
        splitter.setStartPage(pageNumber);
        splitter.setEndPage(pageNumber);
        splitter.setSplitAtPage(1);

        List<PDDocument> pages = splitter.split(original);
        if (pages.isEmpty()) {
            throw new IOException("Não foi possível extrair a página " + pageNumber + ".");
        }

        try (PDDocument temporary = pages.get(0)) {
            PDFMergerUtility merger = new PDFMergerUtility();
            merger.appendDocument(destination, temporary);
        }
    }
}
