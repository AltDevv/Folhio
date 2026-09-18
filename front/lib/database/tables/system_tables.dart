import 'package:drift/drift.dart';

@DataClassName('AppHistoryEntry')
class AppHistory extends Table {
  TextColumn get id => text()();
  TextColumn get eventType => text()();
  TextColumn get title => text()();

  TextColumn get detailsJson =>
      text().withDefault(const Constant('{}'))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BackupSnapshot')
class BackupSnapshots extends Table {
  TextColumn get id => text()();

  TextColumn get destination =>
      text().withDefault(const Constant('local'))();

  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  TextColumn get filePath => text().nullable()();

  TextColumn get errorMessage =>
      text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}