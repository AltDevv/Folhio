part of '../persistencia_local_repository.dart';

extension OperacoesBackupLocal on PersistenciaLocalRepository {
  Future<void> limparArquivosTemporarios() async {
    final tempDir = await getTemporaryDirectory();
    if (!await tempDir.exists()) return;
    await for (final entity in tempDir.list()) {
      try {
        if (entity is File) {
          await entity.delete();
        } else if (entity is Directory) {
          await entity.delete(recursive: true);
        }
      } catch (_) {
        // Ignore files currently being used by the platform.
      }
    }
  }

  Future<BackupSnapshot?> ultimoBackup() async {
    final row = await db.ultimoBackup();
    if (row == null) return null;
    return _descriptografarRetratoBackup(row);
  }

  Future<File> criarBackupManual() async {
    final now = DateTime.now();
    final backupId = _id('backup');
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    await backupDir.create(recursive: true);
    final file = File(
      p.join(
        backupDir.path,
        'folhio-backup-${now.millisecondsSinceEpoch}.folhio-backup',
      ),
    );

    await db
        .into(db.backupSnapshots)
        .insert(
          BackupSnapshotsCompanion.insert(
            id: backupId,
            destination: const Value('local'),
            status: const Value('running'),
            createdAt: Value(now),
          ),
        );

    try {
      final payload = await exportarJson();
      final encryptedPayload = await CriptografiaBackupService.instance.criptografarBackup(
        payload,
      );
      await file.writeAsString(jsonEncode(encryptedPayload), flush: true);
      await (db.update(
        db.backupSnapshots,
      )..where((table) => table.id.equals(backupId))).write(
        BackupSnapshotsCompanion(
          status: const Value('completed'),
          filePath: Value(await _encryption.criptografarTexto(file.path)),
          completedAt: Value(DateTime.now()),
        ),
      );
      await definirConfiguracao('backup.enabled', 'true');
      await registrarHistorico(
        eventType: 'backup',
        title: 'Backup concluido',
        details: {'path': file.path},
      );
      return file;
    } catch (error) {
      await (db.update(
        db.backupSnapshots,
      )..where((table) => table.id.equals(backupId))).write(
        BackupSnapshotsCompanion(
          status: const Value('failed'),
          errorMessage: Value(await _encryption.criptografarTexto(error.toString())),
          completedAt: Value(DateTime.now()),
        ),
      );
      rethrow;
    }
  }

  Future<Map<String, Object?>> exportarJson() async {
    return {
      'format': 'folhio-local-first-backup',
      'schemaVersion': db.schemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'settings': await _exportarLinhas(
        await db.select(db.localSettings).get(),
        _descriptografarConfiguracao,
        (row) => row.toJson(),
      ),
      'folders': await _exportarLinhas(
        await db.select(db.localFolders).get(),
        _descriptografarPasta,
        (row) => row.toJson(),
      ),
      'files': await _exportarLinhas(
        await db.select(db.localFiles).get(),
        _descriptografarArquivo,
        (row) => row.toJson(),
      ),
      'classes': await _exportarLinhas(
        await db.select(db.classes).get(),
        _descriptografarTurma,
        (row) => row.toJson(),
      ),
      'students': await _exportarLinhas(
        await db.select(db.students).get(),
        _descriptografarAluno,
        (row) => row.toJson(),
      ),
      'attendanceRecords': await _exportarLinhas(
        await db.select(db.attendanceRecords).get(),
        _descriptografarRegistroPresenca,
        (row) => row.toJson(),
      ),
      'attendanceEntries': await _exportarLinhas(
        await db.select(db.attendanceEntries).get(),
        _descriptografarEntradaPresenca,
        (row) => row.toJson(),
      ),
      'gradeRecords': await _exportarLinhas(
        await db.select(db.gradeRecords).get(),
        _descriptografarRegistroNota,
        (row) => row.toJson(),
      ),
      'generatedMaterials': await _exportarLinhas(
        await db.select(db.generatedMaterials).get(),
        _descriptografarMaterialGerado,
        (row) => row.toJson(),
      ),
      'history': await _exportarLinhas(
        await db.select(db.appHistory).get(),
        _descriptografarHistorico,
        (row) => row.toJson(),
      ),
      'backups': await _exportarLinhas(
        await db.select(db.backupSnapshots).get(),
        _descriptografarRetratoBackup,
        (row) => row.toJson(),
      ),
    };
  }

  Future<void> restaurarArquivoBackup(File file) async {
    final rawDecoded = jsonDecode(await file.readAsString());
    if (rawDecoded is! Map<String, dynamic>) {
      throw const FormatException('Arquivo de backup invalido.');
    }
    final decoded = await CriptografiaBackupService.instance.descriptografarBackup(
      rawDecoded,
    );
    if (decoded['format'] != CriptografiaBackupService.plainFormat) {
      throw const FormatException('Arquivo de backup invalido.');
    }

    await db.transaction(() async {
      await db.delete(db.attendanceEntries).go();
      await db.delete(db.gradeRecords).go();
      await db.delete(db.generatedMaterials).go();
      await db.delete(db.appHistory).go();
      await db.delete(db.backupSnapshots).go();
      await db.delete(db.attendanceRecords).go();
      await db.delete(db.students).go();
      await db.delete(db.classes).go();
      await db.delete(db.localFiles).go();
      await db.delete(db.localFolders).go();
      await db.delete(db.localSettings).go();

      await _restaurarLista(decoded['settings'], (row) async {
        return db
            .into(db.localSettings)
            .insert(
              (await _criptografarConfiguracao(
                LocalSetting.fromJson(row),
              )).toCompanion(true),
            );
      });
      await _restaurarLista(decoded['folders'], (row) async {
        return db
            .into(db.localFolders)
            .insert(
              (await _criptografarPasta(
                LocalFolder.fromJson(row),
              )).toCompanion(true),
            );
      });
      await _restaurarLista(decoded['files'], (row) async {
        return db
            .into(db.localFiles)
            .insert(
              (await _criptografarArquivo(LocalFile.fromJson(row))).toCompanion(true),
            );
      });
      await _restaurarLista(decoded['classes'], (row) async {
        return db
            .into(db.classes)
            .insert(
              (await _criptografarTurma(
                SchoolClass.fromJson(row),
              )).toCompanion(true),
            );
      });
      await _restaurarLista(decoded['students'], (row) async {
        return db
            .into(db.students)
            .insert(
              (await _criptografarAluno(Student.fromJson(row))).toCompanion(true),
            );
      });
      await _restaurarLista(decoded['attendanceRecords'], (row) async {
        return db
            .into(db.attendanceRecords)
            .insert(
              (await _criptografarRegistroPresenca(
                AttendanceRecord.fromJson(row),
              )).toCompanion(true),
            );
      });
      await _restaurarLista(decoded['attendanceEntries'], (row) async {
        return db
            .into(db.attendanceEntries)
            .insert(
              (await _criptografarEntradaPresenca(
                AttendanceEntry.fromJson(row),
              )).toCompanion(true),
            );
      });
      await _restaurarLista(decoded['gradeRecords'], (row) async {
        return db
            .into(db.gradeRecords)
            .insert(
              (await _criptografarRegistroNota(
                GradeRecord.fromJson(row),
              )).toCompanion(true),
            );
      });
      await _restaurarLista(decoded['generatedMaterials'], (row) async {
        return db
            .into(db.generatedMaterials)
            .insert(
              (await _criptografarMaterialGerado(
                GeneratedMaterial.fromJson(row),
              )).toCompanion(true),
            );
      });
      await _restaurarLista(decoded['history'], (row) async {
        return db
            .into(db.appHistory)
            .insert(
              (await _criptografarHistorico(
                AppHistoryEntry.fromJson(row),
              )).toCompanion(true),
            );
      });
      await _restaurarLista(decoded['backups'], (row) async {
        return db
            .into(db.backupSnapshots)
            .insert(
              (await _criptografarRetratoBackup(
                BackupSnapshot.fromJson(row),
              )).toCompanion(true),
            );
      });
    });

    await definirConfiguracao('security.localEncryptionMigrated.v1', 'true');
    await registrarHistorico(eventType: 'backup_restore', title: 'Backup restaurado');
  }
}
