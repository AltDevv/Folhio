import 'package:flutter/foundation.dart';

import '../../security/authentication/autenticacao_controller.dart';
import '../../model/settings/settings_models.dart';
import '../../repository/settings/configuracoes_dois_fatores_repository.dart';

typedef TwoFactorSettingsResolver =
    Future<FolhioConfiguracoesDoisFatores> Function(
      FolhioConfiguracoesDoisFatores settings,
      Future<FolhioConfiguracoesDoisFatores> Function(String code) onCode,
    );

class ConfiguracoesDoisFatoresViewModel extends ChangeNotifier {
  final ConfiguracoesDoisFatoresRepository _repository;

  ConfiguracoesDoisFatoresViewModel({ConfiguracoesDoisFatoresRepository? repository})
    : _repository = repository ?? criarRepositoryPadraoDoisFatores();

  ConfiguracoesDoisFatoresState _state = const ConfiguracoesDoisFatoresState();

  ConfiguracoesDoisFatoresState get state => _state;

  bool get enabled => _state.enabled;

  bool get emailAvailable => _state.emailAvailable;

  bool get loading => _state.loading;

  bool get saving => _state.saving;

  bool get signedIn => _state.signedIn;

  String? get savingMessage => _state.savingMessage;

  String get emailLabel => _state.email ?? 'seu email';

  Future<String?> carregar() async {
    if (!_repository.isSignedIn) {
      _state = _state.copiarCom(loading: false, signedIn: false);
      notifyListeners();
      return null;
    }
    try {
      final settings = await _repository.carregar();
      _state = _state.copiarCom(
        enabled: settings.enabled,
        emailAvailable: settings.emailAvailable,
        loading: false,
        signedIn: true,
        email: _repository.email,
      );
      notifyListeners();
      return null;
    } catch (_) {
      _state = _state.copiarCom(loading: false);
      notifyListeners();
      return 'Não foi possível carregar a segurança da conta.';
    }
  }

  Future<String> definirDoisFatores({
    required bool enabled,
    String? currentPassword,
    required TwoFactorSettingsResolver confirmTwoFactor,
  }) async {
    if (enabled && !_state.emailAvailable) {
      return 'O envio de email de segurança ainda não está configurado no servidor.';
    }
    _state = _state.copiarCom(
      saving: true,
      savingMessage: enabled
          ? 'Ativando verificação em duas etapas...'
          : 'Enviando código de confirmação para seu email...',
    );
    notifyListeners();

    try {
      var settings = await _repository.atualizar(
        enabled: enabled,
        currentPassword: currentPassword,
      );
      if (settings.twoFactorRequired && settings.twoFactorToken != null) {
        _state = _state.copiarCom(saving: false, clearSavingMessage: true);
        notifyListeners();
        settings = await confirmTwoFactor(
          settings,
          (code) => _repository.atualizar(
            enabled: enabled,
            currentPassword: currentPassword,
            twoFactorToken: settings.twoFactorToken,
            twoFactorCode: code,
          ),
        );
      }

      _state = _state.copiarCom(
        enabled: settings.enabled,
        emailAvailable: settings.emailAvailable,
        signedIn: _repository.isSignedIn,
        email: _repository.email,
        saving: false,
        clearSavingMessage: true,
      );
      notifyListeners();
      return settings.enabled
          ? 'Verificação em duas etapas ativada.'
          : 'Verificação em duas etapas desativada.';
    } catch (_) {
      _state = _state.copiarCom(saving: false, clearSavingMessage: true);
      notifyListeners();
      rethrow;
    }
  }
}

ConfiguracoesDoisFatoresRepository criarRepositoryPadraoDoisFatores() {
  return FolhioConfiguracoesDoisFatoresRepository(auth: AutenticacaoController.instance);
}
