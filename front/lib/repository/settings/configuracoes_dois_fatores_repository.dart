import '../../security/authentication/autenticacao_controller.dart';

abstract class ConfiguracoesDoisFatoresRepository {
  bool get isSignedIn;

  String? get email;

  Future<FolhioConfiguracoesDoisFatores> carregar();

  Future<FolhioConfiguracoesDoisFatores> atualizar({
    required bool enabled,
    String? currentPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  });
}

class FolhioConfiguracoesDoisFatoresRepository implements ConfiguracoesDoisFatoresRepository {
  final AutenticacaoController auth;

  const FolhioConfiguracoesDoisFatoresRepository({required this.auth});

  @override
  bool get isSignedIn => auth.isSignedIn;

  @override
  String? get email => auth.user?.email;

  @override
  Future<FolhioConfiguracoesDoisFatores> carregar() {
    return auth.configuracoesDoisFatores();
  }

  @override
  Future<FolhioConfiguracoesDoisFatores> atualizar({
    required bool enabled,
    String? currentPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  }) {
    return auth.atualizarConfiguracoesDoisFatores(
      enabled: enabled,
      currentPassword: currentPassword,
      twoFactorToken: twoFactorToken,
      twoFactorCode: twoFactorCode,
    );
  }
}
