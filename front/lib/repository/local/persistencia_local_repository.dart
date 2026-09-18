import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../security/encryption/criptografia_backup_service.dart';
import '../../database/folhio_database.dart';
import '../../security/encryption/criptografia_local_service.dart';

part 'stores/local_backup_operations.dart';
part 'stores/local_classes_store.dart';
part 'stores/local_history_store.dart';
part 'stores/local_library_store.dart';
part 'stores/local_settings_store.dart';

class PersistenciaLocalRepository {
  PersistenciaLocalRepository._();

  static final PersistenciaLocalRepository instance = PersistenciaLocalRepository._();

  final FolhioDatabase db = FolhioDatabase();
  final CriptografiaLocalService _encryption = CriptografiaLocalService.instance;
  late final _ConfiguracoesLocaisStore _settings = _ConfiguracoesLocaisStore(this);
  late final _HistoricoLocalStore _history = _HistoricoLocalStore(this);
  late final _BibliotecaLocalStore _library = _BibliotecaLocalStore(this);
  late final _TurmasLocaisStore _classes = _TurmasLocaisStore(this);

  Future<String?> configuracao(String key) {
    return _settings.configuracao(key);
  }

  Future<void> definirConfiguracao(String key, String value) {
    return _settings.definirConfiguracao(key, value);
  }

  Future<bool> get automaticBackupEnabled {
    return _settings.automaticBackupEnabled;
  }

  Future<void> definirBackupAutomaticoHabilitado(bool value) {
    return _settings.definirBackupAutomaticoHabilitado(value);
  }

  Future<void> migrarCriptografiaLocalSeNecessario() async {
    if (await configuracao('security.localEncryptionMigrated.v1') == 'true') return;

    await db.transaction(() async {
      final settings = await db.select(db.localSettings).get();
      for (final row in settings) {
        await db
            .into(db.localSettings)
            .insertOnConflictUpdate(
              (await _criptografarConfiguracao(row)).toCompanion(true),
            );
      }

      final files = await db.select(db.localFiles).get();
      for (final row in files) {
        await _criptografarConteudoArquivoLocalExistente(row);
        await db
            .into(db.localFiles)
            .insertOnConflictUpdate(
              (await _criptografarArquivo(row)).toCompanion(true),
            );
      }

      final folders = await db.select(db.localFolders).get();
      for (final row in folders) {
        await db
            .into(db.localFolders)
            .insertOnConflictUpdate(
              (await _criptografarPasta(row)).toCompanion(true),
            );
      }

      final classes = await db.select(db.classes).get();
      for (final row in classes) {
        await db
            .into(db.classes)
            .insertOnConflictUpdate(
              (await _criptografarTurma(row)).toCompanion(true),
            );
      }

      final students = await db.select(db.students).get();
      for (final row in students) {
        await db
            .into(db.students)
            .insertOnConflictUpdate(
              (await _criptografarAluno(row)).toCompanion(true),
            );
      }

      final attendanceRecords = await db.select(db.attendanceRecords).get();
      for (final row in attendanceRecords) {
        await db
            .into(db.attendanceRecords)
            .insertOnConflictUpdate(
              (await _criptografarRegistroPresenca(row)).toCompanion(true),
            );
      }

      final attendanceEntries = await db.select(db.attendanceEntries).get();
      for (final row in attendanceEntries) {
        await db
            .into(db.attendanceEntries)
            .insertOnConflictUpdate(
              (await _criptografarEntradaPresenca(row)).toCompanion(true),
            );
      }

      final gradeRecords = await db.select(db.gradeRecords).get();
      for (final row in gradeRecords) {
        await db
            .into(db.gradeRecords)
            .insertOnConflictUpdate(
              (await _criptografarRegistroNota(row)).toCompanion(true),
            );
      }

      final generatedMaterials = await db.select(db.generatedMaterials).get();
      for (final row in generatedMaterials) {
        await db
            .into(db.generatedMaterials)
            .insertOnConflictUpdate(
              (await _criptografarMaterialGerado(row)).toCompanion(true),
            );
      }

      final history = await db.select(db.appHistory).get();
      for (final row in history) {
        await db
            .into(db.appHistory)
            .insertOnConflictUpdate(
              (await _criptografarHistorico(row)).toCompanion(true),
            );
      }

      final backups = await db.select(db.backupSnapshots).get();
      for (final row in backups) {
        await db
            .into(db.backupSnapshots)
            .insertOnConflictUpdate(
              (await _criptografarRetratoBackup(row)).toCompanion(true),
            );
      }
    });

    await definirConfiguracao('security.localEncryptionMigrated.v1', 'true');
  }

  Future<void> registrarHistorico({
    required String eventType,
    required String title,
    Map<String, Object?> details = const {},
  }) {
    return _history.registrarHistorico(
      eventType: eventType,
      title: title,
      details: details,
    );
  }

  Future<void> escreverArquivoLocalCriptografado(File file, List<int> bytes) {
    return _library.escreverArquivoLocalCriptografado(file, bytes);
  }

  Future<Uint8List> lerArquivoLocalCriptografado(File file) {
    return _library.lerArquivoLocalCriptografado(file);
  }

  Future<void> salvarOuAtualizarMetadadosArquivo({
    required String id,
    required String fileName,
    required String mimeType,
    int? sizeBytes,
    String? localPath,
    String? remoteStorageKey,
    String? folderId,
    required String folderName,
    required String origin,
    DateTime? updatedAt,
  }) {
    return _library.salvarOuAtualizarMetadadosArquivo(
      id: id,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      localPath: localPath,
      remoteStorageKey: remoteStorageKey,
      folderId: folderId,
      folderName: folderName,
      origin: origin,
      updatedAt: updatedAt,
    );
  }

  Future<LocalFile?> arquivoPorId(String id) {
    return _library.arquivoPorId(id);
  }

  Future<List<LocalFile>> arquivosRecentes({int limit = 20}) {
    return _library.arquivosRecentes(limit: limit);
  }

  Future<void> excluirArquivoLocal(String id) {
    return _library.excluirArquivoLocal(id);
  }

  Future<void> moverArquivoLocal({
    required String id,
    String? folderId,
    required String folderName,
  }) {
    return _library.moverArquivoLocal(
      id: id,
      folderId: folderId,
      folderName: folderName,
    );
  }

  Future<void> renomearArquivoLocal({required String id, required String fileName}) {
    return _library.renomearArquivoLocal(id: id, fileName: fileName);
  }

  Future<List<LocalFolder>> listarPastas({String? parentId, int limit = 80}) {
    return _library.listarPastas(parentId: parentId, limit: limit);
  }

  Future<LocalFolder?> pastaPorId(String id) {
    return _library.pastaPorId(id);
  }

  Future<LocalFolder> salvarPasta({
    String? id,
    String? parentId,
    required String name,
    String tags = '',
    String notes = '',
    String links = '',
  }) {
    return _library.salvarPasta(
      id: id,
      parentId: parentId,
      name: name,
      tags: tags,
      notes: notes,
      links: links,
    );
  }

  Future<void> excluirPasta(String id) {
    return _library.excluirPasta(id);
  }

  Future<List<SchoolClass>> listarTurmas({int limit = 80}) {
    return _classes.listarTurmas(limit: limit);
  }

  Future<SchoolClass> salvarTurma({
    String? id,
    required String name,
    String schoolYear = '',
    String subject = '',
    String shift = '',
  }) {
    return _classes.salvarTurma(
      id: id,
      name: name,
      schoolYear: schoolYear,
      subject: subject,
      shift: shift,
    );
  }

  Future<void> excluirTurma(String id) {
    return _classes.excluirTurma(id);
  }

  Future<List<Student>> listarAlunos(String classId) {
    return _classes.listarAlunos(classId);
  }

  Future<Student> salvarAluno({
    String? id,
    required String classId,
    required String name,
    String registration = '',
    bool active = true,
  }) {
    return _classes.salvarAluno(
      id: id,
      classId: classId,
      name: name,
      registration: registration,
      active: active,
    );
  }

  Future<void> excluirAluno(String id) {
    return _classes.excluirAluno(id);
  }

  Future<List<Map<String, dynamic>>> _exportarLinhas<T>(
    List<T> rows,
    Future<T> Function(T row) decrypt,
    Map<String, dynamic> Function(T row) toJson,
  ) async {
    final exported = <Map<String, dynamic>>[];
    for (final row in rows) {
      exported.add(toJson(await decrypt(row)));
    }
    return exported;
  }

  Future<void> _restaurarLista(
    dynamic rows,
    Future<Object?> Function(Map<String, dynamic> row) insert,
  ) async {
    if (rows is! List) return;
    for (final row in rows) {
      if (row is Map<String, dynamic>) {
        await insert(row);
      }
    }
  }

  Future<void> _criptografarConteudoArquivoLocalExistente(LocalFile row) async {
    try {
      final localPath = await _encryption.descriptografarTextoOpcional(row.localPath);
      if (localPath == null || localPath.isEmpty) return;
      final file = File(localPath);
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      if (_encryption.ehBytesCriptografados(bytes)) return;
      await escreverArquivoLocalCriptografado(file, bytes);
    } catch (_) {
      // A locked or missing file should not block the database migration.
    }
  }

  Future<LocalSetting> _criptografarConfiguracao(LocalSetting row) async {
    return row.copyWith(value: await _encryption.criptografarTexto(row.value));
  }

  Future<LocalSetting> _descriptografarConfiguracao(LocalSetting row) async {
    return row.copyWith(value: await _encryption.descriptografarTexto(row.value));
  }

  Future<LocalFile> _criptografarArquivo(LocalFile row) async {
    return row.copyWith(
      fileName: await _encryption.criptografarTexto(row.fileName),
      localPath: Value(await _encryption.criptografarTextoOpcional(row.localPath)),
      remoteStorageKey: Value(
        await _encryption.criptografarTextoOpcional(row.remoteStorageKey),
      ),
      folderName: await _encryption.criptografarTexto(row.folderName),
    );
  }

  Future<LocalFile> _descriptografarArquivo(LocalFile row) async {
    return row.copyWith(
      fileName: await _encryption.descriptografarTexto(row.fileName),
      localPath: Value(await _encryption.descriptografarTextoOpcional(row.localPath)),
      remoteStorageKey: Value(
        await _encryption.descriptografarTextoOpcional(row.remoteStorageKey),
      ),
      folderName: await _encryption.descriptografarTexto(row.folderName),
    );
  }

  Future<LocalFolder> _criptografarPasta(LocalFolder row) async {
    return row.copyWith(
      name: await _encryption.criptografarTexto(row.name),
      tags: await _encryption.criptografarTexto(row.tags),
      notes: await _encryption.criptografarTexto(row.notes),
      links: await _encryption.criptografarTexto(row.links),
    );
  }

  Future<LocalFolder> _descriptografarPasta(LocalFolder row) async {
    return row.copyWith(
      name: await _encryption.descriptografarTexto(row.name),
      tags: await _encryption.descriptografarTexto(row.tags),
      notes: await _encryption.descriptografarTexto(row.notes),
      links: await _encryption.descriptografarTexto(row.links),
    );
  }

  Future<SchoolClass> _criptografarTurma(SchoolClass row) async {
    return row.copyWith(
      name: await _encryption.criptografarTexto(row.name),
      schoolYear: await _encryption.criptografarTexto(row.schoolYear),
      subject: await _encryption.criptografarTexto(row.subject),
      shift: await _encryption.criptografarTexto(row.shift),
    );
  }

  Future<SchoolClass> _descriptografarTurma(SchoolClass row) async {
    return row.copyWith(
      name: await _encryption.descriptografarTexto(row.name),
      schoolYear: await _encryption.descriptografarTexto(row.schoolYear),
      subject: await _encryption.descriptografarTexto(row.subject),
      shift: await _encryption.descriptografarTexto(row.shift),
    );
  }

  Future<Student> _criptografarAluno(Student row) async {
    return row.copyWith(
      name: await _encryption.criptografarTexto(row.name),
      registration: await _encryption.criptografarTexto(row.registration),
    );
  }

  Future<Student> _descriptografarAluno(Student row) async {
    return row.copyWith(
      name: await _encryption.descriptografarTexto(row.name),
      registration: await _encryption.descriptografarTexto(row.registration),
    );
  }

  Future<AttendanceRecord> _criptografarRegistroPresenca(
    AttendanceRecord row,
  ) async {
    return row.copyWith(notes: await _encryption.criptografarTexto(row.notes));
  }

  Future<AttendanceRecord> _descriptografarRegistroPresenca(
    AttendanceRecord row,
  ) async {
    return row.copyWith(notes: await _encryption.descriptografarTexto(row.notes));
  }

  Future<AttendanceEntry> _criptografarEntradaPresenca(AttendanceEntry row) async {
    return row.copyWith(note: await _encryption.criptografarTexto(row.note));
  }

  Future<AttendanceEntry> _descriptografarEntradaPresenca(AttendanceEntry row) async {
    return row.copyWith(note: await _encryption.descriptografarTexto(row.note));
  }

  Future<GradeRecord> _criptografarRegistroNota(GradeRecord row) async {
    return row.copyWith(label: await _encryption.criptografarTexto(row.label));
  }

  Future<GradeRecord> _descriptografarRegistroNota(GradeRecord row) async {
    return row.copyWith(label: await _encryption.descriptografarTexto(row.label));
  }

  Future<GeneratedMaterial> _criptografarMaterialGerado(
    GeneratedMaterial row,
  ) async {
    return row.copyWith(
      subject: await _encryption.criptografarTexto(row.subject),
      theme: await _encryption.criptografarTexto(row.theme),
      contentJson: await _encryption.criptografarTexto(row.contentJson),
    );
  }

  Future<GeneratedMaterial> _descriptografarMaterialGerado(
    GeneratedMaterial row,
  ) async {
    return row.copyWith(
      subject: await _encryption.descriptografarTexto(row.subject),
      theme: await _encryption.descriptografarTexto(row.theme),
      contentJson: await _encryption.descriptografarTexto(row.contentJson),
    );
  }

  Future<AppHistoryEntry> _criptografarHistorico(AppHistoryEntry row) async {
    return row.copyWith(
      title: await _encryption.criptografarTexto(row.title),
      detailsJson: await _encryption.criptografarTexto(row.detailsJson),
    );
  }

  Future<AppHistoryEntry> _descriptografarHistorico(AppHistoryEntry row) async {
    return row.copyWith(
      title: await _encryption.descriptografarTexto(row.title),
      detailsJson: await _encryption.descriptografarTexto(row.detailsJson),
    );
  }

  Future<BackupSnapshot> _criptografarRetratoBackup(BackupSnapshot row) async {
    return row.copyWith(
      filePath: Value(await _encryption.criptografarTextoOpcional(row.filePath)),
      errorMessage: await _encryption.criptografarTexto(row.errorMessage),
    );
  }

  Future<BackupSnapshot> _descriptografarRetratoBackup(BackupSnapshot row) async {
    return row.copyWith(
      filePath: Value(await _encryption.descriptografarTextoOpcional(row.filePath)),
      errorMessage: await _encryption.descriptografarTexto(row.errorMessage),
    );
  }

  bool _temTextoCriptografadoIlegivel(String? value) {
    return value != null && _encryption.ehTextoCriptografado(value);
  }

  bool _temTextoTurmaIlegivel(SchoolClass row) {
    return _temTextoCriptografadoIlegivel(row.name) ||
        _temTextoCriptografadoIlegivel(row.schoolYear) ||
        _temTextoCriptografadoIlegivel(row.subject) ||
        _temTextoCriptografadoIlegivel(row.shift);
  }

  bool _temTextoArquivoIlegivel(LocalFile row) {
    return _temTextoCriptografadoIlegivel(row.fileName) ||
        _temTextoCriptografadoIlegivel(row.localPath) ||
        _temTextoCriptografadoIlegivel(row.remoteStorageKey) ||
        _temTextoCriptografadoIlegivel(row.folderName);
  }

  bool _temTextoPastaIlegivel(LocalFolder row) {
    return _temTextoCriptografadoIlegivel(row.name) ||
        _temTextoCriptografadoIlegivel(row.tags) ||
        _temTextoCriptografadoIlegivel(row.notes) ||
        _temTextoCriptografadoIlegivel(row.links);
  }

  String _id(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}
