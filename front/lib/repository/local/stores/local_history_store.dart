part of '../persistencia_local_repository.dart';

class _HistoricoLocalStore {
  _HistoricoLocalStore(this._owner);

  final PersistenciaLocalRepository _owner;

  Future<void> registrarHistorico({
    required String eventType,
    required String title,
    Map<String, Object?> details = const {},
  }) async {
    await _owner.db
        .into(_owner.db.appHistory)
        .insert(
          AppHistoryCompanion.insert(
            id: _owner._id('history'),
            eventType: eventType,
            title: await _owner._encryption.criptografarTexto(title),
            detailsJson: Value(
              await _owner._encryption.criptografarTexto(jsonEncode(details)),
            ),
          ),
        );
  }
}
