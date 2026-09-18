import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../database/folhio_database.dart';
import '../../repository/local/persistencia_local_repository.dart';
import '../../security/authentication/autenticacao_controller.dart';
import '../../security/files/envio_policy.dart';
import '../../config/ambiente_folhio_config.dart';
import '../../config/cabecalhos_api_folhio.dart';
import '../../config/rotas_api_folhio.dart';
import '../../dto/folhio_action.dart';
import '../../handler/erro_http_handler.dart';

part 'clients/actions/action_api_client.dart';
part 'clients/base/http_api_client.dart';
part 'clients/files/file_api_client.dart';
part 'clients/files/helpers/download_helpers.dart';
part 'clients/files/helpers/generated_file_io.dart';
part '../../security/files/upload_safety_validator.dart';
part '../../repository/library/library_local_client.dart';
part '../../mapper/library_local_mapper.dart';
part 'clients/logs/log_api_client.dart';
part 'clients/materials/materials_api_client.dart';
part 'clients/progress/progress_api_client.dart';
part 'clients/progress/realtime_progress_client.dart';
part '../../dto/file_contracts.dart';
part '../../dto/log_contracts.dart';
part '../../dto/material_contracts.dart';
part '../../dto/progress_contracts.dart';
part '../../handler/api_exceptions.dart';
part '../../handler/error_messages.dart';

class FolhioApiGateway {
  static const apiKeyHeader = CabecalhosApiFolhio.apiKey;
  static const clientIdHeader = CabecalhosApiFolhio.clientId;
  static const requestIdHeader = CabecalhosApiFolhio.requestId;
  static const appVersionHeader = CabecalhosApiFolhio.appVersion;
  static const deviceHeader = CabecalhosApiFolhio.device;
  static const proxyBypassHeaderName = AmbienteFolhioConfig.apiProxyBypassHeader;
  static const proxyBypassHeaderValue = AmbienteFolhioConfig.apiProxyBypassValue;
  static const clientIdSettingKey = 'security.clientId';
  static const favoriteFileIdsSettingKey = 'library.favoriteFileIds';
  static const maxUploadBytes = EnvioPolicy.maxBytes;
  static const maxUploadMegabytes = EnvioPolicy.maxMegabytes;
  static const apiKey = AmbienteFolhioConfig.appApiKey;
  static const appVersion = AmbienteFolhioConfig.appVersion;
  static Map<String, String> get apiHeaders {
    final accessToken = AutenticacaoController.instance.accessToken;
    return {
      apiKeyHeader: apiKey,
      appVersionHeader: appDeviceVersion,
      deviceHeader: appDeviceName,
      if (proxyBypassHeaderName.isNotEmpty)
        proxyBypassHeaderName: proxyBypassHeaderValue,
      HttpHeaders.userAgentHeader: appUserAgent,
      if (accessToken != null)
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    };
  }

  static const defaultBaseUrl = AmbienteFolhioConfig.apiBaseUrl;

  static final ValueNotifier<FolhioProgressoOperacao?> progress =
      ValueNotifier<FolhioProgressoOperacao?>(null);
  static final ValueNotifier<FolhioArquivoGerado?> generatedFile =
      ValueNotifier<FolhioArquivoGerado?>(null);

  final String baseUrl;
  final Uri endpoint;
  final Duration timeout;
  final HttpClient _httpClient;
  final Future<Map<String, String>> Function() _resolveHeaders;
  late final _FolhioHttpApiClient _http;
  late final _FolhioAcaoApiClient _actions;
  late final _FolhioArquivoApiClient _files;
  late final _FolhioBibliotecaLocalClient _library;
  late final _FolhioLogApiClient _logs;
  late final _FolhioMateriaisApiClient _materials;

  FolhioApiGateway({
    this.baseUrl = defaultBaseUrl,
    this.timeout = const Duration(minutes: 5),
    HttpClient? httpClient,
    Future<Map<String, String>> Function()? resolveHeaders,
  }) : endpoint = Uri.parse('$baseUrl${RotasApiFolhio.actions}'),
       _httpClient = httpClient ?? HttpClient(),
       _resolveHeaders =
           resolveHeaders ?? AutenticacaoController.instance.cabecalhosAutenticacao {
    _httpClient.connectionTimeout = const Duration(seconds: 12);
    _http = _FolhioHttpApiClient(this);
    _actions = _FolhioAcaoApiClient(this);
    _files = _FolhioArquivoApiClient(this);
    _library = _FolhioBibliotecaLocalClient(this);
    _logs = _FolhioLogApiClient(this);
    _materials = _FolhioMateriaisApiClient(this);
  }

  Future<FolhioAcaoResponse> enviar(FolhioAcaoRequest action) {
    return _actions.enviar(action);
  }

  // ignore: unused_element
  Future<FolhioArquivoEnviado> enviarArquivo(
    File file, {
    String? fileName,
    bool keepProgress = false,
    bool persistent = false,
    bool showProgressError = true,
  }) {
    return _files.enviarArquivo(
      file,
      fileName: fileName,
      keepProgress: keepProgress,
      persistent: persistent,
      showProgressError: showProgressError,
    );
  }

  // ignore: unused_element
  Future<FolhioArquivoEnviado> enviarBytes(
    List<int> bytes, {
    required String fileName,
    bool keepProgress = false,
    bool persistent = false,
    bool showProgressError = true,
  }) {
    return _files.enviarBytes(
      bytes,
      fileName: fileName,
      keepProgress: keepProgress,
      persistent: persistent,
      showProgressError: showProgressError,
    );
  }

  // ignore: unused_element
  Future<void> registrarEventoCliente(FolhioEventoRegistroClienteRequest request) {
    return _logs.registrarEventoCliente(request);
  }

  Future<FolhioCatalogoMateriais> catalogoMateriais({String discipline = ''}) {
    return _materials.catalogo(discipline: discipline);
  }

  Future<List<FolhioModeloMaterial>> modelosMateriais({
    String materialType = '',
  }) {
    return _materials.modelos(materialType: materialType);
  }

  Future<FolhioMaterialGerado> montarMaterial(
    FolhioGeracaoMaterialRequest request,
  ) {
    return _materials.montar(request);
  }

  Future<List<FolhioResumoMaterialGerado>> materiaisGerados({
    int limit = 50,
  }) {
    return _materials.gerados(limit: limit);
  }

  // ignore: unused_element
  Future<File> baixarArquivo({
    required String fileId,
    required String savePath,
  }) {
    return _files.baixarArquivo(fileId: fileId, savePath: savePath);
  }

  String urlPreviaPdf(String fileId, {int page = 1}) {
    return _files.urlPreviaPdf(fileId, page: page);
  }

  Future<FolhioArquivoGerado?> prepararArquivoSaida(
    FolhioArquivoSaida? outputFile,
  ) async {
    if (outputFile == null) {
      return null;
    }

    final fileName = outputFile.fileName.trim().isEmpty
        ? 'folhio-resultado'
        : outputFile.fileName;
    progress.value = const FolhioProgressoOperacao(
      progress: 0.88,
      message: 'Preparando arquivo',
    );
    final localPath = await _baixarArquivoSaida(outputFile, fileName: fileName);
    final readyFile = FolhioArquivoGerado(
      fileName: fileName,
      mimeType: outputFile.mimeType,
      bytes: Uint8List(0),
      storageKey: outputFile.storageKey,
      downloadUrl: outputFile.downloadUrl,
      localPath: localPath,
    );
    generatedFile.value = readyFile;
    progress.value = const FolhioProgressoOperacao(
      progress: 1,
      message: 'Arquivo pronto',
    );
    return readyFile;
  }

  Future<FolhioArquivoGerado> carregarBytesArquivoGerado(
    FolhioArquivoGerado file,
  ) async {
    if (file.bytes.isNotEmpty) {
      return file;
    }

    final localPath = file.localPath;
    if (localPath != null && localPath.isNotEmpty) {
      final localFile = File(localPath);
      if (await localFile.exists()) {
        final bytes = await localFile.readAsBytes();
        final readyFile = FolhioArquivoGerado(
          fileName: file.fileName,
          mimeType: file.mimeType,
          bytes: bytes,
          storageKey: file.storageKey,
          downloadUrl: file.downloadUrl,
          localPath: localPath,
        );
        generatedFile.value = readyFile;
        return readyFile;
      }
    }

    progress.value = const FolhioProgressoOperacao(
      progress: 0.72,
      message: 'Baixando arquivo',
    );

    final bytes = await _baixarBytesSaida(
      FolhioArquivoSaida(
        fileName: file.fileName,
        mimeType: file.mimeType,
        storageKey: file.storageKey,
        downloadUrl: file.downloadUrl,
      ),
    );
    final cachedLocalPath = await _FolhioArquivoGeradoIo.armazenarArquivoGerado(
      fileName: file.fileName,
      bytes: bytes,
    );

    final readyFile = FolhioArquivoGerado(
      fileName: file.fileName,
      mimeType: file.mimeType,
      bytes: bytes,
      storageKey: file.storageKey,
      downloadUrl: file.downloadUrl,
      localPath: cachedLocalPath,
    );
    generatedFile.value = readyFile;
    progress.value = const FolhioProgressoOperacao(
      progress: 1,
      message: 'Arquivo pronto',
    );
    return readyFile;
  }

  // ignore: unused_element
  Future<List<FolhioArquivoBiblioteca>> listarArquivosBiblioteca({
    String search = '',
    String folder = '',
    String? folderId,
    int limit = 20,
  }) {
    return _library.listarArquivosBiblioteca(
      search: search,
      folder: folder,
      folderId: folderId,
      limit: limit,
    );
  }

  Future<List<FolhioPastaBiblioteca>> listarPastasBiblioteca({
    String? parentId,
    int limit = 80,
  }) {
    return _library.listarPastasBiblioteca(parentId: parentId, limit: limit);
  }

  Future<FolhioPastaBiblioteca> criarPastaBiblioteca({
    required String name,
    String? parentId,
    String tags = '',
    String notes = '',
    String links = '',
  }) {
    return _library.criarPastaBiblioteca(
      name: name,
      parentId: parentId,
      tags: tags,
      notes: notes,
      links: links,
    );
  }

  Future<FolhioPastaBiblioteca> atualizarPastaBiblioteca(
    String folderId, {
    required String name,
    String tags = '',
    String notes = '',
    String links = '',
  }) {
    return _library.atualizarPastaBiblioteca(
      folderId,
      name: name,
      tags: tags,
      notes: notes,
      links: links,
    );
  }

  Future<void> excluirPastaBiblioteca(String folderId) {
    return _library.excluirPastaBiblioteca(folderId);
  }

  Future<FolhioArquivoBiblioteca> moverArquivoBiblioteca(
    String fileId, {
    String? folderId,
    String folder = 'Arquivos',
  }) {
    return _library.moverArquivoBiblioteca(fileId, folderId: folderId, folder: folder);
  }

  Future<FolhioArquivoBiblioteca> renomearArquivoBiblioteca(
    String fileId, {
    required String fileName,
  }) {
    return _library.renomearArquivoBiblioteca(fileId, fileName: fileName);
  }

  Future<void> excluirArquivoBiblioteca(String fileId) {
    return _library.excluirArquivoBiblioteca(fileId);
  }

  Future<Set<String>> identificadoresFavoritosBiblioteca() {
    return _library.identificadoresFavoritosBiblioteca();
  }

  Future<bool> definirFavoritoArquivoBiblioteca(String fileId, bool favorite) {
    return _library.definirFavoritoArquivoBiblioteca(fileId, favorite);
  }

  Future<bool> alternarFavoritoArquivoBiblioteca(String fileId) {
    return _library.alternarFavoritoArquivoBiblioteca(fileId);
  }

  Future<FolhioArquivoBiblioteca> salvarArquivoGeradoNaBiblioteca(
    FolhioArquivoGerado generatedFile, {
    String folder = 'ConversÃµes',
    String? folderId,
    String conflictStrategy = 'reject',
  }) async {
    final readyFile = await carregarBytesArquivoGerado(generatedFile);
    return _library.salvarArquivoGeradoNaBiblioteca(
      readyFile,
      folder: folder,
      folderId: folderId,
      conflictStrategy: conflictStrategy,
    );
  }

  Future<FolhioArquivoBiblioteca> salvarArquivoLocalNaBiblioteca(
    File sourceFile, {
    String? fileName,
    String folder = 'Importados',
    String? folderId,
  }) {
    return _library.salvarArquivoLocalNaBiblioteca(
      sourceFile,
      fileName: fileName,
      folder: folder,
      folderId: folderId,
    );
  }

  Future<FolhioArquivoGerado> baixarArquivoBiblioteca(
    FolhioArquivoBiblioteca file, {
    bool showReadyOverlay = true,
  }) {
    return _library.baixarArquivoBiblioteca(
      file,
      showReadyOverlay: showReadyOverlay,
    );
  }

  Future<List<FolhioArquivoBiblioteca>> listarArquivosLocaisRecentes({int limit = 4}) {
    return _library.listarArquivosLocaisRecentes(limit: limit);
  }

  static Future<String?> escolherOndeSalvar(FolhioArquivoGerado file) {
    return _FolhioArquivoGeradoIo.escolherOndeSalvar(file);
  }

  static Future<String> salvarEmDownloads(FolhioArquivoGerado file) {
    return _FolhioArquivoGeradoIo.salvarEmDownloads(file);
  }

  static Future<void> compartilharArquivoGerado(FolhioArquivoGerado file) {
    return _FolhioArquivoGeradoIo.compartilharArquivoGerado(file);
  }

  static void limparArquivoGerado() {
    _FolhioArquivoGeradoIo.limparArquivoGerado();
  }

  void fechar() {
    _http.fechar();
  }

  Future<void> _garantirConexaoInternet() {
    return _http.garantirConexaoInternet();
  }

  Future<void> _adicionarCabecalhosAutenticacao(HttpClientRequest request) {
    return _http.adicionarCabecalhosPadrao(request);
  }

  Future<String> _identificadorClienteLocal() async {
    final repository = PersistenciaLocalRepository.instance;
    final existing = await repository.configuracao(clientIdSettingKey);
    final safeClientId = RegExp(r'^[A-Za-z0-9._:-]{12,120}$');
    if (existing != null && safeClientId.hasMatch(existing)) {
      return existing;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    final clientId = 'client-${base64UrlEncode(bytes).replaceAll('=', '')}';
    await repository.definirConfiguracao(clientIdSettingKey, clientId);
    return clientId;
  }

  static String get appDeviceVersion => appVersion;

  static String get appUserAgent => 'Folhio/$appVersion ($appDeviceName)';

  static String get appDeviceName {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  static String humanizarErro(Object error) {
    return _FolhioMensagensErro.humanizarErro(error);
  }
}
