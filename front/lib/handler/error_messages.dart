part of '../service/api/folhio_api_gateway.dart';

class _FolhioMensagensErro {
  static String humanizarErro(Object error) {
    if (error is FolhioExibicaoUsuarioException) {
      return error.message;
    }
    if (error is FolhioConflitoBibliotecaException) {
      return 'Já existe um arquivo com esse nome na biblioteca.';
    }
    if (error is FolhioSemInternetException) {
      return 'Você está sem internet. Conecte-se e tente de novo.';
    }
    if (error is FolhioConfiguracaoException) {
      return _mensagemConfiguracaoAmigavel(error.message);
    }
    if (error is TimeoutException) {
      return 'A conexão demorou demais. Tente novamente em breve.';
    }
    if (error is SocketException) {
      return 'Não foi possível conectar. Verifique sua internet e tente de novo.';
    }
    if (error is HandshakeException) {
      return 'Não foi possível criar uma conexão segura. Tente novamente.';
    }
    if (error is TlsException) {
      return 'Não foi possível criar uma conexão segura. Tente novamente.';
    }
    if (error is HttpException) {
      return 'A conexão falhou. Tente novamente em instantes.';
    }
    if (error is FolhioApiException) {
      return _mensagemPorStatus(error.statusCode, error.message);
    }
    if (error is FormatException) {
      return 'A resposta veio incompleta. Tente novamente.';
    }
    if (error is FileSystemException) {
      return 'Não foi possível acessar esse arquivo. Escolha outro arquivo ou outra pasta.';
    }
    return 'Algo deu errado. Tente novamente.';
  }

  static String _mensagemPorStatus(int statusCode, String rawMessage) {
    if (statusCode == 413) return _mensagemLimiteTamanhoEnvio();
    return ErroHttpHandler.mensagem(statusCode, rawMessage);
  }

  static String _mensagemConfiguracaoAmigavel(String message) {
    final clean = _semTextoTecnico(message);
    if (clean.toLowerCase().contains('api') ||
        clean.toLowerCase().contains('key') ||
        clean.toLowerCase().contains('config')) {
      return 'O app ainda não está pronto para se conectar. Tente novamente mais tarde.';
    }
    return clean.isEmpty ? 'Não foi possível iniciar essa ação.' : clean;
  }

  static String _semTextoTecnico(String message) {
    var clean = message
        .replaceAll(RegExp(r'FolhioApiException\([^)]*\):?'), '')
        .replaceAll(RegExp(r'SocketException:?'), '')
        .replaceAll(RegExp(r'TimeoutException[^:]*:?'), '')
        .replaceAll(RegExp(r'HandshakeException:?'), '')
        .replaceAll(RegExp(r'TlsException:?'), '')
        .replaceAll(RegExp(r'HttpException:?'), '')
        .replaceAll(RegExp(r'\(OS Error:[^)]+\)'), '')
        .replaceAll(RegExp(r'address = [^,]+, port = \d+'), '')
        .replaceAll(RegExp(r'errno = \d+'), '')
        .replaceAll(RegExp(r'uri=[^,\\s]+'), '')
        .replaceAll(RegExp(r'https?://[^\\s]+'), '')
        .trim();
    if (_pareceTecnico(clean)) {
      return '';
    }
    if (clean.length > 120) {
      clean = '${clean.substring(0, 117)}...';
    }
    return clean;
  }

  static bool _pareceTecnico(String message) {
    final lower = message.toLowerCase();
    return lower.contains('exception') ||
        lower.contains('stacktrace') ||
        lower.contains('java.') ||
        lower.contains('dart:') ||
        lower.contains('spring') ||
        lower.contains('sql') ||
        lower.contains('token') ||
        lower.contains('api key') ||
        lower.contains('unauthorized');
  }
}
