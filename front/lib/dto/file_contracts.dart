part of '../service/api/folhio_api_gateway.dart';

class FolhioArquivoGerado {
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
  final String? storageKey;
  final String? downloadUrl;
  final String? localPath;

  const FolhioArquivoGerado({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    this.storageKey,
    this.downloadUrl,
    this.localPath,
  });
}

class FolhioArquivoEnviado {
  final String fileId;
  final String fileName;
  final String mimeType;
  final int? sizeBytes;
  final String? downloadUrl;
  final int? pageCount;
  final double? pageWidth;
  final double? pageHeight;

  const FolhioArquivoEnviado({
    required this.fileId,
    required this.fileName,
    required this.mimeType,
    this.sizeBytes,
    this.downloadUrl,
    this.pageCount,
    this.pageWidth,
    this.pageHeight,
  });

  factory FolhioArquivoEnviado.deJson(Map<String, dynamic> json) {
    return FolhioArquivoEnviado(
      fileId: json['fileId']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
      sizeBytes: json['sizeBytes'] is int ? json['sizeBytes'] as int : null,
      downloadUrl: json['downloadUrl']?.toString(),
      pageCount: json['pageCount'] is int ? json['pageCount'] as int : null,
      pageWidth: json['pageWidth'] is num
          ? (json['pageWidth'] as num).toDouble()
          : null,
      pageHeight: json['pageHeight'] is num
          ? (json['pageHeight'] as num).toDouble()
          : null,
    );
  }
}

class FolhioArquivoBiblioteca {
  final String id;
  final String? folderId;
  final String folder;
  final String fileName;
  final String mimeType;
  final int? sizeBytes;
  final String storageKey;
  final String downloadUrl;
  final String origin;
  final bool requiresPaidPlan;
  final DateTime? updatedAt;

  const FolhioArquivoBiblioteca({
    required this.id,
    this.folderId,
    required this.folder,
    required this.fileName,
    required this.mimeType,
    required this.storageKey,
    required this.downloadUrl,
    required this.origin,
    this.requiresPaidPlan = false,
    this.sizeBytes,
    this.updatedAt,
  });

  factory FolhioArquivoBiblioteca.deJson(Map<String, dynamic> json) {
    final requiresPaidPlan =
        json['requiresPaidPlan'] == true ||
        json['premium'] == true ||
        json['paid'] == true;
    return FolhioArquivoBiblioteca(
      id: json['id']?.toString() ?? '',
      folderId: json['folderId']?.toString(),
      folder: json['folder']?.toString() ?? 'Arquivos',
      fileName: json['fileName']?.toString() ?? 'arquivo',
      mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
      sizeBytes: json['sizeBytes'] is int ? json['sizeBytes'] as int : null,
      storageKey: json['storageKey']?.toString() ?? '',
      downloadUrl: json['downloadUrl']?.toString() ?? '',
      origin: json['origin']?.toString() ?? 'app',
      requiresPaidPlan: requiresPaidPlan,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class FolhioPastaBiblioteca {
  final String id;
  final String? parentId;
  final String name;
  final String tags;
  final String notes;
  final String links;
  final DateTime? updatedAt;

  const FolhioPastaBiblioteca({
    required this.id,
    this.parentId,
    required this.name,
    required this.tags,
    required this.notes,
    required this.links,
    this.updatedAt,
  });

  factory FolhioPastaBiblioteca.deJson(Map<String, dynamic> json) {
    final rawParentId = json['parentId']?.toString();
    return FolhioPastaBiblioteca(
      id: json['id']?.toString() ?? '',
      parentId: rawParentId == null || rawParentId.isEmpty ? null : rawParentId,
      name: json['name']?.toString() ?? 'Pasta',
      tags: json['tags']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      links: json['links']?.toString() ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}
