import 'package:flutter_test/flutter_test.dart';
import 'package:folhio/repository/settings/configuracoes_repository.dart';
import 'package:folhio/controller/settings/configuracoes_view_model.dart';

void main() {
  test(
    'SettingsViewModel prioriza nome autenticado sobre nome local',
    () async {
      final repository = _SimuladoConfiguracoesRepository(
        storedName: 'Nome local',
        authenticatedName: 'Nome da conta',
      );
      final viewModel = ConfiguracoesViewModel(repository: repository);

      await viewModel.carregarResumo();

      expect(viewModel.profileName, 'Nome da conta');
    },
  );

  test('SettingsViewModel usa Professor quando nao ha nome salvo', () async {
    final viewModel = ConfiguracoesViewModel(repository: _SimuladoConfiguracoesRepository());

    await viewModel.carregarResumo();

    expect(viewModel.profileName, 'Professor');
  });

  test('SettingsViewModel delega logout para o repositorio', () async {
    final repository = _SimuladoConfiguracoesRepository();
    final viewModel = ConfiguracoesViewModel(repository: repository);

    await viewModel.encerrarSessao();

    expect(repository.signOutCalled, isTrue);
  });
}

class _SimuladoConfiguracoesRepository implements ConfiguracoesRepository {
  final String? storedName;
  final String? authenticatedName;
  bool signOutCalled = false;

  _SimuladoConfiguracoesRepository({this.storedName, this.authenticatedName});

  @override
  Future<String?> nomePerfilArmazenado() async => storedName;

  @override
  String? nomePerfilAutenticado() => authenticatedName;

  @override
  Future<void> encerrarSessao() async {
    signOutCalled = true;
  }
}
