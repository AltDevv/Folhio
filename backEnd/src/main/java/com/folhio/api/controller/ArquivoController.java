package com.folhio.api.controller;

import com.folhio.api.dto.file.ArquivoResponse;
import com.folhio.api.security.IdentidadeCliente;
import com.folhio.api.security.authentication.UsuarioAutenticado;
import com.folhio.api.service.ArquivoService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;
import java.nio.charset.StandardCharsets;

@RestController
@RequestMapping("/api/folhio/files")
public class ArquivoController {
    private final ArquivoService files;

    public ArquivoController(ArquivoService files) {
        this.files = files;
    }

    @PostMapping("/upload")
    public ArquivoResponse enviarArquivo(@RequestParam("file") MultipartFile file,
                               @RequestParam(defaultValue = "false") boolean persistent,
                               HttpServletRequest request) {
        return files.enviarArquivo(file, IdentidadeCliente.obrigatorio(request), identificadorUsuario(request),
                persistent, request.getHeader("X-Request-Id"));
    }

    @GetMapping("/{fileId}")
    public ArquivoResponse metadados(@PathVariable String fileId, HttpServletRequest request) {
        return files.metadados(fileId, IdentidadeCliente.obrigatorio(request), identificadorUsuario(request));
    }

    @GetMapping("/{fileId}/download")
    public ResponseEntity<StreamingResponseBody> baixar(@PathVariable String fileId, HttpServletRequest request) {
        var file = files.buscar(fileId, IdentidadeCliente.obrigatorio(request), identificadorUsuario(request));
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(file.contentType()))
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment()
                        .filename(file.originalFileName(), StandardCharsets.UTF_8).build().toString())
                .contentLength(file.sizeBytes())
                .body(output -> files.baixar(file, output));
    }

    @GetMapping("/{fileId}/preview")
    public ResponseEntity<byte[]> visualizarPrevia(@PathVariable String fileId,
                                          @RequestParam(defaultValue = "1") int page,
                                          HttpServletRequest request) {
        return ResponseEntity.ok().contentType(MediaType.IMAGE_PNG)
                .body(files.visualizarPrevia(fileId, IdentidadeCliente.obrigatorio(request), identificadorUsuario(request), page));
    }

    private String identificadorUsuario(HttpServletRequest request) {
        return request.getAttribute(UsuarioAutenticado.REQUEST_ATTRIBUTE) instanceof UsuarioAutenticado user
                ? user.id() : null;
    }
}
