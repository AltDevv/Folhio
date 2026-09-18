import 'package:flutter/foundation.dart';

import 'aparencia_controller.dart';
import '../../repository/local/persistencia_local_repository.dart';
import '../../model/settings/settings_models.dart';
import '../../repository/settings/configuracoes_acessibilidade_repository.dart';

class ConfiguracoesAcessibilidadeViewModel extends ChangeNotifier {
  final ConfiguracoesAcessibilidadeRepository _repository;

  ConfiguracoesAcessibilidadeViewModel({ConfiguracoesAcessibilidadeRepository? repository})
    : _repository =
          repository ?? criarRepositoryPadraoAcessibilidade();

  ConfiguracoesAcessibilidadeState _state = const ConfiguracoesAcessibilidadeState();

  ConfiguracoesAcessibilidadeState get state => _state;

  bool get highContrast => _state.highContrast;

  bool get extraDescriptions => _state.extraDescriptions;

  String get fontSize => _state.fontSize;

  Future<void> carregar() async {
    _state = await _repository.carregar();
    notifyListeners();
  }

  Future<String> definirAltoContraste(bool value) async {
    _state = _state.copiarCom(highContrast: value);
    notifyListeners();
    await _repository.definirAltoContraste(value);
    return 'Preferencia salva.';
  }

  Future<String> definirDescricoesExtras(bool value) async {
    _state = _state.copiarCom(extraDescriptions: value);
    notifyListeners();
    await _repository.definirDescricoesExtras(value);
    return 'Preferencia salva.';
  }

  Future<String> definirTamanhoFonte(String value) async {
    _state = _state.copiarCom(fontSize: value);
    notifyListeners();
    await _repository.definirTamanhoFonte(value);
    return 'Tamanho da fonte atualizado.';
  }
}

ConfiguracoesAcessibilidadeRepository criarRepositoryPadraoAcessibilidade() {
  return ConfiguracoesAcessibilidadeLocalRepository(
    local: PersistenciaLocalRepository.instance,
    appearance: AparenciaController.instance,
  );
}
