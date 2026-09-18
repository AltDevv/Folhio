package com.folhio.api.processing.conversion;

import com.folhio.api.processing.image.RemocaoFundoService;
import com.folhio.api.processing.conversion.util.RenderizacaoPdfUtils;
import com.folhio.api.service.ArquivoArmazenadoService;
import com.folhio.api.files.model.ArquivoArmazenado;
import com.folhio.api.progress.ProgressoTracker;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.List;
import java.util.Map;

@Service
public class EdicaoImagemEngine {

    private final ArquivoArmazenadoService storageService;
    private final RemocaoFundoService backgroundRemovalService;

    public record CamadaImagemVisual(ArquivoArmazenado file, Map<String, Object> rect) {
    }

    public EdicaoImagemEngine(ArquivoArmazenadoService storageService, RemocaoFundoService backgroundRemovalService) {
        this.storageService = storageService;
        this.backgroundRemovalService = backgroundRemovalService;
    }

    public ResultadoConversao editarImagemVisual(
            ArquivoArmazenado input,
            int quarterTurns,
            double rotationDegrees,
            boolean mirrored,
            int brightness,
            int contrast,
            boolean removeBackground,
            String cropShape,
            Map<String, Object> crop,
            List<Map<String, Object>> textLayers,
            List<CamadaImagemVisual> imageLayers,
            List<Map<String, Object>> marks
    ) {
        String extension = ArquivoArmazenadoService.extensaoDe(input.originalFileName());
        if (!List.of("png", "jpg", "jpeg").contains(extension)) {
            throw new IllegalArgumentException("A edição visual exportável aceita PNG e JPG por enquanto.");
        }

        String outputName = ArquivoArmazenadoService.semExtensao(input.originalFileName()) + "-editado" + TransformacoesImagem.sufixoFormatoRecorte(cropShape) + ".png";
        ArquivoArmazenado output = storageService.salvarSaida(outputName, "image/png", target -> {
            ProgressoTracker.atualizar(0.15, "Lendo imagem");
            BufferedImage image = RenderizacaoPdfUtils.lerImagemComOrientacao(input.path());
            if (image == null) {
                throw new IOException("Não foi possível abrir a imagem.");
            }

            BufferedImage result = TransformacoesImagem.converterParaArgb(image);
            if (removeBackground) {
                ProgressoTracker.atualizar(0.30, "Removendo fundo");
                result = removerFundo(result);
            }
            ProgressoTracker.atualizar(0.48, "Aplicando ajustes");
            result = TransformacoesImagem.ajustarImagem(result, brightness, contrast);
            if (mirrored) {
                result = TransformacoesImagem.espelharImagem(result);
            }
            result = TransformacoesImagem.girarImagem(result, quarterTurns);
            result = TransformacoesImagem.girarImagem(result, rotationDegrees);

            ProgressoTracker.atualizar(0.76, "Aplicando marcações");
            desenharCamadasImagem(result, imageLayers);
            desenharMarcas(result, marks);
            ProgressoTracker.atualizar(0.84, "Aplicando textos");
            desenharCamadasTexto(result, textLayers);
            result = TransformacoesImagem.recortarImagem(result, crop, cropShape);
            ImageIO.write(result, "png", target.toFile());
            ProgressoTracker.atualizar(0.95, "Salvando imagem");
        });

        return new ResultadoConversao(output, removeBackground ? "Imagem editada com fundo removido." : "Imagem editada com sucesso.");
    }

    private BufferedImage removerFundo(BufferedImage source) {
        try {
            return backgroundRemovalService.removerFundo(source);
        } catch (IOException exception) {
            return source;
        }
    }

    private void desenharCamadasImagem(BufferedImage image, List<CamadaImagemVisual> imageLayers) throws IOException {
        if (imageLayers == null || imageLayers.isEmpty()) {
            return;
        }
        Graphics2D graphics = image.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            for (int index = 0; index < imageLayers.size(); index++) {
                CamadaImagemVisual layer = imageLayers.get(index);
                if (layer == null || layer.file() == null) {
                    continue;
                }
                BufferedImage overlay = RenderizacaoPdfUtils.lerImagemComOrientacao(layer.file().path());
                if (overlay == null) {
                    continue;
                }
                Map<String, Object> rect = layer.rect() == null ? Map.of() : layer.rect();
                double xRatio = valorDecimal(rect.get("x"), 0.38 + Math.min(index, 4) * 0.04);
                double yRatio = valorDecimal(rect.get("y"), 0.38 + Math.min(index, 4) * 0.04);
                double widthRatio = valorDecimal(rect.get("width"), 0.24);
                double heightRatio = valorDecimal(rect.get("height"), 0.18);
                int x = (int) Math.round(limitarPosicaoSobreposicao(xRatio) * image.getWidth());
                int y = (int) Math.round(limitarPosicaoSobreposicao(yRatio) * image.getHeight());
                int width = Math.max(12, (int) Math.round(limitarTamanhoSobreposicao(widthRatio) * image.getWidth()));
                int height = Math.max(12, (int) Math.round(limitarTamanhoSobreposicao(heightRatio) * image.getHeight()));
                graphics.drawImage(TransformacoesImagem.converterParaArgb(overlay), x, y, width, height, null);
            }
        } finally {
            graphics.dispose();
        }
    }

    private void desenharMarcas(BufferedImage image, List<Map<String, Object>> marks) {
        if (marks == null || marks.isEmpty()) {
            return;
        }
        Graphics2D graphics = image.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            graphics.setStroke(new java.awt.BasicStroke(Math.max(5, image.getWidth() / 160f), java.awt.BasicStroke.CAP_ROUND, java.awt.BasicStroke.JOIN_ROUND));
            for (Map<String, Object> mark : marks) {
                graphics.setColor(interpretarCor(valorTexto(mark.get("color"), "#d221c89a")));
                List<?> points = valorLista(mark.get("points"));
                for (int index = 1; index < points.size(); index++) {
                    Map<String, Object> previous = valorMapa(points.get(index - 1));
                    Map<String, Object> current = valorMapa(points.get(index));
                    int x1 = (int) Math.round(limitarProporcao(valorDecimal(previous.get("x"), 0)) * image.getWidth());
                    int y1 = (int) Math.round(limitarProporcao(valorDecimal(previous.get("y"), 0)) * image.getHeight());
                    int x2 = (int) Math.round(limitarProporcao(valorDecimal(current.get("x"), 0)) * image.getWidth());
                    int y2 = (int) Math.round(limitarProporcao(valorDecimal(current.get("y"), 0)) * image.getHeight());
                    graphics.drawLine(x1, y1, x2, y2);
                }
            }
        } finally {
            graphics.dispose();
        }
    }

    private void desenharCamadasTexto(BufferedImage image, List<Map<String, Object>> textLayers) {
        if (textLayers == null || textLayers.isEmpty()) {
            return;
        }
        Graphics2D graphics = image.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            for (int index = 0; index < textLayers.size(); index++) {
                Map<String, Object> layer = textLayers.get(index);
                String text = valorTexto(layer.get("text"), "Texto").trim();
                if (text.isBlank()) {
                    continue;
                }
                Map<String, Object> rect = valorMapa(layer.get("rect"));
                double xRatio = valorDecimal(rect.get("x"), 0.22 + Math.min(index, 4) * 0.04);
                double yRatio = valorDecimal(rect.get("y"), 0.42 + Math.min(index, 4) * 0.05);
                double widthRatio = valorDecimal(rect.get("width"), 0.56);
                double heightRatio = valorDecimal(rect.get("height"), 0.12);
                int x = (int) Math.round(limitarProporcao(xRatio) * image.getWidth());
                int y = (int) Math.round(limitarProporcao(yRatio) * image.getHeight());
                int width = Math.max(20, (int) Math.round(limitarProporcao(widthRatio) * image.getWidth()));
                int height = Math.max(18, (int) Math.round(limitarProporcao(heightRatio) * image.getHeight()));
                desenharTextoCentralizado(graphics, text, interpretarCor(valorTexto(layer.get("color"), "#ff000000")), x, y, width, height);
            }
        } finally {
            graphics.dispose();
        }
    }

    private void desenharTextoCentralizado(Graphics2D graphics, String text, Color color, int x, int y, int width, int height) {
        int fontSize = Math.max(12, Math.min(96, (int) Math.round(height * 0.46)));
        Font font = new Font(Font.SANS_SERIF, Font.BOLD, fontSize);
        graphics.setFont(font);
        FontMetrics metrics = graphics.getFontMetrics();
        String[] lines = text.split("\\R", 4);
        int lineHeight = metrics.getHeight();
        int totalHeight = lineHeight * lines.length;
        int textY = y + Math.max(metrics.getAscent(), ((height - totalHeight) / 2) + metrics.getAscent());
        for (String line : lines) {
            String fitted = ajustarTexto(line, metrics, width);
            int textX = x + Math.max(0, (width - metrics.stringWidth(fitted)) / 2);
            graphics.setColor(new Color(255, 255, 255, 210));
            for (int ox = -2; ox <= 2; ox++) {
                for (int oy = -2; oy <= 2; oy++) {
                    if (ox != 0 || oy != 0) {
                        graphics.drawString(fitted, textX + ox, textY + oy);
                    }
                }
            }
            graphics.setColor(color);
            graphics.drawString(fitted, textX, textY);
            textY += lineHeight;
        }
    }

    private String ajustarTexto(String text, FontMetrics metrics, int width) {
        String fitted = text == null ? "" : text;
        while (fitted.length() > 1 && metrics.stringWidth(fitted) > width) {
            fitted = fitted.substring(0, fitted.length() - 1);
        }
        return fitted;
    }

    private Map<String, Object> valorMapa(Object value) {
        if (value instanceof Map<?, ?> raw) {
            @SuppressWarnings("unchecked")
            Map<String, Object> typed = (Map<String, Object>) raw;
            return typed;
        }
        return Map.of();
    }

    private List<?> valorLista(Object value) {
        return value instanceof List<?> list ? list : List.of();
    }

    private String valorTexto(Object value, String fallback) {
        return value == null ? fallback : value.toString();
    }

    private double valorDecimal(Object value, double fallback) {
        if (value instanceof Number number) {
            return number.doubleValue();
        }
        if (value != null) {
            try {
                return Double.parseDouble(value.toString());
            } catch (NumberFormatException ignored) {
                return fallback;
            }
        }
        return fallback;
    }

    private double limitarProporcao(double value) {
        return Math.max(0, Math.min(1, value));
    }

    private double limitarPosicaoSobreposicao(double value) {
        return Math.max(-3, Math.min(3, value));
    }

    private double limitarTamanhoSobreposicao(double value) {
        return Math.max(0.02, Math.min(4, value));
    }

    private Color interpretarCor(String value) {
        String clean = value == null ? "" : value.replace("#", "").trim();
        try {
            long raw = Long.parseLong(clean, 16);
            if (clean.length() == 8) {
                return new Color((int) raw, true);
            }
            if (clean.length() == 6) {
                return new Color((int) raw);
            }
        } catch (NumberFormatException ignored) {
            return Color.BLACK;
        }
        return Color.BLACK;
    }

}
