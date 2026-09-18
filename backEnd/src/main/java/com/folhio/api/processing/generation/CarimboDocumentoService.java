package com.folhio.api.processing.generation;

import com.folhio.api.dto.action.AcaoRequest;
import com.folhio.api.dto.action.AcaoResponse;
import com.folhio.api.common.util.MapasJson;
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
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class CarimboDocumentoService {

    private final ArquivoArmazenadoService storageService;

    public CarimboDocumentoService(ArquivoArmazenadoService storageService) {
        this.storageService = storageService;
    }

    public AcaoResponse carimbarDocumentos(AcaoRequest request) {
        List<ArquivoArmazenado> inputs = arquivosDosDados(request.payload());
        ArquivoArmazenado signature = assinaturaDosDados(request.payload());
        PosicaoCarimbo placement = posicaoDosDados(request.payload());

        if (inputs.isEmpty()) {
            return AcaoResponse.rejeitado(
                    request.requestId(),
                    "Escolha pelo menos um PDF ou imagem para assinar.",
                    Map.of()
            );
        }

        ArquivoArmazenado output = inputs.size() == 1
                ? carimbarUnico(inputs.get(0), signature, placement)
                : carimbarVarios(inputs, signature, placement);

        return AcaoResponse.sucesso(
                request.requestId(),
                "Documentos assinados com sucesso.",
                Map.of(
                        "files", inputs.size(),
                        "signature", signature.originalFileName()
                ),
                arquivoSaida(output)
        );
    }

    private List<ArquivoArmazenado> arquivosDosDados(Map<String, Object> payload) {
        List<ArquivoArmazenado> files = new ArrayList<>();
        for (Object item : MapasJson.listar(payload, "files")) {
            if (item instanceof Map<?, ?> raw) {
                @SuppressWarnings("unchecked")
                Map<String, Object> file = (Map<String, Object>) raw;
                String id = MapasJson.texto(file, "id", "");
                if (!id.isBlank()) {
                    files.add(storageService.buscar(id));
                }
            }
        }
        return files;
    }

    private ArquivoArmazenado assinaturaDosDados(Map<String, Object> payload) {
        String id = MapasJson.texto(MapasJson.filho(payload, "signature"), "id", "");
        if (id.isBlank()) {
            throw new com.folhio.api.handler.file.exception.FormatoArquivoNaoSuportadoException("Escolha uma assinatura em PNG.");
        }
        ArquivoArmazenado signature = storageService.buscar(id);
        String extension = ArquivoArmazenadoService.extensaoDe(signature.originalFileName());
        if (!"png".equals(extension)) {
            throw new com.folhio.api.handler.file.exception.FormatoArquivoNaoSuportadoException("Use uma assinatura em PNG, de preferência sem fundo.");
        }
        return signature;
    }

    private PosicaoCarimbo posicaoDosDados(Map<String, Object> payload) {
        Map<String, Object> placement = MapasJson.filho(payload, "placement");
        return new PosicaoCarimbo(
                limitar(MapasJson.decimal(placement, "x", 0.58), 0.0, 1.0),
                limitar(MapasJson.decimal(placement, "y", 0.70), 0.0, 1.0),
                limitar(MapasJson.decimal(placement, "width", 0.26), 0.08, 0.70)
        );
    }

    private ArquivoArmazenado carimbarUnico(ArquivoArmazenado input, ArquivoArmazenado signature, PosicaoCarimbo placement) {
        String extension = ArquivoArmazenadoService.extensaoDe(input.originalFileName());
        if ("pdf".equals(extension)) {
            return storageService.salvarSaida(
                    ArquivoArmazenadoService.semExtensao(input.originalFileName()) + "-assinado.pdf",
                    "application/pdf",
                    target -> carimbarPdf(input, signature, placement, target)
            );
        }
        if (ehExtensaoImagem(extension)) {
            return storageService.salvarSaida(
                    ArquivoArmazenadoService.semExtensao(input.originalFileName()) + "-assinado.png",
                    "image/png",
                    target -> carimbarImagem(input, signature, placement, target)
            );
        }
        throw new com.folhio.api.handler.file.exception.FormatoArquivoNaoSuportadoException("Use apenas PDF, PNG ou JPG.");
    }

    private ArquivoArmazenado carimbarVarios(List<ArquivoArmazenado> inputs, ArquivoArmazenado signature, PosicaoCarimbo placement) {
        return storageService.salvarSaida("documentos-assinados.zip", "application/zip", target -> {
            try (ZipOutputStream zip = new ZipOutputStream(Files.newOutputStream(target))) {
                for (int index = 0; index < inputs.size(); index++) {
                    ArquivoArmazenado input = inputs.get(index);
                    Path stamped = Files.createTempFile("folhio-stamped-", extensaoSaida(input));
                    try {
                        carimbarNoCaminho(input, signature, placement, stamped);
                        zip.putNextEntry(new ZipEntry(nomeSaida(input)));
                        Files.copy(stamped, zip);
                        zip.closeEntry();
                    } finally {
                        Files.deleteIfExists(stamped);
                    }
                    ProgressoTracker.atualizar(
                            0.20 + ((index + 1) * 0.70 / inputs.size()),
                            "Assinando arquivo " + (index + 1)
                    );
                }
            }
        });
    }

    private void carimbarNoCaminho(
            ArquivoArmazenado input,
            ArquivoArmazenado signature,
            PosicaoCarimbo placement,
            Path target
    ) throws IOException {
        String extension = ArquivoArmazenadoService.extensaoDe(input.originalFileName());
        if ("pdf".equals(extension)) {
            carimbarPdf(input, signature, placement, target);
        } else if (ehExtensaoImagem(extension)) {
            carimbarImagem(input, signature, placement, target);
        } else {
            throw new com.folhio.api.handler.file.exception.FormatoArquivoNaoSuportadoException("Use apenas PDF, PNG ou JPG.");
        }
    }

    private void carimbarPdf(
            ArquivoArmazenado input,
            ArquivoArmazenado signature,
            PosicaoCarimbo placement,
            Path target
    ) throws IOException {
        BufferedImage signatureImage = lerImagem(signature.path(), "Não foi possível ler a assinatura.");
        try (PDDocument document = Loader.loadPDF(input.path().toFile())) {
            int pages = document.getNumberOfPages();
            for (int index = 0; index < pages; index++) {
                PDPage page = document.getPage(index);
                try (PDPageContentStream stream = new PDPageContentStream(
                        document,
                        page,
                        PDPageContentStream.AppendMode.APPEND,
                        true,
                        true
                )) {
                    desenharAssinaturaNoPdf(document, stream, page, signatureImage, placement);
                }
                ProgressoTracker.atualizar(0.20 + ((index + 1) * 0.60 / Math.max(pages, 1)), "Aplicando assinatura");
            }
            document.save(target.toFile());
        }
    }

    private void desenharAssinaturaNoPdf(
            PDDocument document,
            PDPageContentStream stream,
            PDPage page,
            BufferedImage signatureImage,
            PosicaoCarimbo placement
    ) throws IOException {
        PDRectangle box = page.getMediaBox();
        float targetWidth = (float) (box.getWidth() * placement.widthRatio());
        float targetHeight = targetWidth * signatureImage.getHeight() / Math.max(signatureImage.getWidth(), 1);
        float x = (float) ((box.getWidth() - targetWidth) * placement.xRatio());
        float topY = (float) ((box.getHeight() - targetHeight) * placement.yRatio());
        float y = box.getHeight() - topY - targetHeight;

        PDImageXObject image = LosslessFactory.createFromImage(document, signatureImage);
        stream.drawImage(image, x, y, targetWidth, targetHeight);
    }

    private void carimbarImagem(
            ArquivoArmazenado input,
            ArquivoArmazenado signature,
            PosicaoCarimbo placement,
            Path target
    ) throws IOException {
        BufferedImage base = lerImagem(input.path(), "Não foi possível ler a imagem.");
        BufferedImage stamp = lerImagem(signature.path(), "Não foi possível ler a assinatura.");
        BufferedImage output = new BufferedImage(base.getWidth(), base.getHeight(), BufferedImage.TYPE_INT_ARGB);
        Graphics2D graphics = output.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            graphics.drawImage(base, 0, 0, null);

            int targetWidth = (int) Math.round(base.getWidth() * placement.widthRatio());
            int targetHeight = Math.max(1, targetWidth * stamp.getHeight() / Math.max(stamp.getWidth(), 1));
            int x = (int) Math.round((base.getWidth() - targetWidth) * placement.xRatio());
            int y = (int) Math.round((base.getHeight() - targetHeight) * placement.yRatio());
            graphics.drawImage(stamp, x, y, targetWidth, targetHeight, null);
        } finally {
            graphics.dispose();
        }
        ImageIO.write(output, "png", target.toFile());
    }

    private BufferedImage lerImagem(Path path, String message) throws IOException {
        BufferedImage image = ImageIO.read(path.toFile());
        if (image == null) {
            throw new IOException(message);
        }
        return image;
    }

    private boolean ehExtensaoImagem(String extension) {
        return "png".equals(extension) || "jpg".equals(extension) || "jpeg".equals(extension);
    }

    private String extensaoSaida(ArquivoArmazenado input) {
        return "pdf".equals(ArquivoArmazenadoService.extensaoDe(input.originalFileName())) ? ".pdf" : ".png";
    }

    private String nomeSaida(ArquivoArmazenado input) {
        return ArquivoArmazenadoService.semExtensao(input.originalFileName()) + "-assinado" + extensaoSaida(input);
    }

    private double limitar(double value, double min, double max) {
        return Math.max(min, Math.min(max, value));
    }

    private AcaoResponse.ArquivoSaida arquivoSaida(ArquivoArmazenado file) {
        return new AcaoResponse.ArquivoSaida(
                file.originalFileName(),
                file.contentType(),
                file.sizeBytes(),
                "/api/folhio/files/" + file.id() + "/download",
                file.id()
        );
    }

    private record PosicaoCarimbo(double xRatio, double yRatio, double widthRatio) {
    }
}
