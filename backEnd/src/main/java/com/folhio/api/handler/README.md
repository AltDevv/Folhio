# Tratamento de erros

Organizacao inspirada no libTeca: cada dominio possui pastas exception e handler,
com classes de dominio em portugues e sufixos tecnicos em ingles.

- Exceptions de negocio indicam a causa; o handler correspondente define status e codigo.
- RespostaErro padroniza success, status, code, message, requestId, timestamp e fields.
- ExcecaoApiHandler trata validacao, infraestrutura e falhas inesperadas como ultimo recurso.
- Os filtros de seguranca usam o mesmo contrato, pois executam antes do MVC.
- O router de processamento propaga as exceptions e encerra o progresso em caso de falha.
- Erros inesperados nunca devem devolver detalhes internos ao cliente.

Use code para distinguir causas com o mesmo status HTTP. Por exemplo,
CHAVE_API_INVALIDA e SESSAO_EXPIRADA sao respostas 401 com acoes diferentes.
Nao escolha status procurando palavras na mensagem da exception.

Erros gerados pelo proxy (como 502) podem chegar sem JSON. O Flutter trata esse
caso como indisponibilidade do servico. Nenhum handler da aplicacao consegue
interceptar uma requisicao que nao chegou ao backend.

O identificador da resposta e enviado no cabecalho X-Request-Id e usado no
registro HTTP de erros. Nao incluir senhas, chaves ou tokens nas mensagens.
