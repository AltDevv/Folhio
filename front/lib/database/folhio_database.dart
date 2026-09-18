import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/academic_tables.dart';
import 'tables/attendance_tables.dart';
import 'tables/library_tables.dart';
import 'tables/school_tables.dart';
import 'tables/settings_tables.dart';
import 'tables/system_tables.dart';

part 'folhio_database.g.dart';

LazyDatabase _abrirConexao() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'folhio.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(
  tables: [
    LocalSettings,
    LocalFiles,
    LocalFolders,
    Classes,
    Students,
    AttendanceRecords,
    AttendanceEntries,
    GradeRecords,
    GeneratedMaterials,
    AppHistory,
    BackupSnapshots,
  ],
)
class FolhioDatabase extends _$FolhioDatabase {
  FolhioDatabase() : super(_abrirConexao());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await customStatement('DROP TABLE IF EXISTS local_collections');
        await customStatement('DROP TABLE IF EXISTS local_files_legacy');

        await customStatement(
          'ALTER TABLE local_files RENAME TO local_files_legacy',
        );

        await migrator.createTable(localFiles);

        await customStatement('''
          INSERT INTO local_files (
            id,
            file_name,
            mime_type,
            size_bytes,
            local_path,
            remote_storage_key,
            folder_id,
            folder_name,
            origin,
            pending_backup,
            created_at,
            updated_at
          )
          SELECT
            id,
            file_name,
            mime_type,
            size_bytes,
            local_path,
            remote_storage_key,
            folder_id,
            folder_name,
            origin,
            pending_backup,
            created_at,
            updated_at
          FROM local_files_legacy
        ''');

        await customStatement(
          'DROP TABLE IF EXISTS local_files_legacy',
        );
      }
    },
  );

  Future<void> salvarOuAtualizarConfiguracao(
      String key,
      String value,
      ) {
    return into(localSettings).insertOnConflictUpdate(
      LocalSettingsCompanion.insert(
        key: key,
        value: value,
      ),
    );
  }

  Future<String?> configuracao(String key) async {
    final row = await (select(localSettings)
      ..where((table) => table.key.equals(key)))
        .getSingleOrNull();

    return row?.value;
  }

  Future<BackupSnapshot?> ultimoBackup() {
    return (select(backupSnapshots)
      ..orderBy([
            (table) => OrderingTerm.desc(table.createdAt),
      ])
      ..limit(1))
        .getSingleOrNull();
  }

  Future<List<LocalFile>> arquivosRecentes({
    int limit = 20,
  }) {
    return (select(localFiles)
      ..orderBy([
            (table) => OrderingTerm.desc(table.updatedAt),
      ])
      ..limit(limit))
        .get();
  }
}