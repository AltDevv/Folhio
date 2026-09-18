import '../../dto/folhio_action.dart';
import '../../service/api/folhio_api_gateway.dart';

/// Controller da geraï¿½ï¿½o com IA.
///
/// O backend pode receber este JSON, chamar um provedor de IA, salvar o
/// resultado e devolver um PDF, DOCX ou texto editï¿½vel para o Flutter.
class IaController {
  final FolhioApiGateway api;

  IaController(this.api);

  Future<FolhioAcaoResponse> gerarMaterialDidatico({
    required String materialType,
    required String subject,
    required String topic,
    required int questionCount,
    required String difficulty,
    required bool includeAnswerKey,
  }) {
    return api.enviar(
      FolhioAcaoRequest(
        requestId: criarIdRequisicao('ai-generate'),
        category: 'ai',
        type: 'generate_teaching_material',
        title: 'Gerar com IA',
        description:
            'Gera prova, atividade, plano de aula ou material escolar com IA.',
        payload: {
          'materialType': materialType,
          'subject': subject,
          'topic': topic,
          'questionCount': questionCount,
          'difficulty': difficulty,
          'includeAnswerKey': includeAnswerKey,
          'language': 'pt-BR',
          'output': {'format': 'pdf', 'alsoReturnEditableText': true},
        },
      ),
    );
  }
}
