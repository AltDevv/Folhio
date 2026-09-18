import 'package:flutter_test/flutter_test.dart';
import 'package:folhio/model/settings/settings_models.dart';
import 'package:folhio/repository/settings/configuracoes_aparencia_repository.dart';
import 'package:folhio/controller/settings/configuracoes_aparencia_view_model.dart';

void main() {
  test('AppearanceSettingsViewModel atualiza tema', () async {
    final repository = _SimuladoConfiguracoesAparenciaRepository();
    final viewModel = ConfiguracoesAparenciaViewModel(repository: repository);

    final message = await viewModel.definirModoTema('Escuro');

    expect(viewModel.themeMode, 'Escuro');
    expect(repository.themeMode, 'Escuro');
    expect(message, 'Tema atualizado.');
  });

  test('AppearanceSettingsViewModel atualiza cor principal', () async {
    final repository = _SimuladoConfiguracoesAparenciaRepository();
    final viewModel = ConfiguracoesAparenciaViewModel(repository: repository);

    final message = await viewModel.definirCorDestaque('Azul');

    expect(viewModel.accentColor, 'Azul');
    expect(repository.accentColor, 'Azul');
    expect(message, 'Cor principal atualizada.');
  });
}

class _SimuladoConfiguracoesAparenciaRepository
    implements ConfiguracoesAparenciaRepository {
  String themeMode = 'Claro';
  String accentColor = 'Verde padrão';

  @override
  ConfiguracoesAparenciaState atual() {
    return ConfiguracoesAparenciaState(
      themeMode: themeMode,
      accentColor: accentColor,
    );
  }

  @override
  Future<void> definirCorDestaque(String value) async {
    accentColor = value;
  }

  @override
  Future<void> definirModoTema(String value) async {
    themeMode = value;
  }
}
