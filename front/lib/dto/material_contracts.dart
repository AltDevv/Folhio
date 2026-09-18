part of '../service/api/folhio_api_gateway.dart';

class FolhioModeloMaterial {
  final String id;
  final String name;
  final String materialType;
  final String styleCode;
  final String description;

  const FolhioModeloMaterial({
    required this.id,
    required this.name,
    required this.materialType,
    required this.styleCode,
    required this.description,
  });

  factory FolhioModeloMaterial.deJson(Map<String, dynamic> json) {
    return FolhioModeloMaterial(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Template',
      materialType: json['materialType']?.toString() ?? '',
      styleCode: json['styleCode']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class FolhioCatalogoMateriais {
  final List<String> disciplines;
  final List<String> subjects;
  final List<String> schoolYears;
  final List<String> difficulties;
  final List<FolhioModeloMaterial> templates;

  const FolhioCatalogoMateriais({
    required this.disciplines,
    required this.subjects,
    required this.schoolYears,
    required this.difficulties,
    required this.templates,
  });

  factory FolhioCatalogoMateriais.deJson(Map<String, dynamic> json) {
    return FolhioCatalogoMateriais(
      disciplines: _listaTextos(json['disciplines']),
      subjects: _listaTextos(json['subjects']),
      schoolYears: _listaTextos(json['schoolYears']),
      difficulties: _listaTextos(json['difficulties']),
      templates: (json['templates'] as List? ?? const [])
          .whereType<Map>()
          .map((item) {
            return FolhioModeloMaterial.deJson(
              Map<String, dynamic>.from(item),
            );
          })
          .toList(growable: false),
    );
  }

  static List<String> _listaTextos(Object? raw) {
    return (raw as List? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class FolhioGeracaoMaterialRequest {
  final String title;
  final String materialType;
  final String discipline;
  final String subject;
  final String schoolYear;
  final String difficulty;
  final String templateId;
  final String teacherName;
  final String className;
  final String instructions;
  final int questionCount;
  final bool includeAnswerKey;
  final bool shuffleQuestions;
  final bool shuffleOptions;

  const FolhioGeracaoMaterialRequest({
    required this.title,
    required this.materialType,
    required this.discipline,
    required this.subject,
    required this.schoolYear,
    required this.difficulty,
    required this.templateId,
    required this.teacherName,
    required this.className,
    required this.instructions,
    required this.questionCount,
    required this.includeAnswerKey,
    required this.shuffleQuestions,
    required this.shuffleOptions,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'materialType': materialType,
      'discipline': discipline,
      'subject': subject,
      'schoolYear': schoolYear,
      'difficulty': difficulty,
      'templateId': templateId,
      'teacherName': teacherName,
      'className': className,
      'instructions': instructions,
      'questionCount': questionCount,
      'includeAnswerKey': includeAnswerKey,
      'shuffleQuestions': shuffleQuestions,
      'shuffleOptions': shuffleOptions,
    };
  }
}

class FolhioMaterialGerado {
  static const docxMime =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

  final bool success;
  final String generatedMaterialId;
  final String fileId;
  final String fileName;
  final String downloadUrl;
  final String templateId;
  final int questionCount;
  final List<FolhioQuestaoGerada> questions;

  const FolhioMaterialGerado({
    required this.success,
    required this.generatedMaterialId,
    required this.fileId,
    required this.fileName,
    required this.downloadUrl,
    required this.templateId,
    required this.questionCount,
    required this.questions,
  });

  factory FolhioMaterialGerado.deJson(Map<String, dynamic> json) {
    return FolhioMaterialGerado(
      success: json['success'] == true,
      generatedMaterialId: json['generatedMaterialId']?.toString() ?? '',
      fileId: json['fileId']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? 'material.docx',
      downloadUrl: json['downloadUrl']?.toString() ?? '',
      templateId: json['templateId']?.toString() ?? '',
      questionCount: json['questionCount'] is int
          ? json['questionCount'] as int
          : 0,
      questions: (json['questions'] as List? ?? const [])
          .whereType<Map>()
          .map((item) {
            return FolhioQuestaoGerada.deJson(
              Map<String, dynamic>.from(item),
            );
          })
          .toList(growable: false),
    );
  }

  FolhioArquivoSaida get outputFile {
    return FolhioArquivoSaida(
      fileName: fileName,
      mimeType: docxMime,
      storageKey: fileId,
      downloadUrl: downloadUrl,
    );
  }
}

class FolhioQuestaoGerada {
  final String id;
  final String discipline;
  final String subject;
  final String schoolYear;
  final String difficulty;
  final String statement;

  const FolhioQuestaoGerada({
    required this.id,
    required this.discipline,
    required this.subject,
    required this.schoolYear,
    required this.difficulty,
    required this.statement,
  });

  factory FolhioQuestaoGerada.deJson(Map<String, dynamic> json) {
    return FolhioQuestaoGerada(
      id: json['id']?.toString() ?? '',
      discipline: json['discipline']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      schoolYear: json['schoolYear']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      statement: json['statement']?.toString() ?? '',
    );
  }
}

class FolhioResumoMaterialGerado {
  final String id;
  final String title;
  final String materialType;
  final String discipline;
  final String subject;
  final String schoolYear;
  final String difficulty;
  final String templateId;
  final int questionCount;
  final String fileId;
  final String fileName;
  final String downloadUrl;
  final DateTime? createdAt;

  const FolhioResumoMaterialGerado({
    required this.id,
    required this.title,
    required this.materialType,
    required this.discipline,
    required this.subject,
    required this.schoolYear,
    required this.difficulty,
    required this.templateId,
    required this.questionCount,
    required this.fileId,
    required this.fileName,
    required this.downloadUrl,
    required this.createdAt,
  });

  factory FolhioResumoMaterialGerado.deJson(Map<String, dynamic> json) {
    return FolhioResumoMaterialGerado(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      materialType: json['materialType']?.toString() ?? '',
      discipline: json['discipline']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      schoolYear: json['schoolYear']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      templateId: json['templateId']?.toString() ?? '',
      questionCount: json['questionCount'] is int
          ? json['questionCount'] as int
          : 0,
      fileId: json['fileId']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      downloadUrl: json['downloadUrl']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
