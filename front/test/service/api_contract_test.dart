import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:folhio/config/rotas_api_folhio.dart';
import 'package:folhio/dto/folhio_action.dart';
import 'package:folhio/security/files/envio_policy.dart';
import 'package:folhio/service/api/folhio_api_gateway.dart';

void main() {
  test('limite de upload acompanha o backend', () {
    expect(EnvioPolicy.permiteTamanho(0), isFalse);
    expect(EnvioPolicy.permiteTamanho(-1), isFalse);
    expect(EnvioPolicy.permiteTamanho(EnvioPolicy.maxBytes - 1), isTrue);
    expect(EnvioPolicy.permiteTamanho(EnvioPolicy.maxBytes), isFalse);
    expect(EnvioPolicy.maxBytes, 262144000);
  });

  test('rotas de arquivo codificam identificadores', () {
    expect(RotasApiFolhio.baixar('abc'), '/api/folhio/files/abc/download');
    expect(
      RotasApiFolhio.visualizar('abc', 2),
      '/api/folhio/files/abc/preview?page=2',
    );
    expect(RotasApiFolhio.arquivo('a/b'), '/api/folhio/files/a%2Fb');
  });

  test('upload e acao enviam headers e contratos HTTP esperados', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String>[];
    final errors = <Object>[];
    final subscription = server.listen((request) async {
      try {
        if (request.uri.path.startsWith('/ws/')) {
          request.response.statusCode = 404;
          await request.response.close();
          return;
        }
        requests.add(request.uri.path);
        expect(request.headers.value('Authorization'), 'Bearer test-token');
        expect(request.headers.value('X-API-Key'), 'test-key');
        expect(request.headers.value('X-Folhio-Client-Id'), 'test-client-123');
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == RotasApiFolhio.upload) {
          expect(request.method, 'POST');
          expect(request.uri.queryParameters['persistent'], 'true');
          final body = await utf8.decoder.bind(request).join();
          expect(body, contains('name="file"; filename="sample.pdf"'));
          request.response.write(
            jsonEncode({
              'success': true,
              'fileId': 'file-123',
              'fileName': 'sample.pdf',
              'mimeType': 'application/pdf',
              'sizeBytes': 20,
              'pageCount': 1,
              'pageWidth': 595.0,
              'pageHeight': 842.0,
              'downloadUrl': '/api/folhio/files/file-123/download',
            }),
          );
        } else {
          expect(request.uri.path, RotasApiFolhio.actions);
          final body =
              jsonDecode(await utf8.decoder.bind(request).join()) as Map;
          expect(body['type'], 'pdf_poster');
          expect((body['payload'] as Map)['fileId'], 'file-123');
          request.response.write(
            jsonEncode({
              'success': true,
              'status': 'completed',
              'requestId': 'test-action',
              'message': 'OK',
              'data': <String, dynamic>{},
            }),
          );
        }
        await request.response.close();
      } catch (error) {
        errors.add(error);
        await request.response.close();
      }
    });
    final api = FolhioApiGateway(
      baseUrl: 'http://127.0.0.1:${server.port}',
      resolveHeaders: () async => {
        'Authorization': 'Bearer test-token',
        'X-API-Key': 'test-key',
        'X-Folhio-Client-Id': 'test-client-123',
      },
    );
    try {
      final file = await api.enviarBytes(
        utf8.encode('%PDF-1.4\n%%EOF'),
        fileName: 'sample.pdf',
        persistent: true,
        keepProgress: true,
      );
      expect(file.fileId, 'file-123');
      expect(file.pageCount, 1);
      expect(file.pageWidth, 595);
      final result = await api.enviar(
        FolhioAcaoRequest(
          requestId: 'test-action',
          category: 'edit',
          type: 'pdf_poster',
          title: 'Poster',
          description: '',
          payload: {'fileId': file.fileId},
        ),
      );
      expect(result.success, isTrue);
      expect(requests, [RotasApiFolhio.upload, RotasApiFolhio.actions]);
      expect(errors, isEmpty);
    } finally {
      api.fechar();
      await subscription.cancel();
      await server.close(force: true);
      FolhioApiGateway.progress.value = null;
      FolhioApiGateway.generatedFile.value = null;
    }
  });
}
