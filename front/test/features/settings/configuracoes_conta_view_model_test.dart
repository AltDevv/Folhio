import 'package:flutter_test/flutter_test.dart';
import 'package:folhio/security/authentication/autenticacao_controller.dart';
import 'package:folhio/model/settings/settings_models.dart';
import 'package:folhio/repository/settings/configuracoes_conta_repository.dart';
import 'package:folhio/controller/settings/configuracoes_conta_view_model.dart';

void main() {
  test('AccountSettingsViewModel atualiza nome', () async {
    final repository = _SimuladoConfiguracoesContaRepository();
    final viewModel = ConfiguracoesContaViewModel(repository: repository);

    final message = await viewModel.salvarNome('Maria');

    expect(viewModel.displayName, 'Maria');
    expect(repository.name, 'Maria');
    expect(message, 'Nome atualizado.');
  });

  test('AccountSettingsViewModel valida nome vazio', () async {
    final viewModel = ConfiguracoesContaViewModel(
      repository: _SimuladoConfiguracoesContaRepository(),
    );

    expect(
      () => viewModel.salvarNome('   '),
      throwsA(isA<FolhioAutenticacaoException>()),
    );
  });

  test('AccountSettingsViewModel resolve 2FA ao trocar email', () async {
    final repository = _SimuladoConfiguracoesContaRepository(requireTwoFactor: true);
    final viewModel = ConfiguracoesContaViewModel(repository: repository);

    final message = await viewModel.salvarEmail(
      email: 'novo@folhio.app',
      currentPassword: 'senha-atual',
      confirmTwoFactor: (result, onCode) => onCode('123456'),
    );

    expect(repository.twoFactorCodeUsed, '123456');
    expect(viewModel.displayEmail, 'novo@folhio.app');
    expect(message, 'Email atualizado.');
  });

  test('AccountSettingsViewModel apaga conta e encerra sessao local', () async {
    final repository = _SimuladoConfiguracoesContaRepository();
    final viewModel = ConfiguracoesContaViewModel(repository: repository);

    final message = await viewModel.excluirConta(
      currentPassword: 'senha-atual',
      confirmTwoFactor: (result, onCode) => onCode('123456'),
    );

    expect(repository.signOutLocalCalled, isTrue);
    expect(message, 'Conta apagada.');
  });

  test(
    'AccountSettingsViewModel envia recuperacao para email da conta',
    () async {
      final repository = _SimuladoConfiguracoesContaRepository();
      final viewModel = ConfiguracoesContaViewModel(repository: repository);

      final message = await viewModel.solicitarRedefinicaoSenha();

      expect(repository.passwordResetEmail, 'professor@folhio.app');
      expect(message, 'Enviamos um email com o código para renovar sua senha.');
    },
  );
}

class _SimuladoConfiguracoesContaRepository implements ConfiguracoesContaRepository {
  String name = 'Professor';
  String email = 'professor@folhio.app';
  final bool requireTwoFactor;
  String? twoFactorCodeUsed;
  String? passwordResetEmail;
  bool signOutLocalCalled = false;

  _SimuladoConfiguracoesContaRepository({this.requireTwoFactor = false});

  @override
  PerfilContaState perfilAtual() {
    return PerfilContaState(name: name, email: email);
  }

  @override
  Future<FolhioResultadoAtualizacaoConta> atualizarConta({
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  }) async {
    if (requireTwoFactor && twoFactorCode == null) {
      return _resultado(twoFactorRequired: true, twoFactorToken: 'token-2fa');
    }
    twoFactorCodeUsed = twoFactorCode;
    if (name != null) this.name = name;
    if (email != null) this.email = email;
    return _resultado();
  }

  @override
  Future<FolhioResultadoAtualizacaoConta> excluirConta({
    String? currentPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  }) async {
    twoFactorCodeUsed = twoFactorCode;
    return _resultado(user: null);
  }

  @override
  Future<void> encerrarSessaoLocal() async {
    signOutLocalCalled = true;
  }

  @override
  Future<void> solicitarRedefinicaoSenha(String email) async {
    passwordResetEmail = email;
  }

  FolhioResultadoAtualizacaoConta _resultado({
    bool twoFactorRequired = false,
    String? twoFactorToken,
    FolhioUsuario? user,
  }) {
    return FolhioResultadoAtualizacaoConta(
      success: true,
      user:
          user ??
          FolhioUsuario(
            id: 'user-1',
            name: name,
            email: email,
            emailVerified: true,
          ),
      twoFactorRequired: twoFactorRequired,
      twoFactorToken: twoFactorToken,
      twoFactorDestination: email,
      message: 'ok',
    );
  }
}
