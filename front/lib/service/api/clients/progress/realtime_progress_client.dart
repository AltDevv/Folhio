part of '../../folhio_api_gateway.dart';

class _ConexaoProgressoTempoReal {
  final String requestId;
  final Future<WebSocket> _socket;
  bool _cancelled = false;
  WebSocket? _connected;

  _ConexaoProgressoTempoReal({
    required this.requestId,
    required Uri uri,
    required Map<String, String> headers,
  }) : _socket = WebSocket.connect(uri.toString(), headers: headers) {
    unawaited(_escutar());
  }

  Future<void> _escutar() async {
    try {
      final socket = await _socket.timeout(const Duration(seconds: 5));
      if (_cancelled) {
        await socket.close();
        return;
      }
      _connected = socket;
      await for (final event in socket) {
        if (_cancelled) {
          break;
        }
        if (FolhioApiGateway.generatedFile.value != null) {
          break;
        }
        if (event is! String || event.trim().isEmpty) {
          continue;
        }
        final decoded = jsonDecode(event);
        if (decoded is Map<String, dynamic>) {
          final next = FolhioProgressoOperacao.deJson(decoded);
          final current = FolhioApiGateway.progress.value;
          if (current != null && next.progress < current.progress) {
            continue;
          }
          FolhioApiGateway.progress.value = next;
        }
      }
    } catch (_) {
      // If realtime progress fails, the operation still finishes by its HTTP response.
    }
  }

  Future<void> cancelar() async {
    _cancelled = true;
    try {
      final socket =
          _connected ??
          await _socket.timeout(const Duration(milliseconds: 300));
      await socket.close();
    } catch (_) {
      // Best effort cleanup.
    }
  }
}
