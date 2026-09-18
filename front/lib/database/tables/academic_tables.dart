import 'package:drift/drift.dart';

import 'library_tables.dart';
import 'school_tables.dart';

@DataClassName('GradeRecord')
class GradeRecords extends Table {
  TextColumn get id => text()();
  TextColumn get classId => text().references(Classes, #id)();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get label => text()();
  RealColumn get value => real()();

  RealColumn get weight =>
      real().withDefault(const Constant(1))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GeneratedMaterial')
class GeneratedMaterials extends Table {
  TextColumn get id => text()();
  TextColumn get materialType => text()();
  TextColumn get subject => text()();
  TextColumn get theme => text()();
  TextColumn get contentJson => text()();

  TextColumn get localFileId =>
      text().nullable().references(LocalFiles, #id)();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}