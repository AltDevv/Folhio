package com.folhio.api.security.antivirus;

import com.folhio.api.service.RegistroSistemaService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Map;

@Service
public class VerificacaoArquivoService {

    private static final int CHUNK_SIZE = 64 * 1024;

    private final boolean enabled;
    private final boolean required;
    private final String host;
    private final int port;
    private final Duration timeout;
    private final RegistroSistemaService registros;

    public VerificacaoArquivoService(
            @Value("${folhio.file-scanner.enabled:true}") boolean enabled,
            @Value("${folhio.file-scanner.required:false}") boolean required,
            @Value("${folhio.file-scanner.clamav.host:localhost}") String host,
            @Value("${folhio.file-scanner.clamav.port:3310}") int port,
            @Value("${folhio.file-scanner.timeout-seconds:45}") long timeoutSeconds,
            RegistroSistemaService registros
    ) {
        this.enabled = enabled;
        this.required = required;
        this.host = host;
        this.port = port;
        this.timeout = Duration.ofSeconds(Math.max(1, timeoutSeconds));
        this.registros = registros;
    }

    public void verificarEnvio(Path file, String originalName, long size) {
        if (!enabled) {
            return;
        }

        try {
            String response = verificarComClamAv(file);
            if (response.endsWith(" FOUND")) {
                registros.aviso(
                        "ARQUIVO",
                        "arquivo.scan.infectado",
                        "Upload bloqueado pelo ClamAV.",
                        Map.of("fileName", originalName, "size", size, "response", response)
                );
                throw new com.folhio.api.handler.file.exception.ArquivoBloqueadoException("Arquivo bloqueado pela verificação de segurança.");
            }
            if (!response.endsWith(" OK")) {
                tratarErroVerificacao(originalName, size, "Resposta inesperada do ClamAV: " + response, null);
                return;
            }
            registros.informacao(
                    "ARQUIVO",
                    "arquivo.scan.ok",
                    "Upload aprovado pelo ClamAV.",
                    Map.of("fileName", originalName, "size", size)
            );
        } catch (IOException error) {
            tratarErroVerificacao(originalName, size, "Nao foi possivel consultar o ClamAV.", error);
        }
    }

    private String verificarComClamAv(Path file) throws IOException {
        try (Socket socket = new Socket()) {
            int timeoutMs = Math.toIntExact(Math.min(Integer.MAX_VALUE, timeout.toMillis()));
            socket.connect(new InetSocketAddress(host, port), timeoutMs);
            socket.setSoTimeout(timeoutMs);

            try (OutputStream output = socket.getOutputStream();
                 InputStream input = socket.getInputStream();
                 InputStream fileInput = Files.newInputStream(file)) {
                output.write("zINSTREAM\0".getBytes(StandardCharsets.US_ASCII));
                byte[] buffer = new byte[CHUNK_SIZE];
                int read;
                while ((read = fileInput.read(buffer)) >= 0) {
                    output.write(ByteBuffer.allocate(4).putInt(read).array());
                    output.write(buffer, 0, read);
                }
                output.write(new byte[]{0, 0, 0, 0});
                output.flush();
                return lerResposta(input);
            }
        }
    }

    private String lerResposta(InputStream input) throws IOException {
        StringBuilder response = new StringBuilder();
        int next;
        while ((next = input.read()) >= 0) {
            if (next == 0 || next == '\n') {
                break;
            }
            response.append((char) next);
            if (response.length() > 4096) throw new IOException("ClamAV response too large.");
        }
        return response.toString().trim();
    }

    private void tratarErroVerificacao(String originalName, long size, String message, Exception error) {
        Map<String, Object> details = Map.of(
                "fileName", originalName,
                "size", size,
                "required", required
        );
        if (required) {
            registros.erro("ARQUIVO", "arquivo.scan.erro", message, error, details);
            throw new com.folhio.api.handler.integration.exception.VerificacaoArquivoIndisponivelException("Não foi possível verificar o arquivo.");
        }
        registros.aviso("ARQUIVO", "arquivo.scan.indisponivel", message, details);
    }
}
