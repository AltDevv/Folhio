import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../service/api/folhio_api_gateway.dart';
import '../../repository/materials/criacao_material_repository.dart';

class CriacaoMaterialViewModel extends ChangeNotifier {
  final CriacaoMaterialRepository _repository;

  CriacaoMaterialViewModel({
    CriacaoMaterialRepository? repository,
    required String initialMaterialType,
  }) : _repository = repository ?? FolhioCriacaoMaterialRepository(),
       materialType = _normalizarTipoMaterial(initialMaterialType);

  bool loading = false;
  bool generating = false;
  String? error;
  FolhioCatalogoMateriais? catalog;
  List<FolhioModeloMaterial> templates = const [];
  List<FolhioResumoMaterialGerado> recent = const [];

  String materialType;
  String discipline = '';
  String subject = '';
  String schoolYear = '';
  String difficulty = '';
  String templateId = '';
  int questionCount = 8;
  bool includeAnswerKey = true;
  bool shuffleQuestions = true;
  bool shuffleOptions = true;
  FolhioMaterialGerado? lastBuilt;

  static const materialTypes = ['atividade', 'prova', 'lista'];

  String get materialTypeLabel {
    return switch (materialType) {
      'prova' => 'Prova',
      'lista' => 'Lista',
      _ => 'Atividade',
    };
  }

  String get selectedTemplateName {
    return templates
            .where((template) => template.id == templateId)
            .map((template) => template.name)
            .firstOrNull ??
        'Automático';
  }

  bool get canGenerate {
    return !loading &&
        !generating &&
        discipline.trim().isNotEmpty &&
        subject.trim().isNotEmpty;
  }

  Future<void> carregar() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final loadedCatalog = await _repository.catalogo();
      final loadedTemplates = await _repository.modelos(
        materialType: materialType,
      );
      final loadedRecent = await _repository.gerados(limit: 6);
      catalog = loadedCatalog;
      templates = loadedTemplates.isEmpty
          ? loadedCatalog.templates
          : loadedTemplates;
      recent = loadedRecent;
      _selecionarPadroes();
    } catch (exception) {
      error = FolhioApiGateway.humanizarErro(exception);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> definirTipoMaterial(String value) async {
    final nextType = _normalizarTipoMaterial(value);
    if (nextType == materialType) return;
    materialType = nextType;
    templateId = '';
    loading = true;
    error = null;
    notifyListeners();
    try {
      templates = await _repository.modelos(materialType: materialType);
      if (templates.isEmpty) {
        templates = catalog?.templates ?? const [];
      }
      templateId = templates.isEmpty ? '' : templates.first.id;
    } catch (exception) {
      error = FolhioApiGateway.humanizarErro(exception);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void definirDisciplina(String value) {
    if (discipline == value) return;
    discipline = value;
    subject = '';
    notifyListeners();
    unawaited(_recarregarCatalogoPorDisciplina(value));
  }

  void definirAssunto(String value) {
    subject = value;
    notifyListeners();
  }

  void definirAnoEscolar(String value) {
    schoolYear = value;
    notifyListeners();
  }

  void definirDificuldade(String value) {
    difficulty = value;
    notifyListeners();
  }

  void definirModelo(String value) {
    templateId = value;
    notifyListeners();
  }

  void definirQuantidadeQuestoes(int value) {
    questionCount = value.clamp(1, 30).toInt();
    notifyListeners();
  }

  void definirInclusaoGabarito(bool value) {
    includeAnswerKey = value;
    notifyListeners();
  }

  void definirEmbaralharQuestoes(bool value) {
    shuffleQuestions = value;
    notifyListeners();
  }

  void definirEmbaralharOpcoes(bool value) {
    shuffleOptions = value;
    notifyListeners();
  }

  Future<FolhioMaterialGerado?> gerar({
    required String title,
    required String teacherName,
    required String className,
    required String instructions,
  }) async {
    if (!canGenerate) {
      error = 'Escolha disciplina e assunto para gerar o material.';
      notifyListeners();
      return null;
    }

    generating = true;
    error = null;
    notifyListeners();
    try {
      final request = FolhioGeracaoMaterialRequest(
        title: title.trim().isEmpty ? materialTypeLabel : title.trim(),
        materialType: materialType,
        discipline: discipline,
        subject: subject,
        schoolYear: schoolYear,
        difficulty: difficulty,
        templateId: templateId,
        teacherName: teacherName.trim(),
        className: className.trim(),
        instructions: instructions.trim(),
        questionCount: questionCount,
        includeAnswerKey: includeAnswerKey,
        shuffleQuestions: shuffleQuestions,
        shuffleOptions: shuffleOptions,
      );
      final built = await _repository.montar(request);
      lastBuilt = built;
      recent = await _repository.gerados(limit: 6);
      return built;
    } catch (exception) {
      error = FolhioApiGateway.humanizarErro(exception);
      return null;
    } finally {
      generating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _repository.fechar();
    super.dispose();
  }

  void _selecionarPadroes() {
    discipline = _existenteOuPrimeiro(discipline, catalog?.disciplines);
    subject = _existenteOuPrimeiro(subject, catalog?.subjects);
    schoolYear = _existenteOuPrimeiro(schoolYear, catalog?.schoolYears);
    difficulty = _existenteOuPrimeiro(difficulty, catalog?.difficulties);
    templateId = _existenteOuPrimeiro(templateId, templates.map((e) => e.id));
  }

  Future<void> _recarregarCatalogoPorDisciplina(String value) async {
    try {
      final loadedCatalog = await _repository.catalogo(discipline: value);
      catalog = loadedCatalog;
      subject = _existenteOuPrimeiro(subject, loadedCatalog.subjects);
      schoolYear = _existenteOuPrimeiro(schoolYear, loadedCatalog.schoolYears);
      difficulty = _existenteOuPrimeiro(difficulty, loadedCatalog.difficulties);
      notifyListeners();
    } catch (_) {
      // Manter o catálogo anterior é melhor do que apagar as opções da tela.
    }
  }

  static String _existenteOuPrimeiro(String current, Iterable<String>? values) {
    final list = values?.where((item) => item.trim().isNotEmpty).toList();
    if (list == null || list.isEmpty) return current;
    if (list.contains(current)) return current;
    return list.first;
  }

  static String _normalizarTipoMaterial(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('prova')) return 'prova';
    if (normalized.contains('lista')) return 'lista';
    return 'atividade';
  }
}

extension _PrimeiroOuNuloExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
