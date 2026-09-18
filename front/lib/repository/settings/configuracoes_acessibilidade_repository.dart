import '../../controller/settings/aparencia_controller.dart';
import '../local/persistencia_local_repository.dart';
import '../../model/settings/settings_models.dart';

abstract class ConfiguracoesAcessibilidadeRepository {
  Future<ConfiguracoesAcessibilidadeState> carregar();

  Future<void> definirAltoContraste(bool value);

  Future<void> definirDescricoesExtras(bool value);

  Future<void> definirTamanhoFonte(String value);
}

class ConfiguracoesAcessibilidadeLocalRepository
    implements ConfiguracoesAcessibilidadeRepository {
  final PersistenciaLocalRepository local;
  final AparenciaController appearance;

  const ConfiguracoesAcessibilidadeLocalRepository({
    required this.local,
    required this.appearance,
  });

  @override
  Future<ConfiguracoesAcessibilidadeState> carregar() async {
    return ConfiguracoesAcessibilidadeState(
      highContrast: appearance.highContrast,
      extraDescriptions: appearance.extraDescriptions,
      fontSize: appearance.fontSizeLabel,
    );
  }

  @override
  Future<void> definirAltoContraste(bool value) {
    return appearance.definirAltoContraste(value);
  }

  @override
  Future<void> definirDescricoesExtras(bool value) {
    return appearance.definirDescricoesExtras(value);
  }

  @override
  Future<void> definirTamanhoFonte(String value) {
    return appearance.definirRotuloTamanhoFonte(value);
  }
}
