package com.folhio.api.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.file.Path;
import java.nio.file.Paths;

@Component
public class CaminhosGeradorMaterial {

    private final Path root;
    private final Path docxTemplates;

    public CaminhosGeradorMaterial(
            @Value("${folhio.material-generator.root:material-generator}") String root,
            @Value("${folhio.material-generator.templates.docx:}") String docxTemplates
    ) {
        this.root = Paths.get(root).normalize();
        this.docxTemplates = docxTemplates == null || docxTemplates.isBlank()
                ? this.root.resolve("templates").resolve("docx").normalize()
                : Paths.get(docxTemplates).normalize();
    }

    public Path raiz() {
        return root;
    }

    public Path modelosDocx() {
        return docxTemplates;
    }

    public String modeloDocx(String fileName) {
        Path template = docxTemplates.resolve(fileName).normalize();
        if (!template.startsWith(docxTemplates)) {
            throw new com.folhio.api.handler.validation.exception.DadosInvalidosException("Nome de template inválido.");
        }
        return template.toString().replace('\\', '/');
    }
}
