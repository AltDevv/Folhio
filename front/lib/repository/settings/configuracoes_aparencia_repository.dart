import '../../controller/settings/aparencia_controller.dart';
import '../../model/settings/settings_models.dart';

abstract class ConfiguracoesAparenciaRepository {
  ConfiguracoesAparenciaState atual();

  Future<void> definirModoTema(String value);

  Future<void> definirCorDestaque(String value);
}

class FolhioConfiguracoesAparenciaRepository
    implements ConfiguracoesAparenciaRepository {
  final AparenciaController appearance;

  const FolhioConfiguracoesAparenciaRepository({required this.appearance});

  @override
  ConfiguracoesAparenciaState atual() {
    return ConfiguracoesAparenciaState(
      themeMode: appearance.themeModeLabel,
      accentColor: appearance.accentLabel,
    );
  }

  @override
  Future<void> definirModoTema(String value) {
    return appearance.definirRotuloModoTema(value);
  }

  @override
  Future<void> definirCorDestaque(String value) {
    return appearance.definirRotuloDestaque(value);
  }
}
