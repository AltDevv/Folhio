import 'package:flutter_test/flutter_test.dart';
import 'package:folhio/handler/erro_http_handler.dart';

void main() {
  test('preserva mensagem especifica mesmo com success false', () {
    expect(
      ErroHttpHandler.mensagem(
        404,
        '{"success":false,"code":"ARQUIVO_NAO_ENCONTRADO","message":"Arquivo removido."}',
      ),
      'Arquivo removido.',
    );
  });
  test('502 HTML e indisponibilidade, nao falta de internet', () {
    final mensagem = ErroHttpHandler.mensagem(502, '<html>Bad Gateway</html>');
    expect(mensagem, contains('indisponível'));
    expect(mensagem, isNot(contains('<html>')));
    expect(mensagem, isNot(contains('internet')));
  });
  test('diferencia chave do app de sessao expirada', () {
    expect(
      ErroHttpHandler.mensagem(401, '{"code":"CHAVE_API_INVALIDA"}'),
      contains('configuração'),
    );
    expect(
      ErroHttpHandler.mensagem(
        401,
        '{"code":"SESSAO_EXPIRADA","message":"Entre novamente."}',
      ),
      'Entre novamente.',
    );
  });
  test('mostra campo invalido e protege contra resposta tecnica', () {
    expect(
      ErroHttpHandler.mensagem(
        400,
        '{"code":"DADOS_INVALIDOS","message":"Revise.","fields":{"email":"Email inválido."}}',
      ),
      'Email inválido.',
    );
    expect(
      ErroHttpHandler.mensagem(
        500,
        '{"message":"java.lang.NullPointerException"}',
      ),
      isNot(contains('java.')),
    );
  });
}
