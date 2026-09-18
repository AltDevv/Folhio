import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

import '../../config/ambiente_folhio_config.dart';

class ContaGoogleService {
  ContaGoogleService._();

  static final ContaGoogleService instance = ContaGoogleService._();

  static const String _webClientId = AmbienteFolhioConfig.googleWebClientId;

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  Future<void>? _initializeFuture;
  GoogleSignInAccount? _account;

  GoogleSignInAccount? get currentAccount => _account;
  bool get isConfigured => !Platform.isAndroid || _webClientId.isNotEmpty;

  Future<void> inicializar() {
    _initializeFuture ??= _inicializar();
    return _initializeFuture!;
  }

  Future<void> _inicializar() async {
    await _signIn.initialize(
      serverClientId: _webClientId.isEmpty ? null : _webClientId,
    );
    final lightweightAuthentication = _signIn
        .attemptLightweightAuthentication();
    _account = lightweightAuthentication == null
        ? null
        : await lightweightAuthentication;
  }

  Future<GoogleSignInAccount> autenticar() async {
    await inicializar();
    if (!isConfigured) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'GOOGLE_WEB_CLIENT_ID ausente no APK.',
      );
    }
    if (!_signIn.supportsAuthenticate()) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.uiUnavailable,
        description: 'Este aparelho nao abriu o login do Google.',
      );
    }
    _account ??= await _signIn.authenticate();
    return _account!;
  }

  Future<void> encerrarSessao() async {
    await inicializar();
    try {
      await _signIn.disconnect();
    } catch (_) {
      await _signIn.signOut();
    }
    _account = null;
  }
}
