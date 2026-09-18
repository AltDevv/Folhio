import 'package:flutter/foundation.dart';

import '../../security/authentication/autenticacao_controller.dart';
import '../../model/settings/settings_models.dart';
import '../../repository/settings/configuracoes_conta_repository.dart';

typedef AccountTwoFactorResolver =
    Future<FolhioResultadoAtualizacaoConta> Function(
      FolhioResultadoAtualizacaoConta result,
      Future<FolhioResultadoAtualizacaoConta> Function(String code) onCode,
    );

class ConfiguracoesContaViewModel extends ChangeNotifier {
  final ConfiguracoesContaRepository _repository;

  ConfiguracoesContaViewModel({ConfiguracoesContaRepository? repository})
    : _repository = repository ?? criarRepositoryPadraoConta() {
    _state = _repository.perfilAtual();
  }

  PerfilContaState _state = const PerfilContaState();

  PerfilContaState get state => _state;

  String get name => _state.name;

  String get email => _state.email;

  String get displayName => _state.displayName;

  String get displayEmail => _state.displayEmail;

  ModoEdicaoConta get editMode => _state.editMode;

  bool get savingName => _state.savingName;

  bool get savingEmail => _state.savingEmail;

  bool get savingPassword => _state.savingPassword;

  bool get savingDelete => _state.savingDelete;

  bool get sendingPasswordReset => _state.sendingPasswordReset;

  bool get isSaving => _state.isSaving;

  void sincronizarCamposConta() {
    _state = _state.copiarCom(
      name: _repository.perfilAtual().name,
      email: _repository.perfilAtual().email,
    );
    notifyListeners();
  }

  void iniciarEdicao(ModoEdicaoConta mode) {
    if (isSaving) return;
    final current = _repository.perfilAtual();
    _state = _state.copiarCom(
      name: mode == ModoEdicaoConta.name ? current.name : _state.name,
      email: mode == ModoEdicaoConta.email ? current.email : _state.email,
      editMode: mode,
    );
    notifyListeners();
  }

  void cancelarEdicao() {
    if (isSaving) return;
    final current = _repository.perfilAtual();
    _state = current.copiarCom(editMode: ModoEdicaoConta.none);
    notifyListeners();
  }

  Future<String> salvarNome(String name) async {
    if (name.trim().isEmpty) {
      throw const FolhioAutenticacaoException(
        'Digite o nome que deve aparecer no Folhio.',
      );
    }
    _state = _state.copiarCom(savingName: true);
    notifyListeners();
    try {
      final result = await _repository.atualizarConta(name: name.trim());
      _aplicarResultado(result);
      _state = _state.copiarCom(editMode: ModoEdicaoConta.none);
      return 'Nome atualizado.';
    } finally {
      _state = _state.copiarCom(savingName: false);
      notifyListeners();
    }
  }

  Future<String> salvarEmail({
    required String email,
    required String currentPassword,
    required AccountTwoFactorResolver confirmTwoFactor,
  }) async {
    if (email.trim().isEmpty) {
      throw const FolhioAutenticacaoException('Digite o novo email.');
    }
    if (currentPassword.isEmpty) {
      throw const FolhioAutenticacaoException(
        'Digite sua senha atual para trocar o email.',
      );
    }
    _state = _state.copiarCom(savingEmail: true);
    notifyListeners();
    try {
      var result = await _repository.atualizarConta(
        email: email.trim(),
        currentPassword: currentPassword,
      );
      if (result.twoFactorRequired && result.twoFactorToken != null) {
        result = await confirmTwoFactor(
          result,
          (code) => _repository.atualizarConta(
            email: email.trim(),
            currentPassword: currentPassword,
            twoFactorToken: result.twoFactorToken,
            twoFactorCode: code,
          ),
        );
      }
      _aplicarResultado(result);
      _state = _state.copiarCom(editMode: ModoEdicaoConta.none);
      return 'Email atualizado.';
    } finally {
      _state = _state.copiarCom(savingEmail: false);
      notifyListeners();
    }
  }

  Future<String> salvarSenha({
    required String currentPassword,
    required String newPassword,
    required AccountTwoFactorResolver confirmTwoFactor,
  }) async {
    if (currentPassword.isEmpty) {
      throw const FolhioAutenticacaoException('Digite sua senha atual.');
    }
    if (newPassword.length < 6) {
      throw const FolhioAutenticacaoException(
        'A nova senha precisa ter pelo menos 6 caracteres.',
      );
    }
    _state = _state.copiarCom(savingPassword: true);
    notifyListeners();
    try {
      var result = await _repository.atualizarConta(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (result.twoFactorRequired && result.twoFactorToken != null) {
        result = await confirmTwoFactor(
          result,
          (code) => _repository.atualizarConta(
            currentPassword: currentPassword,
            newPassword: newPassword,
            twoFactorToken: result.twoFactorToken,
            twoFactorCode: code,
          ),
        );
      }
      _aplicarResultado(result);
      _state = _state.copiarCom(editMode: ModoEdicaoConta.none);
      return 'Senha atualizada.';
    } finally {
      _state = _state.copiarCom(savingPassword: false);
      notifyListeners();
    }
  }

  Future<String> solicitarRedefinicaoSenha() async {
    final currentEmail = _repository.perfilAtual().email.trim();
    if (currentEmail.isEmpty) {
      throw const FolhioAutenticacaoException('Não encontramos o email da sua conta.');
    }
    _state = _state.copiarCom(sendingPasswordReset: true);
    notifyListeners();
    try {
      await _repository.solicitarRedefinicaoSenha(currentEmail);
      return 'Enviamos um email com o código para renovar sua senha.';
    } finally {
      _state = _state.copiarCom(sendingPasswordReset: false);
      notifyListeners();
    }
  }

  Future<String> excluirConta({
    required String currentPassword,
    required AccountTwoFactorResolver confirmTwoFactor,
  }) async {
    _state = _state.copiarCom(savingDelete: true);
    notifyListeners();
    try {
      var result = await _repository.excluirConta(
        currentPassword: currentPassword,
      );
      if (result.twoFactorRequired && result.twoFactorToken != null) {
        result = await confirmTwoFactor(
          result,
          (code) => _repository.excluirConta(
            currentPassword: currentPassword,
            twoFactorToken: result.twoFactorToken,
            twoFactorCode: code,
          ),
        );
      }
      await _repository.encerrarSessaoLocal();
      return 'Conta apagada.';
    } finally {
      _state = _state.copiarCom(savingDelete: false);
      notifyListeners();
    }
  }

  void _aplicarResultado(FolhioResultadoAtualizacaoConta result) {
    final user = result.user;
    if (user == null) return;
    _state = _state.copiarCom(name: user.name, email: user.email);
    notifyListeners();
  }
}

ConfiguracoesContaRepository criarRepositoryPadraoConta() {
  return FolhioConfiguracoesContaRepository(auth: AutenticacaoController.instance);
}
