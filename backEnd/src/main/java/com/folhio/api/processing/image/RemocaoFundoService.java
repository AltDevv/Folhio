package com.folhio.api.processing.image;

import ai.onnxruntime.OnnxTensor;
import ai.onnxruntime.OnnxValue;
import ai.onnxruntime.OrtEnvironment;
import ai.onnxruntime.OrtException;
import ai.onnxruntime.OrtSession;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.FloatBuffer;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;

@Service
public class RemocaoFundoService {

    private static final int MODEL_SIZE = 320;
    private static final float[] MEAN = {0.485f, 0.456f, 0.406f};
    private static final float[] STD = {0.229f, 0.224f, 0.225f};

    private final boolean enabled;
    private final Path modelPath;

    private OrtEnvironment environment;
    private OrtSession session;
    private String inputName;

    public RemocaoFundoService(
            @Value("${folhio.ai.background-removal-enabled:true}") boolean enabled,
            @Value("${folhio.ai.background-removal-model:models/u2net.onnx}") String modelPath
    ) {
        this.enabled = enabled;
        this.modelPath = resolverCaminhoModelo(modelPath);
    }

    public BufferedImage removerFundo(BufferedImage source) throws IOException {
        if (!enabled) {
            throw new IOException("Removedor de fundo por IA desativado.");
        }
        if (!Files.exists(modelPath)) {
            throw new IOException("Modelo ONNX não encontrado em " + modelPath.toAbsolutePath());
        }

        try {
            garantirSessao();
            float[] input = preprocessar(source);
            try (OnnxTensor tensor = OnnxTensor.createTensor(
                    environment,
                    FloatBuffer.wrap(input),
                    new long[]{1, 3, MODEL_SIZE, MODEL_SIZE}
            );
                 OrtSession.Result result = session.run(Map.of(inputName, tensor))) {
                float[] mask = lerMascara(result.get(0));
                return aplicarMascara(source, mask);
            }
        } catch (OrtException | RuntimeException exception) {
            throw new IOException("Falha ao remover fundo com ONNX.", exception);
        }
    }

    private synchronized void garantirSessao() throws OrtException {
        if (session != null) {
            return;
        }
        environment = OrtEnvironment.getEnvironment();
        OrtSession.SessionOptions options = new OrtSession.SessionOptions();
        options.setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT);
        session = environment.createSession(modelPath.toAbsolutePath().toString(), options);
        inputName = session.getInputNames().iterator().next();
    }

    private float[] preprocessar(BufferedImage source) {
        BufferedImage resized = new BufferedImage(MODEL_SIZE, MODEL_SIZE, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = resized.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            graphics.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            graphics.setColor(Color.WHITE);
            graphics.fillRect(0, 0, MODEL_SIZE, MODEL_SIZE);
            graphics.drawImage(source, 0, 0, MODEL_SIZE, MODEL_SIZE, null);
        } finally {
            graphics.dispose();
        }

        float[] input = new float[3 * MODEL_SIZE * MODEL_SIZE];
        int plane = MODEL_SIZE * MODEL_SIZE;
        for (int y = 0; y < MODEL_SIZE; y++) {
            for (int x = 0; x < MODEL_SIZE; x++) {
                int rgb = resized.getRGB(x, y);
                int index = y * MODEL_SIZE + x;
                input[index] = ((((rgb >>> 16) & 0xFF) / 255.0f) - MEAN[0]) / STD[0];
                input[plane + index] = ((((rgb >>> 8) & 0xFF) / 255.0f) - MEAN[1]) / STD[1];
                input[(2 * plane) + index] = (((rgb & 0xFF) / 255.0f) - MEAN[2]) / STD[2];
            }
        }
        return input;
    }

    private float[] lerMascara(OnnxValue value) throws OrtException, IOException {
        if (!(value instanceof OnnxTensor tensor)) {
            throw new IOException("Saída ONNX inesperada para remoção de fundo.");
        }
        FloatBuffer buffer = tensor.getFloatBuffer();
        float[] raw = new float[buffer.remaining()];
        buffer.get(raw);
        int maskSize = MODEL_SIZE * MODEL_SIZE;
        if (raw.length < maskSize) {
            throw new IOException("Máscara ONNX menor que o esperado.");
        }

        float[] mask = new float[maskSize];
        System.arraycopy(raw, 0, mask, 0, maskSize);
        normalizar(mask);
        return mask;
    }

    private void normalizar(float[] mask) {
        float min = Float.POSITIVE_INFINITY;
        float max = Float.NEGATIVE_INFINITY;
        for (float value : mask) {
            min = Math.min(min, value);
            max = Math.max(max, value);
        }
        float range = Math.max(0.00001f, max - min);
        for (int i = 0; i < mask.length; i++) {
            mask[i] = limitarEntreZeroEUm((mask[i] - min) / range);
        }
    }

    private BufferedImage aplicarMascara(BufferedImage source, float[] mask) {
        BufferedImage maskImage = new BufferedImage(MODEL_SIZE, MODEL_SIZE, BufferedImage.TYPE_BYTE_GRAY);
        for (int y = 0; y < MODEL_SIZE; y++) {
            for (int x = 0; x < MODEL_SIZE; x++) {
                int alpha = Math.round(mask[y * MODEL_SIZE + x] * 255);
                int gray = (alpha << 16) | (alpha << 8) | alpha;
                maskImage.setRGB(x, y, gray);
            }
        }

        BufferedImage scaledMask = new BufferedImage(source.getWidth(), source.getHeight(), BufferedImage.TYPE_BYTE_GRAY);
        Graphics2D graphics = scaledMask.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            graphics.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            graphics.drawImage(maskImage, 0, 0, source.getWidth(), source.getHeight(), null);
        } finally {
            graphics.dispose();
        }

        BufferedImage output = new BufferedImage(source.getWidth(), source.getHeight(), BufferedImage.TYPE_INT_ARGB);
        for (int y = 0; y < source.getHeight(); y++) {
            for (int x = 0; x < source.getWidth(); x++) {
                int argb = source.getRGB(x, y);
                int originalAlpha = (argb >>> 24) & 0xFF;
                int maskAlpha = scaledMask.getRaster().getSample(x, y, 0);
                int nextAlpha = Math.round(originalAlpha * (maskAlpha / 255.0f));
                output.setRGB(x, y, (nextAlpha << 24) | (argb & 0x00FFFFFF));
            }
        }
        return output;
    }

    private float limitarEntreZeroEUm(float value) {
        return Math.max(0.0f, Math.min(1.0f, value));
    }

    private Path resolverCaminhoModelo(String configuredPath) {
        Path path = Path.of(configuredPath);
        if (path.isAbsolute()) {
            return path;
        }
        if (Files.exists(path)) {
            return path;
        }
        Path backendRelative = Path.of("back(api)").resolve(path);
        if (Files.exists(backendRelative)) {
            return backendRelative;
        }
        return path;
    }
}
