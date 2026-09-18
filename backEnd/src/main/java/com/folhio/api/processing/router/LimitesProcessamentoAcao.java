package com.folhio.api.processing.router;

import com.folhio.api.service.ArquivoArmazenadoService;
import com.folhio.api.files.model.ArquivoArmazenado;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.util.List;
import java.util.Set;

final class LimitesProcessamentoAcao {

    private static final long MAX_PDF_BYTES = 80L * 1024L * 1024L;
    private static final int MAX_PDF_PAGES = 300;
    private static final long MAX_IMAGE_BYTES = 25L * 1024L * 1024L;
    private static final long MAX_IMAGE_PIXELS = 36_000_000L;
    private static final long MAX_OFFICE_BYTES = 80L * 1024L * 1024L;
    private static final int MAX_MERGE_FILES = 20;
    private static final long MAX_MERGE_BYTES = 150L * 1024L * 1024L;
    private static final Set<String> IMAGE_EXTENSIONS = Set.of("png", "jpg", "jpeg");
    private static final Set<String> OFFICE_EXTENSIONS = Set.of("doc", "docx", "ppt", "pptx", "xls", "xlsx");

    private LimitesProcessamentoAcao() {
    }

    static void validarEntradaConversaoDocumento(ArquivoArmazenado file) {
        String extension = ArquivoArmazenadoService.extensaoDe(file.originalFileName());
        if ("pdf".equals(extension)) {
            validarPdf(file);
            return;
        }
        if (IMAGE_EXTENSIONS.contains(extension)) {
            validarImagem(file);
            return;
        }
        if (OFFICE_EXTENSIONS.contains(extension)) {
            validarTamanho(file, MAX_OFFICE_BYTES, "Documento maior que o limite permitido para conversao.");
            return;
        }
        throw new com.folhio.api.handler.file.exception.FormatoArquivoNaoSuportadoException("Tipo de arquivo nao suportado para conversao.");
    }

    static void validarPdf(ArquivoArmazenado file) {
        validarTamanho(file, MAX_PDF_BYTES, "PDF maior que o limite permitido para processamento.");
        int pages = quantidadePaginasPdf(file);
        if (pages > MAX_PDF_PAGES) {
            throw new com.folhio.api.handler.processing.exception.LimiteProcessamentoException("PDF com paginas demais para processar agora.");
        }
    }

    static void validarEntradaPoster(ArquivoArmazenado file) {
        String extension = ArquivoArmazenadoService.extensaoDe(file.originalFileName());
        if ("pdf".equals(extension)) {
            validarPdf(file);
            return;
        }
        if (IMAGE_EXTENSIONS.contains(extension)) {
            validarImagem(file);
            return;
        }
        throw new com.folhio.api.handler.file.exception.FormatoArquivoNaoSuportadoException("Use um PDF ou uma imagem para criar o pôster.");
    }

    static void validarMesclagem(List<ArquivoArmazenado> files) {
        if (files.isEmpty()) {
            throw new com.folhio.api.handler.file.exception.ArquivoInvalidoException("Informe ao menos um PDF.");
        }
        if (files.size() > MAX_MERGE_FILES) {
            throw new com.folhio.api.handler.file.exception.ArquivoInvalidoException("Muitos PDFs selecionados para mesclar de uma vez.");
        }
        long totalBytes = 0;
        for (ArquivoArmazenado file : files) {
            validarPdf(file);
            totalBytes += file.sizeBytes();
        }
        if (totalBytes > MAX_MERGE_BYTES) {
            throw new com.folhio.api.handler.processing.exception.LimiteProcessamentoException("PDFs grandes demais para mesclar de uma vez.");
        }
    }

    static void validarImagem(ArquivoArmazenado file) {
        validarTamanho(file, MAX_IMAGE_BYTES, "Imagem maior que o limite permitido para edicao.");
        String extension = ArquivoArmazenadoService.extensaoDe(file.originalFileName());
        if (!IMAGE_EXTENSIONS.contains(extension)) {
            throw new com.folhio.api.handler.file.exception.FormatoArquivoNaoSuportadoException("A edicao visual aceita apenas imagem.");
        }
        try {
            BufferedImage image = ImageIO.read(file.path().toFile());
            if (image == null) {
                throw new com.folhio.api.handler.file.exception.ArquivoInvalidoException("Nao foi possivel ler a imagem.");
            }
            long pixels = (long) image.getWidth() * image.getHeight();
            if (pixels > MAX_IMAGE_PIXELS) {
                throw new com.folhio.api.handler.processing.exception.LimiteProcessamentoException("Imagem grande demais para editar neste momento.");
            }
        } catch (com.folhio.api.handler.NegocioException error) {
            throw error;
        } catch (Exception error) {
            throw new com.folhio.api.handler.file.exception.ArquivoInvalidoException("Nao foi possivel validar a imagem.", error);
        }
    }

    private static void validarTamanho(ArquivoArmazenado file, long limitBytes, String message) {
        if (file.sizeBytes() > limitBytes) {
            throw new com.folhio.api.handler.processing.exception.LimiteProcessamentoException(message);
        }
    }

    private static int quantidadePaginasPdf(ArquivoArmazenado file) {
        try (PDDocument document = Loader.loadPDF(file.path().toFile())) {
            return document.getNumberOfPages();
        } catch (Exception error) {
            throw new com.folhio.api.handler.file.exception.ArquivoInvalidoException("Nao foi possivel validar o PDF.", error);
        }
    }
}
