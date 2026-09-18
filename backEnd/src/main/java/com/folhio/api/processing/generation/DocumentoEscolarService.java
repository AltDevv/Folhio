package com.folhio.api.processing.generation;

import com.folhio.api.dto.action.AcaoRequest;
import com.folhio.api.dto.action.AcaoResponse;
import com.folhio.api.common.util.MapasJson;
import com.folhio.api.service.ArquivoArmazenadoService;
import com.folhio.api.files.model.ArquivoArmazenado;
import com.folhio.api.progress.ProgressoTracker;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DocumentoEscolarService {

    private static final List<String> SAMPLE_STUDENTS = List.of(
            "Ana Clara", "Bruno Lima", "Carla Souza", "Daniel Rocha", "Eduarda Alves",
            "Felipe Costa", "Gabriela Nunes", "Henrique Dias", "Isabela Ramos", "Joao Pedro"
    );

    private final ArquivoArmazenadoService storageService;

    public DocumentoEscolarService(ArquivoArmazenadoService storageService) {
        this.storageService = storageService;
    }

    public AcaoResponse gerarListaChamada(AcaoRequest request, String className) {
        Map<String, Object> fields = MapasJson.filho(request.payload(), "fields");
        boolean includeSignature = MapasJson.booleano(fields, "includeTeacherSignature", true);
        boolean includeObservations = MapasJson.booleano(fields, "includeObservations", false);
        String dateMode = modoDataImpressa(MapasJson.texto(request.payload(), "dateMode", "today"));
        List<AlunoChamada> requestedStudents = alunosChamada(request.payload());
        final List<AlunoChamada> students = requestedStudents.isEmpty()
                ? alunosExemploChamada()
                : requestedStudents;

        ArquivoArmazenado file = storageService.salvarSaida("chamada-para-imprimir-" + nomeSeguro(className) + ".pdf", "application/pdf", target -> {
            ProgressoTracker.atualizar(0.20, "Montando chamada");
            try (PDDocument document = new PDDocument()) {
                PDPage page = new PDPage(PDRectangle.A4);
                document.addPage(page);
                try (PDPageContentStream stream = new PDPageContentStream(document, page)) {
                    escreverTitulo(stream, "Chamada para imprimir - " + className, 760);
                    escreverLinha(stream, "Data: " + dateMode + "    Disciplina: ____________________", 730);
                    escreverLinha(stream, "Professor(a): ________________________________", 710);

                    float y = 675;
                    int total = Math.max(1, students.size());
                    for (int i = 0; i < students.size(); i++) {
                        AlunoChamada student = students.get(i);
                        String observation = includeObservations ? "    Obs: __________________" : "";
                        String registration = student.registration().isBlank() ? "" : " (" + student.registration() + ")";
                        String marks = "absent".equals(student.status())
                                ? "[ ] Presente    [x] Falta"
                                : "[x] Presente    [ ] Falta";
                        escreverLinha(stream, (i + 1) + ". " + student.name() + registration + "    " + marks + observation, y);
                        y -= 28;
                        ProgressoTracker.atualizar(0.25 + ((i + 1) * 0.60 / total), "Adicionando aluno " + (i + 1));
                    }

                    if (includeSignature) {
                        escreverLinha(stream, "Assinatura do professor: ________________________________", 120);
                    }
                }
                document.save(target.toFile());
            }
            ProgressoTracker.atualizar(0.95, "PDF da chamada salvo");
        });

        return concluido(request, "Chamada gerada com sucesso.", file);
    }

    private List<AlunoChamada> alunosChamada(Map<String, Object> payload) {
        List<AlunoChamada> students = new ArrayList<>();
        for (Object item : MapasJson.listar(payload, "students")) {
            if (!(item instanceof Map<?, ?> raw)) {
                continue;
            }
            Map<String, Object> studentMap = new HashMap<>();
            for (Map.Entry<?, ?> entry : raw.entrySet()) {
                if (entry.getKey() != null) {
                    studentMap.put(entry.getKey().toString(), entry.getValue());
                }
            }
            String name = MapasJson.texto(studentMap, "name", "").trim();
            if (name.isBlank()) {
                continue;
            }
            String registration = MapasJson.texto(studentMap, "registration", "").trim();
            String status = MapasJson.texto(studentMap, "status", "present").trim().toLowerCase();
            students.add(new AlunoChamada(name, registration, status));
        }
        return students;
    }

    private List<AlunoChamada> alunosExemploChamada() {
        return SAMPLE_STUDENTS.stream()
                .map(name -> new AlunoChamada(name, "", "present"))
                .toList();
    }

    public AcaoResponse gerarPlanilhaNotas(AcaoRequest request, String className) {
        String period = MapasJson.texto(request.payload(), "period", "bimestre");
        String model = MapasJson.texto(request.payload(), "model", "test_work");

        ArquivoArmazenado file = storageService.salvarSaida("notas-e-medias-" + nomeSeguro(className) + ".xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", target -> {
                    ProgressoTracker.atualizar(0.20, "Criando notas e medias");
                    try (XSSFWorkbook workbook = new XSSFWorkbook()) {
                        XSSFSheet sheet = workbook.createSheet("Notas e medias");
                        Font headerFont = workbook.createFont();
                        headerFont.setBold(true);
                        CellStyle headerStyle = workbook.createCellStyle();
                        headerStyle.setFont(headerFont);

                        Row title = sheet.createRow(0);
                        title.createCell(0).setCellValue("Turma");
                        title.createCell(1).setCellValue(className);
                        title.createCell(3).setCellValue("Periodo");
                        title.createCell(4).setCellValue(period);

                        Row header = sheet.createRow(2);
                        String[] columns = colunasNotas(model);
                        for (int i = 0; i < columns.length; i++) {
                            header.createCell(i).setCellValue(columns[i]);
                            header.getCell(i).setCellStyle(headerStyle);
                        }

                        for (int i = 0; i < SAMPLE_STUDENTS.size(); i++) {
                            Row row = sheet.createRow(i + 3);
                            row.createCell(0).setCellValue(SAMPLE_STUDENTS.get(i));
                            preencherLinhaNotas(row, model, i + 4);
                            ProgressoTracker.atualizar(0.25 + ((i + 1) * 0.60 / SAMPLE_STUDENTS.size()), "Criando linha " + (i + 1));
                        }

                        for (int i = 0; i < columns.length; i++) {
                            sheet.autoSizeColumn(i);
                        }
                        workbook.write(java.nio.file.Files.newOutputStream(target));
                    }
                    ProgressoTracker.atualizar(0.95, "Planilha salva");
                });

        return concluido(request, "Planilha de notas e medias criada com sucesso.", file);
    }

    public AcaoResponse gerarComunicadosIndividuais(AcaoRequest request, String className, String messageTemplate) {
        boolean includeSignature = MapasJson.booleano(request.payload(), "includeResponsibleSignature", true);

        ArquivoArmazenado file = storageService.salvarSaida("comunicados-" + nomeSeguro(className) + ".pdf", "application/pdf", target -> {
            ProgressoTracker.atualizar(0.20, "Montando comunicados");
            try (PDDocument document = new PDDocument()) {
                for (int i = 0; i < SAMPLE_STUDENTS.size(); i++) {
                    String student = SAMPLE_STUDENTS.get(i);
                    PDPage page = new PDPage(PDRectangle.A4);
                    document.addPage(page);
                    try (PDPageContentStream stream = new PDPageContentStream(document, page)) {
                        escreverTitulo(stream, "Comunicado aos responsaveis", 760);
                        escreverLinha(stream, "Aluno: " + student + "    Turma: " + className, 720);
                        escreverLinha(stream, limparTextoPdf(messageTemplate), 680);
                        escreverLinha(stream, "Observacao do professor: __________________________________________", 640);
                        if (includeSignature) {
                            escreverLinha(stream, "Assinatura do responsavel: ________________________________", 600);
                        }
                    }
                    ProgressoTracker.atualizar(0.25 + ((i + 1) * 0.60 / SAMPLE_STUDENTS.size()), "Criando comunicado " + (i + 1));
                }
                document.save(target.toFile());
            }
            ProgressoTracker.atualizar(0.95, "PDF de comunicados salvo");
        });

        return concluido(request, "Comunicados gerados com sucesso.", file);
    }

    private AcaoResponse concluido(AcaoRequest request, String message, ArquivoArmazenado file) {
        return AcaoResponse.sucesso(
                request.requestId(),
                message,
                Map.of("tool", request.type()),
                new AcaoResponse.ArquivoSaida(
                        file.originalFileName(),
                        file.contentType(),
                        file.sizeBytes(),
                        "/api/folhio/files/" + file.id() + "/download",
                        file.id()
                )
        );
    }

    private String[] colunasNotas(String model) {
        return switch (model) {
            case "simple_average" -> new String[]{"Aluno", "Nota 1", "Nota 2", "Nota 3", "Media", "Observacoes"};
            case "recovery" -> new String[]{"Aluno", "Media", "Recuperacao", "Media final", "Situacao", "Observacoes"};
            default -> new String[]{"Aluno", "Prova", "Trabalho", "Media", "Situacao", "Observacoes"};
        };
    }

    private void preencherLinhaNotas(Row row, String model, int spreadsheetRow) {
        switch (model) {
            case "simple_average" -> {
                row.createCell(1).setCellValue("");
                row.createCell(2).setCellValue("");
                row.createCell(3).setCellValue("");
                row.createCell(4).setCellFormula("IF(COUNTA(B" + spreadsheetRow + ":D" + spreadsheetRow + ")=0,\"\",AVERAGE(B" + spreadsheetRow + ":D" + spreadsheetRow + "))");
                row.createCell(5).setCellValue("");
            }
            case "recovery" -> {
                row.createCell(1).setCellValue("");
                row.createCell(2).setCellValue("");
                row.createCell(3).setCellFormula("IF(COUNTA(B" + spreadsheetRow + ":C" + spreadsheetRow + ")=0,\"\",MAX(B" + spreadsheetRow + ",C" + spreadsheetRow + "))");
                row.createCell(4).setCellFormula("IF(D" + spreadsheetRow + "=\"\",\"\",IF(D" + spreadsheetRow + ">=6,\"Aprovado\",\"Recuperacao\"))");
                row.createCell(5).setCellValue("");
            }
            default -> {
                row.createCell(1).setCellValue("");
                row.createCell(2).setCellValue("");
                row.createCell(3).setCellFormula("IF(COUNTA(B" + spreadsheetRow + ":C" + spreadsheetRow + ")=0,\"\",AVERAGE(B" + spreadsheetRow + ":C" + spreadsheetRow + "))");
                row.createCell(4).setCellFormula("IF(D" + spreadsheetRow + "=\"\",\"\",IF(D" + spreadsheetRow + ">=6,\"Ok\",\"Atencao\"))");
                row.createCell(5).setCellValue("");
            }
        }
    }

    private String modoDataImpressa(String dateMode) {
        return switch (dateMode) {
            case "tomorrow" -> "Amanha";
            case "custom" -> "Personalizada";
            default -> "Hoje";
        };
    }

    private void escreverTitulo(PDPageContentStream stream, String text, float y) throws java.io.IOException {
        stream.beginText();
        stream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 18);
        stream.newLineAtOffset(50, y);
        stream.showText(limparTextoPdf(text));
        stream.endText();
    }

    private void escreverLinha(PDPageContentStream stream, String text, float y) throws java.io.IOException {
        stream.beginText();
        stream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 12);
        stream.newLineAtOffset(50, y);
        stream.showText(limparTextoPdf(text).replace("\n", " "));
        stream.endText();
    }

    private String limparTextoPdf(String text) {
        if (text == null) {
            return "";
        }
        return text
                .replace('\u2013', '-')
                .replace('\u2014', '-')
                .replace('\u2018', '\'')
                .replace('\u2019', '\'')
                .replace('\u201c', '"')
                .replace('\u201d', '"')
                .replace('ç', 'c')
                .replace('Ç', 'C')
                .replace('ã', 'a')
                .replace('Ã', 'A')
                .replace('á', 'a')
                .replace('Á', 'A')
                .replace('à', 'a')
                .replace('À', 'A')
                .replace('â', 'a')
                .replace('Â', 'A')
                .replace('é', 'e')
                .replace('É', 'E')
                .replace('ê', 'e')
                .replace('Ê', 'E')
                .replace('í', 'i')
                .replace('Í', 'I')
                .replace('ó', 'o')
                .replace('Ó', 'O')
                .replace('õ', 'o')
                .replace('Õ', 'O')
                .replace('ô', 'o')
                .replace('Ô', 'O')
                .replace('ú', 'u')
                .replace('Ú', 'U')
                .replaceAll("[^\\x20-\\x7E]", "?");
    }

    private String nomeSeguro(String value) {
        return value == null || value.isBlank() ? "turma" : value.replaceAll("[^a-zA-Z0-9_-]+", "-");
    }

    private record AlunoChamada(String name, String registration, String status) {
    }
}
