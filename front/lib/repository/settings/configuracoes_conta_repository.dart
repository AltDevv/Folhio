import '../../security/authentication/autenticacao_controller.dart';
import '../../model/settings/settings_models.dart';

abstract class ConfiguracoesContaRepository {
  PerfilContaState perfilAtual();

  Future<FolhioResultadoAtualizacaoConta> atualizarConta({
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  });

  Future<FolhioResultadoAtualizacaoConta> excluirConta({
    String? currentPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  });

  Future<void> solicitarRedefinicaoSenha(String email);

  Future<void> encerrarSessaoLocal();
}

class FolhioConfiguracoesContaRepository implements ConfiguracoesContaRepository {
  final AutenticacaoController auth;

  const FolhioConfiguracoesContaRepository({required this.auth});

  @override
  PerfilContaState perfilAtual() {
    final user = auth.user;
    return PerfilContaState(
      name: user?.name ?? '',
      email: user?.email ?? '',
    );
  }

  @override
  Future<FolhioResultadoAtualizacaoConta> atualizarConta({
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  }) {
    return auth.atualizarConta(
      name: name,
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
      twoFactorToken: twoFactorToken,
      twoFactorCode: twoFactorCode,
    );
  }

  @override
  Future<FolhioResultadoAtualizacaoConta> excluirConta({
    String? currentPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  }) {
    return auth.excluirConta(
      currentPassword: currentPassword,
      twoFactorToken: twoFactorToken,
      twoFactorCode: twoFactorCode,
    );
  }

  @override
  Future<void> solicitarRedefinicaoSenha(String email) {
    return auth.esqueciSenha(email);
  }

  @override
  Future<void> encerrarSessaoLocal() {
    return auth.encerrarSessao(localOnly: true);
  }
}
