import 'package:flutter_test/flutter_test.dart';
import 'package:folhio/service/api/folhio_api_gateway.dart';
import 'package:folhio/repository/materials/criacao_material_repository.dart';
import 'package:folhio/controller/materials/criacao_material_view_model.dart';

void main() {
  test(
    'MaterialCreationViewModel carrega catalogo e escolhe padroes',
    () async {
      final repository = _SimuladoMaterialRepository();
      final viewModel = CriacaoMaterialViewModel(
        repository: repository,
        initialMaterialType: 'prova',
      );

      await viewModel.carregar();

      expect(viewModel.loading, isFalse);
      expect(viewModel.error, isNull);
      expect(viewModel.materialType, 'prova');
      expect(viewModel.discipline, 'Matemática');
      expect(viewModel.subject, 'Frações');
      expect(viewModel.schoolYear, '6º ano');
      expect(viewModel.difficulty, 'Fácil');
      expect(viewModel.templateId, 'prova_formal');

      viewModel.dispose();
    },
  );

  test(
    'MaterialCreationViewModel gera DOCX com filtros selecionados',
    () async {
      final repository = _SimuladoMaterialRepository();
      final viewModel = CriacaoMaterialViewModel(
        repository: repository,
        initialMaterialType: 'atividade',
      );
      await viewModel.carregar();

      viewModel
        ..definirDisciplina('Português')
        ..definirAssunto('Interpretação')
        ..definirAnoEscolar('7º ano')
        ..definirDificuldade('Média')
        ..definirQuantidadeQuestoes(12)
        ..definirInclusaoGabarito(false);

      final generated = await viewModel.gerar(
        title: 'Revisão de interpretação',
        teacherName: 'Prof. Ana',
        className: '7A',
        instructions: 'Responda com calma.',
      );

      expect(generated?.fileName, 'revisao.docx');
      expect(viewModel.lastBuilt?.fileId, 'file-1');
      expect(repository.lastRequest?.title, 'Revisão de interpretação');
      expect(repository.lastRequest?.discipline, 'Português');
      expect(repository.lastRequest?.subject, 'Interpretação');
      expect(repository.lastRequest?.schoolYear, '7º ano');
      expect(repository.lastRequest?.difficulty, 'Média');
      expect(repository.lastRequest?.questionCount, 12);
      expect(repository.lastRequest?.includeAnswerKey, isFalse);

      viewModel.dispose();
    },
  );
}

class _SimuladoMaterialRepository implements CriacaoMaterialRepository {
  FolhioGeracaoMaterialRequest? lastRequest;

  @override
  Future<FolhioCatalogoMateriais> catalogo({String discipline = ''}) async {
    final subjects = discipline == 'Português'
        ? ['Interpretação', 'Pontuação']
        : ['Frações', 'Porcentagem'];
    return FolhioCatalogoMateriais(
      disciplines: const ['Matemática', 'Português'],
      subjects: subjects,
      schoolYears: const ['6º ano', '7º ano'],
      difficulties: const ['Fácil', 'Média'],
      templates: const [
        FolhioModeloMaterial(
          id: 'atividade_simples',
          name: 'Atividade simples',
          materialType: 'atividade',
          styleCode: 'simples',
          description: 'Modelo rápido.',
        ),
        FolhioModeloMaterial(
          id: 'prova_formal',
          name: 'Prova formal',
          materialType: 'prova',
          styleCode: 'formal',
          description: 'Modelo de avaliação.',
        ),
      ],
    );
  }

  @override
  Future<List<FolhioModeloMaterial>> modelos({
    String materialType = '',
  }) async {
    return [
      if (materialType == 'prova')
        const FolhioModeloMaterial(
          id: 'prova_formal',
          name: 'Prova formal',
          materialType: 'prova',
          styleCode: 'formal',
          description: 'Modelo de avaliação.',
        )
      else
        const FolhioModeloMaterial(
          id: 'atividade_simples',
          name: 'Atividade simples',
          materialType: 'atividade',
          styleCode: 'simples',
          description: 'Modelo rápido.',
        ),
    ];
  }

  @override
  Future<FolhioMaterialGerado> montar(FolhioGeracaoMaterialRequest request) async {
    lastRequest = request;
    return const FolhioMaterialGerado(
      success: true,
      generatedMaterialId: 'generated-1',
      fileId: 'file-1',
      fileName: 'revisao.docx',
      downloadUrl: '/api/folhio/files/file-1/download',
      templateId: 'atividade_simples',
      questionCount: 12,
      questions: [],
    );
  }

  @override
  Future<List<FolhioResumoMaterialGerado>> gerados({
    int limit = 20,
  }) async {
    return const [];
  }

  @override
  void fechar() {}
}
