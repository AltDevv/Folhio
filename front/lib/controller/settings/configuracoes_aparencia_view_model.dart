import 'package:flutter/foundation.dart';

import 'aparencia_controller.dart';
import '../../model/settings/settings_models.dart';
import '../../repository/settings/configuracoes_aparencia_repository.dart';

class ConfiguracoesAparenciaViewModel extends ChangeNotifier {
  final ConfiguracoesAparenciaRepository _repository;

  ConfiguracoesAparenciaViewModel({ConfiguracoesAparenciaRepository? repository})
    : _repository = repository ?? criarRepositoryPadraoAparencia() {
    _state = _repository.atual();
  }

  ConfiguracoesAparenciaState _state = const ConfiguracoesAparenciaState();

  String get themeMode => _state.themeMode;

  String get accentColor => _state.accentColor;

  Future<String> definirModoTema(String value) async {
    _state = _state.copiarCom(themeMode: value);
    notifyListeners();
    await _repository.definirModoTema(value);
    _state = _repository.atual();
    notifyListeners();
    return 'Tema atualizado.';
  }

  Future<String> definirCorDestaque(String value) async {
    _state = _state.copiarCom(accentColor: value);
    notifyListeners();
    await _repository.definirCorDestaque(value);
    _state = _repository.atual();
    notifyListeners();
    return 'Cor principal atualizada.';
  }
}

ConfiguracoesAparenciaRepository criarRepositoryPadraoAparencia() {
  return FolhioConfiguracoesAparenciaRepository(
    appearance: AparenciaController.instance,
  );
}
