import 'dart:convert';

/// Envelope padrão que o app envia para ações gerais do backend Java.
///
/// Ele ainda existe porque várias ferramentas do Folhio usam o mesmo endpoint:
/// `POST /api/folhio/actions`.
///
/// O backend decide o que fazer a partir de campos claros:
/// - `category`: área do app, como `converter`, `edit`, `tools` ou `ai`;
/// - `type`: ação específica, como `convert_document` ou `merge_pdfs`;
/// - `legacyOperationName`: nome antigo usado para reaproveitar serviços que
///   já existiam no backend.
///
/// Esse envelope evita criar um endpoint novo para cada ferramenta pequena,
/// mas ainda mantém um contrato conhecido entre Flutter e Spring Boot.
class FolhioAcaoRequest {
  final String requestId;
  final String category;
  final String type;
  final String title;
  final String description;
  final String? legacyOperationName;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> client;

  FolhioAcaoRequest({
    required this.requestId,
    required this.category,
    required this.type,
    required this.title,
    required this.description,
    required this.payload,
    this.legacyOperationName,
    Map<String, dynamic>? client,
  }) : client = client ?? FolhioInformacoesCliente.informacoesPadrao();

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'app': 'folhio',
      'schemaVersion': 1,
      'category': category,
      'type': type,
      'title': title,
      'description': description,
      'legacyOperationName': legacyOperationName,
      'client': client,
      'payload': payload,
    };
  }

  String codificar() => jsonEncode(toJson());
}

/// Resposta padrão esperada do backend para uma ação geral.
///
/// Assim o Flutter consegue tratar sucesso, erro, mensagem para o usuário,
/// arquivo final e dados extras sem criar uma resposta diferente para cada tela.
class FolhioAcaoResponse {
  final String requestId;
  final bool success;
  final String status;
  final String message;
  final Map<String, dynamic> data;
  final FolhioArquivoSaida? outputFile;

  FolhioAcaoResponse({
    required this.requestId,
    required this.success,
    required this.status,
    required this.message,
    required this.data,
    this.outputFile,
  });

  factory FolhioAcaoResponse.deJson(Map<String, dynamic> json) {
    final output = json['outputFile'];

    return FolhioAcaoResponse(
      requestId: json['requestId']?.toString() ?? '',
      success: json['success'] == true,
      status: json['status']?.toString() ?? 'unknown',
      message: json['message']?.toString() ?? '',
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      outputFile: output is Map
          ? FolhioArquivoSaida.deJson(Map<String, dynamic>.from(output))
          : null,
    );
  }
}

/// Metadados de um arquivo gerado pelo backend.
///
/// O backend pode devolver um link de download, um identificador de storage ou
/// os dois, dependendo do tipo de operação.
class FolhioArquivoSaida {
  final String fileName;
  final String mimeType;
  final int? sizeBytes;
  final String? downloadUrl;
  final String? storageKey;

  FolhioArquivoSaida({
    required this.fileName,
    required this.mimeType,
    this.sizeBytes,
    this.downloadUrl,
    this.storageKey,
  });

  factory FolhioArquivoSaida.deJson(Map<String, dynamic> json) {
    return FolhioArquivoSaida(
      fileName: json['fileName']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
      sizeBytes: json['sizeBytes'] is int ? json['sizeBytes'] as int : null,
      downloadUrl: json['downloadUrl']?.toString(),
      storageKey: json['storageKey']?.toString(),
    );
  }
}

class FolhioInformacoesCliente {
  static Map<String, dynamic> informacoesPadrao() {
    return {
      'platform': 'flutter',
      'locale': 'pt_BR',
      'timezone': 'America/Sao_Paulo',
    };
  }
}

String criarIdRequisicao(String prefix) {
  final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
  return '$prefix-$timestamp';
}
