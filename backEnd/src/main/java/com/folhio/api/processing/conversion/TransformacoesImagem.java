package com.folhio.api.processing.conversion;

import java.awt.AlphaComposite;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.geom.Ellipse2D;
import java.awt.geom.Path2D;
import java.awt.image.BufferedImage;
import java.util.List;
import java.util.Locale;
import java.util.Map;

final class TransformacoesImagem {

    private TransformacoesImagem() {
    }

    static BufferedImage converterParaArgb(BufferedImage source) {
        if (source.getType() == BufferedImage.TYPE_INT_ARGB) {
            return source;
        }
        BufferedImage argb = new BufferedImage(source.getWidth(), source.getHeight(), BufferedImage.TYPE_INT_ARGB);
        Graphics2D graphics = argb.createGraphics();
        try {
            graphics.setComposite(AlphaComposite.Src);
            graphics.drawImage(source, 0, 0, null);
        } finally {
            graphics.dispose();
        }
        return argb;
    }

    static BufferedImage ajustarImagem(BufferedImage source, int brightness, int contrast) {
        double contrastFactor = 1 + (Math.max(-50, Math.min(50, contrast)) / 100.0);
        double brightnessShift = Math.max(-50, Math.min(50, brightness)) * 2.55;
        BufferedImage output = new BufferedImage(source.getWidth(), source.getHeight(), BufferedImage.TYPE_INT_ARGB);
        for (int y = 0; y < source.getHeight(); y++) {
            for (int x = 0; x < source.getWidth(); x++) {
                int argb = source.getRGB(x, y);
                int alpha = (argb >>> 24) & 0xFF;
                int red = ajustarCanal((argb >>> 16) & 0xFF, contrastFactor, brightnessShift);
                int green = ajustarCanal((argb >>> 8) & 0xFF, contrastFactor, brightnessShift);
                int blue = ajustarCanal(argb & 0xFF, contrastFactor, brightnessShift);
                output.setRGB(x, y, (alpha << 24) | (red << 16) | (green << 8) | blue);
            }
        }
        return output;
    }

    static BufferedImage espelharImagem(BufferedImage source) {
        BufferedImage output = new BufferedImage(source.getWidth(), source.getHeight(), BufferedImage.TYPE_INT_ARGB);
        Graphics2D graphics = output.createGraphics();
        try {
            graphics.drawImage(source, source.getWidth(), 0, -source.getWidth(), source.getHeight(), null);
        } finally {
            graphics.dispose();
        }
        return output;
    }

    static BufferedImage girarImagem(BufferedImage source, int quarterTurns) {
        int turns = ((quarterTurns % 4) + 4) % 4;
        if (turns == 0) {
            return source;
        }
        boolean swap = turns == 1 || turns == 3;
        int width = swap ? source.getHeight() : source.getWidth();
        int height = swap ? source.getWidth() : source.getHeight();
        BufferedImage output = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
        Graphics2D graphics = output.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            if (turns == 1) {
                graphics.translate(width, 0);
                graphics.rotate(Math.PI / 2);
            } else if (turns == 2) {
                graphics.translate(width, height);
                graphics.rotate(Math.PI);
            } else {
                graphics.translate(0, height);
                graphics.rotate(-Math.PI / 2);
            }
            graphics.drawImage(source, 0, 0, null);
        } finally {
            graphics.dispose();
        }
        return output;
    }

    static BufferedImage girarImagem(BufferedImage source, double degrees) {
        if (Math.abs(degrees) < 0.01) {
            return source;
        }
        double radians = Math.toRadians(degrees);
        double sin = Math.abs(Math.sin(radians));
        double cos = Math.abs(Math.cos(radians));
        int width = source.getWidth();
        int height = source.getHeight();
        int outputWidth = Math.max(1, (int) Math.ceil(width * cos + height * sin));
        int outputHeight = Math.max(1, (int) Math.ceil(height * cos + width * sin));
        BufferedImage output = new BufferedImage(outputWidth, outputHeight, BufferedImage.TYPE_INT_ARGB);
        Graphics2D graphics = output.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            graphics.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            graphics.translate(outputWidth / 2.0, outputHeight / 2.0);
            graphics.rotate(radians);
            graphics.translate(-width / 2.0, -height / 2.0);
            graphics.drawImage(source, 0, 0, null);
        } finally {
            graphics.dispose();
        }
        return output;
    }

    static BufferedImage recortarImagem(BufferedImage source, Map<String, Object> crop, String selectedShape) {
        String shape = selectedShape == null ? "basic" : selectedShape.toLowerCase(Locale.ROOT);
        if (crop == null || crop.isEmpty()) {
            if (List.of("square", "triangle", "circle", "hexagon").contains(shape)) {
                source = centralizarImagemQuadrada(source);
            }
            return aplicarFormatoRecorte(source, shape);
        }
        int x = (int) Math.round(limitarProporcao(valorDecimal(crop.get("x"), 0)) * source.getWidth());
        int y = (int) Math.round(limitarProporcao(valorDecimal(crop.get("y"), 0)) * source.getHeight());
        int width = (int) Math.round(limitarProporcao(valorDecimal(crop.get("width"), 1)) * source.getWidth());
        int height = (int) Math.round(limitarProporcao(valorDecimal(crop.get("height"), 1)) * source.getHeight());
        shape = valorTexto(crop.get("shape"), shape).toLowerCase(Locale.ROOT);
        x = Math.max(0, Math.min(x, source.getWidth() - 1));
        y = Math.max(0, Math.min(y, source.getHeight() - 1));
        width = Math.max(1, Math.min(width, source.getWidth() - x));
        height = Math.max(1, Math.min(height, source.getHeight() - y));
        if (List.of("square", "triangle", "circle", "hexagon").contains(shape)) {
            int side = Math.max(1, Math.min(width, height));
            int centerX = x + width / 2;
            int centerY = y + height / 2;
            x = Math.max(0, Math.min(centerX - side / 2, source.getWidth() - side));
            y = Math.max(0, Math.min(centerY - side / 2, source.getHeight() - side));
            width = side;
            height = side;
        }

        BufferedImage output = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
        Graphics2D graphics = output.createGraphics();
        try {
            graphics.drawImage(source, 0, 0, width, height, x, y, x + width, y + height, null);
        } finally {
            graphics.dispose();
        }
        return aplicarFormatoRecorte(output, shape);
    }

    static String sufixoFormatoRecorte(String shape) {
        return switch (shape == null ? "basic" : shape.toLowerCase(Locale.ROOT)) {
            case "circle" -> "-redondo";
            case "square" -> "-quadrado";
            case "triangle" -> "-triangulo";
            case "hexagon" -> "-hexagono";
            default -> "";
        };
    }

    private static int ajustarCanal(int value, double contrastFactor, double brightnessShift) {
        return limitarCor((int) Math.round(((value - 128) * contrastFactor) + 128 + brightnessShift));
    }

    private static BufferedImage centralizarImagemQuadrada(BufferedImage source) {
        int side = Math.max(1, Math.min(source.getWidth(), source.getHeight()));
        int x = Math.max(0, (source.getWidth() - side) / 2);
        int y = Math.max(0, (source.getHeight() - side) / 2);
        BufferedImage output = new BufferedImage(side, side, BufferedImage.TYPE_INT_ARGB);
        Graphics2D graphics = output.createGraphics();
        try {
            graphics.drawImage(source, 0, 0, side, side, x, y, x + side, y + side, null);
        } finally {
            graphics.dispose();
        }
        return output;
    }

    private static BufferedImage aplicarFormatoRecorte(BufferedImage source, String shape) {
        if (!List.of("triangle", "circle", "hexagon").contains(shape)) {
            return source;
        }
        BufferedImage mask = new BufferedImage(source.getWidth(), source.getHeight(), BufferedImage.TYPE_BYTE_GRAY);
        Graphics2D graphics = mask.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            graphics.setColor(Color.WHITE);
            graphics.fill(formatoRecorte(shape, source.getWidth(), source.getHeight()));
        } finally {
            graphics.dispose();
        }
        BufferedImage output = new BufferedImage(source.getWidth(), source.getHeight(), BufferedImage.TYPE_INT_ARGB);
        for (int y = 0; y < source.getHeight(); y++) {
            for (int x = 0; x < source.getWidth(); x++) {
                int argb = source.getRGB(x, y);
                int originalAlpha = (argb >>> 24) & 0xFF;
                int maskAlpha = mask.getRaster().getSample(x, y, 0);
                int alpha = originalAlpha * maskAlpha / 255;
                int rgb = alpha == 0 ? 0x00FFFFFF : (argb & 0x00FFFFFF);
                output.setRGB(x, y, rgb | (alpha << 24));
            }
        }
        return output;
    }

    private static java.awt.Shape formatoRecorte(String shape, int width, int height) {
        if ("circle".equals(shape)) {
            return new Ellipse2D.Double(0, 0, width, height);
        }
        Path2D.Double path = new Path2D.Double();
        if ("triangle".equals(shape)) {
            path.moveTo(width / 2.0, 0);
            path.lineTo(width, height);
            path.lineTo(0, height);
            path.closePath();
            return path;
        }
        path.moveTo(width * 0.25, 0);
        path.lineTo(width * 0.75, 0);
        path.lineTo(width, height / 2.0);
        path.lineTo(width * 0.75, height);
        path.lineTo(width * 0.25, height);
        path.lineTo(0, height / 2.0);
        path.closePath();
        return path;
    }

    private static String valorTexto(Object value, String fallback) {
        return value == null ? fallback : value.toString();
    }

    private static double valorDecimal(Object value, double fallback) {
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

    private static double limitarProporcao(double value) {
        return Math.max(0, Math.min(1, value));
    }

    private static int limitarCor(int value) {
        return Math.max(0, Math.min(255, value));
    }
}
