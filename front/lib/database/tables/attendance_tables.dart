import 'package:drift/drift.dart';

import 'school_tables.dart';

@DataClassName('AttendanceRecord')
class AttendanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get classId => text().references(Classes, #id)();
  DateTimeColumn get date => dateTime()();

  TextColumn get notes =>
      text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AttendanceEntry')
class AttendanceEntries extends Table {
  TextColumn get id => text()();

  TextColumn get attendanceId =>
      text().references(AttendanceRecords, #id)();

  TextColumn get studentId =>
      text().references(Students, #id)();

  TextColumn get status =>
      text().withDefault(const Constant('present'))();

  TextColumn get note =>
      text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}