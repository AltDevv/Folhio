import 'package:drift/drift.dart';

@DataClassName('LocalFile')
class LocalFiles extends Table {
  TextColumn get id => text()();
  TextColumn get fileName => text()();

  TextColumn get mimeType =>
      text().withDefault(const Constant('application/octet-stream'))();

  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get remoteStorageKey => text().nullable()();
  TextColumn get folderId => text().nullable()();

  TextColumn get folderName =>
      text().withDefault(const Constant('Arquivos'))();

  TextColumn get origin =>
      text().withDefault(const Constant('local'))();

  BoolColumn get pendingBackup =>
      boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LocalFolder')
class LocalFolders extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get links => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}