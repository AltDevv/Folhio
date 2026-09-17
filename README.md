# Folhio

Aplicativo para professores prepararem materiais escolares, organizarem sua biblioteca e trabalharem com PDFs, imagens e documentos em um só lugar.

O projeto reúne um app Flutter, uma API Spring Boot e o **Folhio Studio**, interface web administrativa servida pelo próprio backend. Está em desenvolvimento ativo.

## Funcionalidades

- **Materiais:** criação de atividades, provas e outros materiais, com integração de geração de questões por IA conforme a configuração do backend.
- **Biblioteca:** organização local, envio de arquivos ao servidor, visualização, download e compartilhamento dos resultados.
- **PDF e arquivos:** conversão entre formatos suportados, compactação, mesclagem, extração e numeração de páginas, cabeçalhos e organização de várias páginas por folha.
- **Pôster:** divisão de uma página ou imagem em várias folhas A4 para impressão.
- **Assinaturas e carimbos:** aplicação de uma assinatura em PDFs e imagens, incluindo processamento em lote.
- **Sala de aula:** listas de alunos, chamada, planilhas de notas e comunicados.
- **Conta e segurança:** autenticação, renovação de sessão, login Google, recuperação de senha e verificação em duas etapas, conforme as integrações configuradas.
- **Preferências:** aparência, acessibilidade e configurações locais.


## Folhio Studio

Disponível em `/studio`, sem um servidor frontend separado.

| Área | Finalidade |
| --- | --- |
| Dashboard | Processamentos ativos, conclusões e falhas nas últimas 24 horas, tempo médio, arquivos registrados e acontecimentos recentes. |
| Playground | 20 presets de ações aceitas pelo backend e criação de presets personalizados, salvos no navegador. As chamadas executam operações reais. |
| Biblioteca | Consulta administrativa dos arquivos e indicação de arquivos físicos indisponíveis. |
| Logs | Registros do backend e diagnósticos enviados pelo app, filtros e detalhes técnicos. Atualização via WebSocket com alternativa HTTP. |
| Auditoria | Eventos dos processos do backend, com componente, resultado, duração e identificação da requisição. |
| Layouts | Editor manual de páginas A4 com textos, enunciados, imagens, alternativas e áreas de resposta. |

A auditoria exibida no Studio é do sistema, não um histórico de atividades por usuário. Ela consulta eventos do backend com retenção de 10 dias. O volume de arquivos do Dashboard é calculado pelos metadados registrados, inclusive quando um arquivo físico está ausente.

Os layouts podem ser posicionados, redimensionados, duplicados, salvos e recuperados. **O preenchimento desses layouts pela IA e sua renderização final pelo gerador ainda não estão integrados.** A prévia usa dados demonstrativos.

## Arquitetura

A organização segue camadas centrais inspiradas no projeto libTeca. As pastas principais usam nomes em inglês; classes de domínio e métodos próprios usam português, mantendo sufixos técnicos como `Controller`, `Service`, `Repository` e `ViewModel`.

```text
Folhio/
├── front/
│   ├── lib/
│   │   ├── app/          composição do aplicativo
│   │   ├── config/       rotas e configuração de ambiente
│   │   ├── controller/   estado de apresentação e comandos
│   │   ├── screen/       telas
│   │   ├── widget/       componentes visuais
│   │   ├── style/        estilos e temas compartilhados
│   │   ├── service/      comunicação HTTP e WebSocket
│   │   ├── repository/   acesso aos dados
│   │   ├── database/     persistência local
│   │   ├── security/     sessão, criptografia e segurança
│   │   └── dto/, model/, mapper/, handler/
│   └── folhio.ps1        execução e build com a configuração local
├── backEnd/
│   ├── src/main/java/com/folhio/api/
│   │   ├── controller/, service/, repository/, entity/, dto/
│   │   ├── config/, security/, handler/, mapper/, enums/
│   │   └── processing/, files/, progress/, logs/, audit/, common/
│   ├── src/main/resources/
│   │   ├── application.properties
│   │   └── static/studio/
│   ├── material-generator/   modelos e base de geração
│   └── document-processing/  recursos auxiliares de processamento
└── compose.dev.yml           PostgreSQL de desenvolvimento
```

O app envia e recebe arquivos por HTTP. O progresso das operações usa `/ws/progress/{requestId}`; os logs em tempo real usam `/ws/logs`. O PostgreSQL guarda dados e metadados; o conteúdo dos arquivos fica no armazenamento configurado no backend.

### Tecnologias

- Flutter e Dart, Drift/SQLite e armazenamento seguro de sessão.
- Java 21, Spring Boot 4.0.6, JPA/Hibernate e PostgreSQL.
- Apache PDFBox e Apache POI para documentos.
- HTML, CSS e JavaScript no Studio.
- Integrações opcionais com Ollama, LibreOffice, ClamAV e modelos ONNX, conforme a operação.

## Desenvolvimento local

As instruções abaixo são destinadas à manutenção e aos testes do projeto. Não representam concessão de licença de uso.

### Pré-requisitos

- JDK 21 e `JAVA_HOME` configurado.
- Flutter com Dart compatível com `^3.12.0`, conforme `front/pubspec.yaml`.
- Android SDK e um dispositivo ou emulador para executar o app.
- PostgreSQL; Docker é opcional para usar o banco de desenvolvimento.
- Maven Wrapper incluído em `backEnd`.

### 1. Banco de dados

Na raiz do repositório, caso não exista um PostgreSQL local configurado:

```powershell
docker compose -f compose.dev.yml up -d postgres
```

Esse serviço usa banco `folio`, usuário `postgres` e senha `postgres`, na porta `5432`. São valores de desenvolvimento.

### 2. Configuração do backend

Crie `backEnd/.env` localmente. Substitua os marcadores por valores próprios:

```dotenv
POSTGRES_URL=jdbc:postgresql://localhost:5432/folio
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

FOLHIO_APP_API_KEY=SUBSTITUA_POR_UMA_CHAVE_ALEATORIA
FOLHIO_AUTH_ACCESS_TOKEN_SECRET=SUBSTITUA_POR_UM_SEGREDO_COM_PELO_MENOS_32_CARACTERES
FOLHIO_AUTH_PASSWORD_PEPPER=SUBSTITUA_POR_UM_SEGREDO_COM_PELO_MENOS_24_CARACTERES

FOLHIO_API_BASE_URL=http://10.0.2.2:8080
FOLHIO_WEBSOCKET_ALLOWED_ORIGINS=http://localhost:*,http://127.0.0.1:*

FOLHIO_DROP_LEGACY_TABLES=false
FOLHIO_FILE_SCANNER_ENABLED=false
FOLHIO_BACKGROUND_REMOVAL_ENABLED=false
FOLHIO_MATERIAL_AI_ENABLED=false
```

O exemplo desativa integrações externas para o desenvolvimento inicial. Operações que dependem delas precisam de configuração adicional:

| Recurso | Configuração |
| --- | --- |
| Login Google | `FOLHIO_GOOGLE_CLIENT_ID`; o launcher repassa o identificador ao app. |
| Recuperação de senha e códigos por e-mail | `FOLHIO_MAIL_ENABLED=true`, remetente e variáveis `FOLHIO_SMTP_*`. |
| Geração com Ollama | `FOLHIO_MATERIAL_AI_ENABLED=true`, `FOLHIO_OLLAMA_URL` e `FOLHIO_OLLAMA_MODEL`. |
| Conversões que usam LibreOffice | `FOLHIO_SOFFICE_PATH`, quando necessário. |
| Remoção de fundo | `FOLHIO_BACKGROUND_REMOVAL_ENABLED=true` e modelo em `FOLHIO_BACKGROUND_REMOVAL_MODEL`. |
| Verificação antivírus | `FOLHIO_FILE_SCANNER_ENABLED=true` e configuração `FOLHIO_CLAMAV_*`. |

As opções completas estão em [application.properties](backEnd/src/main/resources/application.properties). Modelos pesados, credenciais e dados privados não fazem parte da configuração demonstrativa.

### 3. Iniciar o backend

A partir da raiz:

```powershell
cd backEnd
.\mvnw.cmd spring-boot:run
```

A API usa a porta `8080` por padrão. Verifique a disponibilidade em outro terminal:

```powershell
Invoke-RestMethod http://localhost:8080/api/folhio/health
```

O Spring carrega o `.env` na inicialização. Reinicie o backend após alterar as variáveis. No IntelliJ, use `backEnd` como diretório de trabalho; isso também mantém corretos os caminhos relativos dos recursos de processamento.

### 4. Abrir o Studio

Acesse [http://localhost:8080/studio](http://localhost:8080/studio). Em **Conexão com o servidor**:

- API base: `http://localhost:8080`, sem `/studio`.
- X-API-Key: valor de `FOLHIO_APP_API_KEY` do `backEnd/.env`.
- Client ID: opcional para consultas administrativas; necessário para simular ações do app no Playground.

Clique em **Salvar e testar**. Na configuração atual, app e Studio compartilham a chave; quem a possui também tem acesso administrativo.

Para acessar por ngrok, inicie o Spring antes do túnel e use `https://SEU-DOMINIO/studio`. Adicione a origem `https://SEU-DOMINIO`, sem caminho, à lista `FOLHIO_WEBSOCKET_ALLOWED_ORIGINS`, separando as entradas por vírgula.

### 5. Executar o app e gerar APK

A partir da raiz:

```powershell
cd front
flutter pub get
.\folhio.ps1 run
```

Para gerar o APK, dentro de `front`:

```powershell
.\folhio.ps1 build-apk
```

Saída padrão: `front/build/app/outputs/flutter-apk/app-release.apk`.

O script lê a configuração selecionada de `backEnd/.env` e a incorpora ao build. Defina `FOLHIO_API_BASE_URL` explicitamente: `10.0.2.2` aponta para o computador no Android Emulator; em um celular físico, use um endereço alcançável pelo aparelho, como o domínio HTTPS do túnel.

Alterar a URL ou a chave no `.env` exige executar ou compilar o app novamente. A assinatura Android de release ainda utiliza a configuração de debug e precisa ser substituída antes de distribuição em loja.

## Verificação

Backend, dentro de `backEnd`:

```powershell
.\mvnw.cmd test
```

App, dentro de `front`:

```powershell
flutter analyze
flutter test
```

Os testes automatizados não substituem a validação em aparelho real das permissões, login Google, entrega de e-mails e operações com arquivos grandes.

## Estado atual e limites

- O editor de layouts está disponível; sua integração ao preenchimento por IA é uma etapa futura.
- O Playground executa ações reais e exige arquivos de entrada válidos para as operações correspondentes.
- A configuração padrão do banco usa atualização de schema em desenvolvimento; a implantação precisa de uma estratégia de migrações.
- A chave compartilhada entre app e Studio é uma configuração de desenvolvimento. A publicação do serviço precisa de controle administrativo separado.

## Documentação

- [Arquitetura do backend](backEnd/ARCHITECTURE.md)
- [Arquitetura do Flutter](front/ARCHITECTURE.md)
- [Folhio Studio](backEnd/STUDIO.md)
- [Acesso ao Studio](backEnd/src/main/resources/ACESSO_FOLHIO_STUDIO.txt)
- [Geração de materiais](backEnd/material-generator/README.md)
- [Exceções e handlers](backEnd/src/main/java/com/folhio/api/handler/README.md)

## Autoria e direitos

Desenvolvido por **Vítor Nathan**.

Copyright © 2026 Vítor Nathan. Todos os direitos reservados.

O código de autoria do projeto Folhio é disponibilizado publicamente para consulta. Não é concedida licença de uso, modificação ou redistribuição, ressalvadas as permissões previstas nos termos do GitHub e na legislação aplicável.

Bibliotecas, ferramentas e outros componentes de terceiros mantêm suas respectivas licenças.