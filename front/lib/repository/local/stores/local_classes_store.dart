part of '../persistencia_local_repository.dart';

class _TurmasLocaisStore {
  _TurmasLocaisStore(this._owner);

  final PersistenciaLocalRepository _owner;

  Future<List<SchoolClass>> listarTurmas({int limit = 80}) async {
    final query = _owner.db.select(_owner.db.classes)
      ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)])
      ..limit(limit);
    final rows = await Future.wait(
      (await query.get()).map(_owner._descriptografarTurma),
    );
    final readable = <SchoolClass>[];
    for (final row in rows) {
      if (_owner._temTextoTurmaIlegivel(row)) {
        await (_owner.db.delete(
          _owner.db.classes,
        )..where((table) => table.id.equals(row.id))).go();
        continue;
      }
      readable.add(row);
    }
    return readable;
  }

  Future<SchoolClass> salvarTurma({
    String? id,
    required String name,
    String schoolYear = '',
    String subject = '',
    String shift = '',
  }) async {
    final now = DateTime.now();
    final classId = id ?? _owner._id('class');
    await _owner.db
        .into(_owner.db.classes)
        .insertOnConflictUpdate(
          ClassesCompanion.insert(
            id: classId,
            name: await _owner._encryption.criptografarTexto(name),
            schoolYear: Value(await _owner._encryption.criptografarTexto(schoolYear)),
            subject: Value(await _owner._encryption.criptografarTexto(subject)),
            shift: Value(await _owner._encryption.criptografarTexto(shift)),
            updatedAt: Value(now),
          ),
        );
    final row = await (_owner.db.select(
      _owner.db.classes,
    )..where((table) => table.id.equals(classId))).getSingle();
    final saved = await _owner._descriptografarTurma(row);
    return saved;
  }

  Future<void> excluirTurma(String id) async {
    await (_owner.db.delete(
      _owner.db.classes,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<List<Student>> listarAlunos(String classId) async {
    final query = _owner.db.select(_owner.db.students)
      ..where((table) => table.classId.equals(classId))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    final rows = await query.get();
    final students = await Future.wait(rows.map(_owner._descriptografarAluno));
    students.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return students;
  }

  Future<Student> salvarAluno({
    String? id,
    required String classId,
    required String name,
    String registration = '',
    bool active = true,
  }) async {
    final now = DateTime.now();
    final studentId = id ?? _owner._id('student');
    await _owner.db
        .into(_owner.db.students)
        .insertOnConflictUpdate(
          StudentsCompanion.insert(
            id: studentId,
            classId: classId,
            name: await _owner._encryption.criptografarTexto(name),
            registration: Value(
              await _owner._encryption.criptografarTexto(registration),
            ),
            active: Value(active),
            updatedAt: Value(now),
          ),
        );
    final row = await (_owner.db.select(
      _owner.db.students,
    )..where((table) => table.id.equals(studentId))).getSingle();
    final saved = await _owner._descriptografarAluno(row);
    return saved;
  }

  Future<void> excluirAluno(String id) async {
    await (_owner.db.delete(
      _owner.db.students,
    )..where((table) => table.id.equals(id))).go();
  }
}
