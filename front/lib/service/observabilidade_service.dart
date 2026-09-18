import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../config/ambiente_folhio_config.dart';

class ObservabilidadeService {
  static int _pendentes = 0;
  static final Map<String, DateTime> _recentes = {};

  static void registrar(
    String evento,
    String mensagem, {
    String nivel = 'INFO',
    String? requestId,
    Map<String, Object?> detalhes = const {},
  }) {
    final agora = DateTime.now();
    final anterior = _recentes[evento];
    if (_pendentes >= 4 ||
        (anterior != null && agora.difference(anterior).inSeconds < 3)) {
      return;
    }
    _recentes.removeWhere((_, data) => agora.difference(data).inMinutes > 5);
    _recentes[evento] = agora;
    unawaited(_enviar(evento, mensagem, nivel, requestId, detalhes));
  }

  static Future<void> _enviar(
    String evento,
    String mensagem,
    String nivel,
    String? requestId,
    Map<String, Object?> detalhes,
  ) async {
    _pendentes++;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final requisicao = await client
          .postUrl(
            Uri.parse(
              '${AmbienteFolhioConfig.apiBaseUrl}/api/folhio/logs/client',
            ),
          )
          .timeout(const Duration(seconds: 3));
      requisicao.headers.contentType = ContentType.json;
      requisicao.headers.set(
        'X-Request-Id',
        requestId ?? 'app-${DateTime.now().microsecondsSinceEpoch}',
      );
      requisicao.headers.set(
        'X-Folhio-App-Version',
        AmbienteFolhioConfig.appVersion,
      );
      requisicao.headers.set('X-Folhio-Device', Platform.operatingSystem);
      requisicao.headers.set('ngrok-skip-browser-warning', 'true');
      requisicao.write(
        jsonEncode({
          'nivel': nivel,
          'categoria': 'CLIENTE',
          'evento': evento,
          'mensagem': mensagem,
          'detalhes': detalhes,
        }),
      );
      final resposta = await requisicao.close().timeout(
        const Duration(seconds: 3),
      );
      await resposta.drain<void>().timeout(const Duration(seconds: 3));
    } catch (_) {
      // A indisponibilidade da telemetria nao interfere na operacao principal.
    } finally {
      client.close(force: true);
      _pendentes--;
    }
  }
}
