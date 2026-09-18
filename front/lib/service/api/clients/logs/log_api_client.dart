part of '../../folhio_api_gateway.dart';

class _FolhioLogApiClient {
  final FolhioApiGateway _owner;

  const _FolhioLogApiClient(this._owner);

  Future<void> registrarEventoCliente(
    FolhioEventoRegistroClienteRequest event,
  ) async {
    try {
      final uri = Uri.parse('${_owner.baseUrl}${RotasApiFolhio.clientLogs}');
      final request = await _owner._httpClient
          .postUrl(uri)
          .timeout(const Duration(seconds: 2));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      if (FolhioApiGateway.apiKey.isNotEmpty) {
        request.headers.set(
          FolhioApiGateway.apiKeyHeader,
          FolhioApiGateway.apiKey,
        );
      }
      request.headers.set(
        FolhioApiGateway.appVersionHeader,
        FolhioApiGateway.appVersion,
      );
      request.headers.set(
        FolhioApiGateway.deviceHeader,
        FolhioApiGateway.appDeviceName,
      );
      if (FolhioApiGateway.proxyBypassHeaderName.isNotEmpty) {
        request.headers.set(
          FolhioApiGateway.proxyBypassHeaderName,
          FolhioApiGateway.proxyBypassHeaderValue,
        );
      }
      request.headers.set(
        HttpHeaders.userAgentHeader,
        FolhioApiGateway.appUserAgent,
      );
      request.headers.set(
        FolhioApiGateway.clientIdHeader,
        await _owner._identificadorClienteLocal(),
      );
      if (event.requestId != null && event.requestId!.isNotEmpty) {
        request.headers.set(FolhioApiGateway.requestIdHeader, event.requestId!);
      }
      request.write(jsonEncode(event.toJson()));
      final response = await request.close().timeout(
        const Duration(seconds: 2),
      );
      await response.drain<void>().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Log de cliente nunca pode atrapalhar a operacao principal do app.
    }
  }
}
