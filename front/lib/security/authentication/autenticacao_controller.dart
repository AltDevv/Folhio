import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../repository/local/persistencia_local_repository.dart';
import '../../config/cabecalhos_api_folhio.dart';
import '../../config/rotas_api_folhio.dart';
import '../../config/ambiente_folhio_config.dart';
import 'conta_google_service.dart';
import '../../handler/erro_http_handler.dart';
import '../../service/observabilidade_service.dart';

part 'account_api_client.dart';
part 'auth_api_client.dart';
part 'auth_header_provider.dart';
part 'auth_models.dart';
part 'auth_session_service.dart';
part 'auth_session_store.dart';
part 'two_factor_api_client.dart';

class AutenticacaoController extends ChangeNotifier {
  AutenticacaoController._();

  static final AutenticacaoController instance = AutenticacaoController._();

  static const _apiKeyHeader = CabecalhosApiFolhio.apiKey;
  static const _clientIdHeader = CabecalhosApiFolhio.clientId;
  static const _authHeader = 'Authorization';
  static const _requestIdHeader = CabecalhosApiFolhio.requestId;
  static const _appVersionHeader = CabecalhosApiFolhio.appVersion;
  static const _deviceHeader = CabecalhosApiFolhio.device;
  static const _clientIdSettingKey = 'security.clientId';
  static const _apiKey = AmbienteFolhioConfig.appApiKey;
  static const _appVersion = AmbienteFolhioConfig.appVersion;
  static const _baseUrl = AmbienteFolhioConfig.apiBaseUrl;

  static final ContaGoogleService _google = ContaGoogleService.instance;

  final _sessionStore = const _FolhioSessaoAutenticacaoStore(FlutterSecureStorage());
  late final _headers = _FolhioCabecalhosAutenticacaoProvider(
    PersistenciaLocalRepository.instance,
  );
  late final _authApi = _FolhioAutenticacaoApiClient(
    _baseUrl,
    _headers,
    _cabecalhosRequisicao,
  );
  late final _accountApi = _FolhioContaApiClient(_authApi);
  late final _twoFactorApi = _FolhioDoisFatoresApiClient(_authApi);
  late final _sessionService = _FolhioSessaoAutenticacaoService(_sessionStore);

  FolhioUsuario? _user;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessTokenExpiresAt;
  bool _ready = false;
  Future<void>? _refreshFuture;

  FolhioUsuario? get user => _user;
  bool get isSignedIn => _user != null && _accessToken != null;
  bool get ready => _ready;
  String? get accessToken => _accessToken;

  Future<bool> restaurarSessao() async {
    await restaurarSessaoArmazenada();
    if (_refreshToken != null) {
      try {
        await renovar();
      } catch (_) {
        // Mantem a sessão local. O app tenta renovar novamente quando a rede voltar.
      }
    }
    _ready = true;
    notifyListeners();
    return isSignedIn;
  }

  Future<bool> restaurarSessaoArmazenada() async {
    _aplicarSessao(await _sessionStore.ler());
    _ready = true;
    notifyListeners();
    return isSignedIn;
  }

  Future<void> cadastrar({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _authApi.cadastrar(
      name: name,
      email: email,
      password: password,
    );
    await _salvarRespostaAutenticacao(data);
  }

  Future<ResultadoAutenticacaoFolhio> entrar({
    required String email,
    required String password,
  }) async {
    final data = await _authApi.entrar(email: email, password: password);
    return _tratarRespostaAutenticacao(data);
  }

  Future<ResultadoAutenticacaoFolhio> entrarComGoogle() async {
    if (!_google.isConfigured) {
      throw const FolhioAutenticacaoException(
        'Login com Google ainda não foi configurado neste app.',
      );
    }
    try {
      final account = await _google.autenticar();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const FolhioAutenticacaoException(
          'O Google não retornou um token de login.',
        );
      }
      final data = await _authApi.entrarComTokenGoogle(idToken);
      return _tratarRespostaAutenticacao(data);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const FolhioAutenticacaoException('Login com Google cancelado.');
      }
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw const FolhioAutenticacaoException(
          'A configuração do Google deste APK não corresponde ao servidor. Gere o app novamente.',
        );
      }
      throw const FolhioAutenticacaoException(
        'Este aparelho não abriu o login do Google.',
      );
    }
  }

  Future<ResultadoAutenticacaoFolhio> verificarDoisFatores({
    required String token,
    required String code,
  }) async {
    final data = await _twoFactorApi.verificar(token: token, code: code);
    return _tratarRespostaAutenticacao(data);
  }

  Future<void> atualizarNomeExibicao(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      throw const FolhioAutenticacaoException('Informe como devemos te chamar.');
    }
    await _atualizarUsuario(await _accountApi.atualizarNomeExibicao(clean));
  }

  Future<void> renovar() async {
    final token = _refreshToken;
    if (token == null || token.isEmpty) {
      throw const FolhioAutenticacaoException('Sessão expirada.');
    }
    await _salvarRespostaAutenticacao(await _authApi.renovar(token));
  }

  Future<void> esqueciSenha(String email) {
    return _accountApi.esqueciSenha(email);
  }

  Future<void> redefinirSenha({
    required String token,
    required String newPassword,
  }) {
    return _accountApi.redefinirSenha(token: token, newPassword: newPassword);
  }

  Future<FolhioConfiguracoesDoisFatores> configuracoesDoisFatores() {
    return _twoFactorApi.configuracoes();
  }

  Future<FolhioConfiguracoesDoisFatores> atualizarConfiguracoesDoisFatores({
    required bool enabled,
    String? currentPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  }) async {
    final settings = await _twoFactorApi.atualizar(
      enabled: enabled,
      currentPassword: currentPassword,
      twoFactorToken: twoFactorToken,
      twoFactorCode: twoFactorCode,
    );
    final current = _user;
    if (current != null && !settings.twoFactorRequired) {
      await _atualizarUsuario(
        current.copiarCom(
          twoFactorEnabled: settings.enabled,
          twoFactorMethod: settings.method,
        ),
      );
    }
    return settings;
  }

  Future<FolhioResultadoAtualizacaoConta> atualizarConta({
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  }) async {
    final result = await _accountApi.atualizarConta(
      name: name,
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
      twoFactorToken: twoFactorToken,
      twoFactorCode: twoFactorCode,
    );
    if (result.user != null) {
      await _atualizarUsuario(result.user!);
    }
    return result;
  }

  Future<FolhioResultadoAtualizacaoConta> excluirConta({
    String? currentPassword,
    String? twoFactorToken,
    String? twoFactorCode,
  }) {
    return _accountApi.excluirConta(
      currentPassword: currentPassword,
      twoFactorToken: twoFactorToken,
      twoFactorCode: twoFactorCode,
    );
  }

  Future<void> encerrarSessao({bool localOnly = false}) async {
    final refresh = _refreshToken;
    _aplicarSessao(
      const _FolhioSessaoAutenticacaoSnapshot(
        user: null,
        accessToken: null,
        refreshToken: null,
        accessTokenExpiresAt: null,
      ),
    );
    await _sessionService.limparSessaoLocal();
    if (!localOnly && refresh != null && refresh.isNotEmpty) {
      unawaited(_authApi.sair(refresh).catchError((_) {}));
    }
    notifyListeners();
  }

  Future<Map<String, String>> cabecalhosAutenticacao() async {
    await _renovarTokenAcessoSeNecessario();
    return _headers.cabecalhos(includeAuth: true, accessToken: _accessToken);
  }

  Future<Map<String, String>> _cabecalhosRequisicao(String path) {
    if (path == RotasApiFolhio.refresh) {
      return _headers.cabecalhos(includeAuth: false);
    }
    return cabecalhosAutenticacao();
  }

  Future<void> _salvarRespostaAutenticacao(Map<String, dynamic> data) async {
    _aplicarSessao(await _sessionService.salvarRespostaAutenticacao(data));
    notifyListeners();
  }

  Future<void> _atualizarUsuario(FolhioUsuario user) async {
    _user = user;
    await _sessionService.atualizarPerfilUsuario(user);
    notifyListeners();
  }

  Future<void> _renovarTokenAcessoSeNecessario() async {
    final runningRefresh = _refreshFuture;
    if (runningRefresh != null) {
      await runningRefresh;
      return;
    }
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      return;
    }
    final expiresAt = _accessTokenExpiresAt;
    if (_accessToken != null &&
        expiresAt != null &&
        expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return;
    }
    final refreshOperation = renovar();
    _refreshFuture = refreshOperation;
    try {
      await refreshOperation;
    } catch (_) {
      // Nao desloga sozinho: uma falha temporaria no servidor/rede nao deve
      // apagar a conta salva no aparelho.
      rethrow;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<ResultadoAutenticacaoFolhio> _tratarRespostaAutenticacao(
    Map<String, dynamic> data,
  ) async {
    if (data['twoFactorRequired'] == true) {
      final token = data['twoFactorToken'] as String?;
      if (token == null || token.isEmpty) {
        throw const FolhioAutenticacaoException('Resposta de segurança incompleta.');
      }
      return ResultadoAutenticacaoFolhio.doisFatores(
        token: token,
        method: data['twoFactorMethod'] as String? ?? 'email',
        destination: data['twoFactorDestination'] as String?,
      );
    }
    await _salvarRespostaAutenticacao(data);
    return ResultadoAutenticacaoFolhio.estaAutenticado(
      needsNameConfirmation: data['needsNameConfirmation'] == true,
    );
  }

  void _aplicarSessao(_FolhioSessaoAutenticacaoSnapshot session) {
    _user = session.user;
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _accessTokenExpiresAt = session.accessTokenExpiresAt;
  }
}
