import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../security/authentication/conta_google_service.dart';
import '../../repository/local/persistencia_local_repository.dart';

class IntegracoesGoogleController {
  static const List<String> _driveScopes = [
    'https://www.googleapis.com/auth/drive.file',
  ];

  static final ContaGoogleService _google = ContaGoogleService.instance;

  GoogleSignInAccount? get currentAccount => _google.currentAccount;

  Future<void> inicializar() => _google.inicializar();

  Future<GoogleSignInAccount> iniciarSessao() async {
    try {
      return await _google.autenticar();
    } on GoogleSignInException catch (error) {
      throw IntegracaoGoogleException(
        error.code == GoogleSignInExceptionCode.clientConfigurationError
            ? 'A conexão com o Google deste APK não corresponde ao servidor. Gere o app novamente.'
            : 'Este aparelho não abriu o login do Google. Tente atualizar o Google Play Services.',
      );
    }
  }

  Future<void> encerrarSessao() async {
    await _google.encerrarSessao();
  }

  Future<List<ArquivoGoogleDrive>> listarArquivosDrive() async {
    final headers = await _cabecalhosAutorizacao(_driveScopes);
    final uri = Uri.https('www.googleapis.com', '/drive/v3/files', {
      'q': 'trashed=false',
      'pageSize': '20',
      'orderBy': 'createdTime desc',
      'fields': 'files(id,name,mimeType,webViewLink,createdTime)',
    });

    final response = await http.get(uri, headers: headers);
    _lancarSeErroGoogle(
      response,
      'Não foi possível buscar seus arquivos no Google Drive.',
    );

    final data = _decodificarObjeto(response.body);
    final files = data['files'] as List<dynamic>? ?? [];
    return files
        .whereType<Map<String, dynamic>>()
        .map(ArquivoGoogleDrive.deJson)
        .toList();
  }

  Future<ArquivoGoogleDrive> enviarArquivoParaDrive(
    File file, {
    String? folderName,
  }) async {
    final folderId = folderName == null || folderName.trim().isEmpty
        ? null
        : await _criarPastaDrive(folderName.trim());

    final headers = await _cabecalhosAutorizacao(_driveScopes);
    final bytes = await PersistenciaLocalRepository.instance.lerArquivoLocalCriptografado(
      file,
    );
    final boundary = 'folhio-${DateTime.now().microsecondsSinceEpoch}';
    final fileName = file.uri.pathSegments.isEmpty
        ? 'arquivo-folhio'
        : file.uri.pathSegments.last;
    final metadata = <String, dynamic>{
      'name': fileName,
      if (folderId != null) 'parents': [folderId],
    };

    final body = BytesBuilder();
    _adicionarMultipartTexto(
      body,
      boundary,
      contentType: 'application/json; charset=UTF-8',
      text: jsonEncode(metadata),
    );
    _adicionarMultipartBytes(
      body,
      boundary,
      contentType: _tipoConteudoPara(fileName),
      bytes: bytes,
    );
    body.add(utf8.encode('--$boundary--\r\n'));

    final response = await http.post(
      Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files'
        '?uploadType=multipart&fields=id,name,mimeType,webViewLink,createdTime',
      ),
      headers: {
        ...headers,
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      body: body.toBytes(),
    );

    _lancarSeErroGoogle(
      response,
      'Não foi possível enviar o arquivo para o Google Drive.',
    );
    return ArquivoGoogleDrive.deJson(_decodificarObjeto(response.body));
  }

  Future<String> _criarPastaDrive(String name) async {
    final headers = await _cabecalhosAutorizacao(_driveScopes);
    final response = await http.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files?fields=id,name'),
      headers: {...headers, 'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'name': name,
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );

    _lancarSeErroGoogle(
      response,
      'Não foi possível criar a pasta no Google Drive.',
    );
    final data = _decodificarObjeto(response.body);
    return data['id'] as String;
  }

  Future<Map<String, String>> _cabecalhosAutorizacao(List<String> scopes) async {
    final account = await iniciarSessao();
    final headers = await account.authorizationClient.authorizationHeaders(
      scopes,
      promptIfNecessary: true,
    );

    if (headers == null) {
      throw const IntegracaoGoogleException(
        'Permissão do Google não liberada. Entre novamente e autorize o acesso.',
      );
    }

    return headers;
  }

  static Map<String, dynamic> _decodificarObjeto(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  static void _lancarSeErroGoogle(http.Response response, String fallback) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const IntegracaoGoogleException(
        'O Google não liberou essa ação. Verifique se a conta autorizou o app e tente novamente.',
      );
    }

    String? message;
    try {
      final data = _decodificarObjeto(response.body);
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        message = error['message'] as String?;
      }
    } catch (_) {
      message = null;
    }

    throw IntegracaoGoogleException(
      message == null ? fallback : '$fallback $message',
    );
  }

  static String _tipoConteudoPara(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.folhio-backup')) return 'application/octet-stream';
    return 'application/octet-stream';
  }

  static void _adicionarMultipartTexto(
    BytesBuilder body,
    String boundary, {
    required String contentType,
    required String text,
  }) {
    body.add(utf8.encode('--$boundary\r\n'));
    body.add(utf8.encode('Content-Type: $contentType\r\n\r\n'));
    body.add(utf8.encode('$text\r\n'));
  }

  static void _adicionarMultipartBytes(
    BytesBuilder body,
    String boundary, {
    required String contentType,
    required Uint8List bytes,
  }) {
    body.add(utf8.encode('--$boundary\r\n'));
    body.add(utf8.encode('Content-Type: $contentType\r\n\r\n'));
    body.add(bytes);
    body.add(utf8.encode('\r\n'));
  }
}

class ArquivoGoogleDrive {
  final String id;
  final String name;
  final String mimeType;
  final String? webViewLink;
  final DateTime? createdTime;

  const ArquivoGoogleDrive({
    required this.id,
    required this.name,
    required this.mimeType,
    this.webViewLink,
    this.createdTime,
  });

  factory ArquivoGoogleDrive.deJson(Map<String, dynamic> json) {
    return ArquivoGoogleDrive(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Arquivo',
      mimeType: json['mimeType'] as String? ?? '',
      webViewLink: json['webViewLink'] as String?,
      createdTime: _tentarInterpretarData(json['createdTime'] as String?),
    );
  }
}

class IntegracaoGoogleException implements Exception {
  final String message;

  const IntegracaoGoogleException(this.message);

  @override
  String toString() => message;
}

DateTime? _tentarInterpretarData(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
