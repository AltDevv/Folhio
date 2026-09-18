import '../../dto/folhio_action.dart';
import '../../service/api/folhio_api_gateway.dart';

/// Controller das Tools, que sÃ£o rotinas escolares do professor.
///
/// Diferente de EdiÃ§Ã£o, aqui o backend pode gerar documentos a partir de dados
/// estruturados: turmas, alunos, notas, datas e padrÃµes de organizaÃ§Ã£o.
class FerramentasController {
  final FolhioApiGateway api;

  FerramentasController(this.api);

  Future<FolhioAcaoResponse> gerarListaPresenca({
    required String classId,
    required String className,
    required String dateMode,
    required bool includeTeacherSignature,
    required bool includeObservations,
    List<Map<String, dynamic>> students = const [],
  }) {
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('tools-attendance'),
        category: 'tools',
        type: 'attendance_list',
        title: 'Chamada para imprimir',
        description:
            'Gera uma folha de presenÃ§a em PDF para imprimir e usar em aula.',
        payload: {
          'class': {'id': classId, 'name': className},
          'students': students,
          'dateMode': dateMode,
          'fields': {
            'includeTeacherSignature': includeTeacherSignature,
            'includeObservations': includeObservations,
          },
          'output': {'format': 'pdf'},
        },
      ),
    );
  }

  Future<FolhioAcaoResponse> gerarPlanilhaNotas({
    required String classId,
    required String className,
    required String period,
    required String model,
  }) {
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('tools-grades'),
        category: 'tools',
        type: 'grade_sheet',
        title: 'Notas e mÃ©dias',
        description:
            'Gera uma planilha com modelos de notas e cÃ¡lculo de mÃ©dias.',
        payload: {
          'class': {'id': classId, 'name': className},
          'period': period,
          'model': model,
          'output': {'format': 'xlsx'},
        },
      ),
    );
  }

  Future<FolhioAcaoResponse> gerarComunicadosIndividuais({
    required String classId,
    required String className,
    required String messageTemplate,
    required bool includeResponsibleSignature,
  }) {
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('tools-note'),
        category: 'tools',
        type: 'individual_note',
        title: 'Comunicados',
        description: 'Gera comunicados individuais para responsÃ¡veis.',
        payload: {
          'class': {'id': classId, 'name': className},
          'messageTemplate': messageTemplate,
          'includeResponsibleSignature': includeResponsibleSignature,
          'output': {'format': 'pdf'},
        },
      ),
    );
  }

  Future<FolhioAcaoResponse> renomearEmLote({
    required List<Map<String, dynamic>> files,
    required String pattern,
    required bool keepOriginalDate,
  }) {
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('tools-rename'),
        category: 'tools',
        type: 'batch_rename',
        title: 'Renomear em lote',
        description:
            'Gera novos nomes para vÃ¡rios arquivos seguindo um padrÃ£o.',
        payload: {
          'files': files,
          'pattern': pattern,
          'keepOriginalDate': keepOriginalDate,
        },
      ),
    );
  }

  Future<FolhioAcaoResponse> organizarPorTurma({
    required List<Map<String, dynamic>> files,
    required String organizationMode,
    required bool createMissingFolders,
  }) {
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('tools-organize'),
        category: 'tools',
        type: 'organize_by_class',
        title: 'Organizar por turma',
        description:
            'Organiza arquivos em pastas por turma, disciplina ou bimestre.',
        payload: {
          'files': files,
          'organizationMode': organizationMode,
          'createMissingFolders': createMissingFolders,
        },
      ),
    );
  }

  Future<FolhioAcaoResponse> carimbarDocumentos({
    required List<Map<String, dynamic>> files,
    required Map<String, dynamic> signature,
    required Map<String, dynamic> placement,
  }) {
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('tools-stamp'),
        category: 'tools',
        type: 'stamp_documents',
        title: 'Assinar documentos',
        description:
            'Aplica uma assinatura ou carimbo na mesma posicao em PDFs e imagens.',
        payload: {
          'files': files,
          'signature': signature,
          'placement': placement,
        },
      ),
    );
  }
}
