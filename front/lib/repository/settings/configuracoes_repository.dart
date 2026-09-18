import '../../security/authentication/autenticacao_controller.dart';
import '../local/persistencia_local_repository.dart';

abstract class ConfiguracoesRepository {
  Future<String?> nomePerfilArmazenado();

  String? nomePerfilAutenticado();

  Future<void> encerrarSessao();
}

class ConfiguracoesLocaisRepository implements ConfiguracoesRepository {
  final PersistenciaLocalRepository local;
  final AutenticacaoController auth;

  const ConfiguracoesLocaisRepository({required this.local, required this.auth});

  @override
  Future<String?> nomePerfilArmazenado() {
    return local.configuracao('profile.name');
  }

  @override
  String? nomePerfilAutenticado() {
    final name = auth.user?.name.trim();
    return name?.isNotEmpty == true ? name : null;
  }

  @override
  Future<void> encerrarSessao() {
    return auth.encerrarSessao();
  }
}
