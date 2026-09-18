part of '../persistencia_local_repository.dart';

class _ConfiguracoesLocaisStore {
  _ConfiguracoesLocaisStore(this._owner);

  final PersistenciaLocalRepository _owner;

  Future<String?> configuracao(String key) async {
    return _owner._encryption.descriptografarTextoOpcional(await _owner.db.configuracao(key));
  }

  Future<void> definirConfiguracao(String key, String value) async {
    return _owner.db.salvarOuAtualizarConfiguracao(
      key,
      await _owner._encryption.criptografarTexto(value),
    );
  }

  Future<bool> get automaticBackupEnabled async {
    return (await configuracao('backup.automatic')) == 'true';
  }

  Future<void> definirBackupAutomaticoHabilitado(bool value) {
    return definirConfiguracao('backup.automatic', value ? 'true' : 'false');
  }
}
