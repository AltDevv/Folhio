import 'package:flutter_test/flutter_test.dart';
import 'package:folhio/model/settings/settings_models.dart';
import 'package:folhio/repository/settings/configuracoes_acessibilidade_repository.dart';
import 'package:folhio/controller/settings/configuracoes_acessibilidade_view_model.dart';

void main() {
  test('carrega preferencias de acessibilidade', () async {
    final viewModel = ConfiguracoesAcessibilidadeViewModel(
      repository: _SimuladoConfiguracoesAcessibilidadeRepository(
        initialState: const ConfiguracoesAcessibilidadeState(
          highContrast: true,
          extraDescriptions: false,
          fontSize: 'Grande',
        ),
      ),
    );

    await viewModel.carregar();

    expect(viewModel.highContrast, isTrue);
    expect(viewModel.extraDescriptions, isFalse);
    expect(viewModel.fontSize, 'Grande');
  });

  test('atualiza tamanho da fonte via repositorio', () async {
    final repository = _SimuladoConfiguracoesAcessibilidadeRepository();
    final viewModel = ConfiguracoesAcessibilidadeViewModel(repository: repository);

    final message = await viewModel.definirTamanhoFonte('Pequeno');

    expect(viewModel.fontSize, 'Pequeno');
    expect(repository.fontSize, 'Pequeno');
    expect(message, 'Tamanho da fonte atualizado.');
  });
}

class _SimuladoConfiguracoesAcessibilidadeRepository
    implements ConfiguracoesAcessibilidadeRepository {
  ConfiguracoesAcessibilidadeState initialState;
  bool highContrast = false;
  bool extraDescriptions = true;
  String fontSize = 'Padrao';

  _SimuladoConfiguracoesAcessibilidadeRepository({
    this.initialState = const ConfiguracoesAcessibilidadeState(),
  });

  @override
  Future<ConfiguracoesAcessibilidadeState> carregar() async => initialState;

  @override
  Future<void> definirDescricoesExtras(bool value) async {
    extraDescriptions = value;
  }

  @override
  Future<void> definirTamanhoFonte(String value) async {
    fontSize = value;
  }

  @override
  Future<void> definirAltoContraste(bool value) async {
    highContrast = value;
  }
}
