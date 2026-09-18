import 'package:flutter/foundation.dart';

import '../../security/authentication/autenticacao_controller.dart';
import '../../repository/local/persistencia_local_repository.dart';
import '../../repository/settings/configuracoes_repository.dart';

class ConfiguracoesViewModel extends ChangeNotifier {
  final ConfiguracoesRepository _repository;

  ConfiguracoesViewModel({ConfiguracoesRepository? repository})
    : _repository = repository ?? criarRepositoryPadraoConfiguracoes();

  String _profileName = 'Professor';

  String get profileName => _profileName;

  Future<void> carregarResumo() async {
    final storedName = await _repository.nomePerfilArmazenado();
    _profileName =
        _repository.nomePerfilAutenticado() ??
        (storedName?.trim().isNotEmpty == true
            ? storedName!.trim()
            : 'Professor');
    notifyListeners();
  }

  Future<void> encerrarSessao() {
    return _repository.encerrarSessao();
  }
}

ConfiguracoesRepository criarRepositoryPadraoConfiguracoes() {
  return ConfiguracoesLocaisRepository(
    local: PersistenciaLocalRepository.instance,
    auth: AutenticacaoController.instance,
  );
}
