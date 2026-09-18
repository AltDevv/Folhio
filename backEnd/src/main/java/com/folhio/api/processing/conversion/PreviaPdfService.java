package com.folhio.api.processing.conversion;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.springframework.stereotype.Service;
import javax.imageio.ImageIO;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.file.Path;

@Service
public class PreviaPdfService {
    public record InformacoesPdf(int pages, float width, float height) {}

    public InformacoesPdf inspecionar(Path path) {
        try (PDDocument document = Loader.loadPDF(path.toFile())) {
            if (document.getNumberOfPages() == 0) return null;
            var page = document.getPage(0);
            var box = page.getCropBox();
            int rotation = Math.floorMod(page.getRotation(), 360);
            return rotation == 90 || rotation == 270
                    ? new InformacoesPdf(document.getNumberOfPages(), box.getHeight(), box.getWidth())
                    : new InformacoesPdf(document.getNumberOfPages(), box.getWidth(), box.getHeight());
        } catch (IOException error) {
            throw new IllegalArgumentException("Nao foi possivel ler o PDF.", error);
        }
    }

    public byte[] visualizarPrevia(Path path, int page) {
        try (PDDocument document = Loader.loadPDF(path.toFile());
             ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            if (page < 1 || page > document.getNumberOfPages()) {
                throw new IllegalArgumentException("Pagina inexistente.");
            }
            var box = document.getPage(page - 1).getCropBox();
            float longest = Math.max(box.getWidth(), box.getHeight());
            if (!Float.isFinite(longest) || longest <= 0) throw new IllegalArgumentException("Pagina invalida.");
            float dpi = Math.min(120f, 2048f * 72f / longest);
            var image = new PDFRenderer(document).renderImageWithDPI(page - 1, dpi);
            ImageIO.write(image, "png", output);
            return output.toByteArray();
        } catch (IOException error) {
            throw new IllegalArgumentException("Nao foi possivel gerar previa do PDF.", error);
        }
    }
}
