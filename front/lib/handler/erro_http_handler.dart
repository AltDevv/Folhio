import 'dart:convert';

class ErroHttpHandler {
  static String mensagem(int status, String corpo) {
    final dados = decodificar(corpo);
    final codigo = dados['code'];
    if (codigo == 'CHAVE_API_INVALIDA') {
      return 'O app não conseguiu se identificar no servidor. Verifique a configuração ou atualize o app.';
    }
    final texto = dados['message'];
    if (texto is String &&
        texto.trim().isNotEmpty &&
        (status < 500 || codigo is String) &&
        !RegExp(
          r'<[^>]+>|java\.|Exception|stacktrace',
          caseSensitive: false,
        ).hasMatch(texto)) {
      final campos = dados['fields'];
      if (codigo == 'DADOS_INVALIDOS' && campos is Map && campos.isNotEmpty) {
        final primeira = campos.values.first;
        if (primeira is String && primeira.isNotEmpty) return primeira;
      }
      return texto.trim();
    }
    return switch (status) {
      400 => 'Confira os dados informados e tente novamente.',
      401 => 'Sua autenticação não é válida. Entre novamente.',
      403 => 'Você não tem permissão para realizar essa ação.',
      404 => 'Não encontramos o item solicitado.',
      408 ||
      504 => 'O servidor demorou demais para responder. Tente novamente.',
      409 => 'Os dados entram em conflito com um registro existente.',
      413 => 'O arquivo excede o limite permitido de envio.',
      415 => 'Esse formato de arquivo não é aceito.',
      422 => 'Não foi possível usar esses dados ou processar esse arquivo.',
      429 => 'Muitas tentativas. Aguarde um pouco e tente novamente.',
      502 || 503 =>
        'O serviço está temporariamente indisponível. Tente novamente em instantes.',
      >= 500 => 'O servidor encontrou uma falha. Tente novamente mais tarde.',
      _ => 'Não foi possível concluir a operação.',
    };
  }

  static Map<String, dynamic> decodificar(String corpo) {
    try {
      final valor = jsonDecode(corpo);
      return valor is Map<String, dynamic> ? valor : {};
    } on FormatException {
      return {};
    }
  }
}
