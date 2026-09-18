import 'package:drift/drift.dart';

@DataClassName('SchoolClass')
class Classes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  TextColumn get schoolYear =>
      text().withDefault(const Constant(''))();

  TextColumn get subject =>
      text().withDefault(const Constant(''))();

  TextColumn get shift =>
      text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('Student')
class Students extends Table {
  TextColumn get id => text()();
  TextColumn get classId => text().references(Classes, #id)();
  TextColumn get name => text()();

  TextColumn get registration =>
      text().withDefault(const Constant(''))();

  BoolColumn get active =>
      boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}