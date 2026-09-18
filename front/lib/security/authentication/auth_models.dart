part of 'autenticacao_controller.dart';

class FolhioUsuario {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool emailVerified;
  final bool twoFactorEnabled;
  final String? twoFactorMethod;

  const FolhioUsuario({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.emailVerified,
    this.twoFactorEnabled = false,
    this.twoFactorMethod,
  });

  factory FolhioUsuario.deJson(Map<String, dynamic> json) {
    return FolhioUsuario(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Professor',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      emailVerified: json['emailVerified'] == true,
      twoFactorEnabled: json['twoFactorEnabled'] == true,
      twoFactorMethod: json['twoFactorMethod'] as String?,
    );
  }

  FolhioUsuario copiarCom({
    String? name,
    String? email,
    String? avatarUrl,
    bool? emailVerified,
    bool? twoFactorEnabled,
    String? twoFactorMethod,
  }) {
    return FolhioUsuario(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      twoFactorMethod: twoFactorMethod ?? this.twoFactorMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'emailVerified': emailVerified,
      'twoFactorEnabled': twoFactorEnabled,
      'twoFactorMethod': twoFactorMethod,
    };
  }
}

class ResultadoAutenticacaoFolhio {
  final bool signedIn;
  final bool needsNameConfirmation;
  final String? twoFactorToken;
  final String? twoFactorMethod;
  final String? twoFactorDestination;

  const ResultadoAutenticacaoFolhio._({
    required this.signedIn,
    required this.needsNameConfirmation,
    this.twoFactorToken,
    this.twoFactorMethod,
    this.twoFactorDestination,
  });

  const ResultadoAutenticacaoFolhio.estaAutenticado({required bool needsNameConfirmation})
    : this._(signedIn: true, needsNameConfirmation: needsNameConfirmation);

  const ResultadoAutenticacaoFolhio.doisFatores({
    required String token,
    required String method,
    String? destination,
  }) : this._(
         signedIn: false,
         needsNameConfirmation: false,
         twoFactorToken: token,
         twoFactorMethod: method,
         twoFactorDestination: destination,
       );
}

class FolhioConfiguracoesDoisFatores {
  final bool enabled;
  final String method;
  final bool emailAvailable;
  final bool twoFactorRequired;
  final String? twoFactorToken;
  final String? twoFactorDestination;

  const FolhioConfiguracoesDoisFatores({
    required this.enabled,
    required this.method,
    required this.emailAvailable,
    this.twoFactorRequired = false,
    this.twoFactorToken,
    this.twoFactorDestination,
  });

  factory FolhioConfiguracoesDoisFatores.deJson(Map<String, dynamic> json) {
    return FolhioConfiguracoesDoisFatores(
      enabled: json['enabled'] == true,
      method: json['method'] as String? ?? 'email',
      emailAvailable: json['emailAvailable'] == true,
      twoFactorRequired: json['twoFactorRequired'] == true,
      twoFactorToken: json['twoFactorToken'] as String?,
      twoFactorDestination: json['twoFactorDestination'] as String?,
    );
  }
}

class FolhioResultadoAtualizacaoConta {
  final bool success;
  final FolhioUsuario? user;
  final bool twoFactorRequired;
  final String? twoFactorToken;
  final String? twoFactorDestination;
  final String message;

  const FolhioResultadoAtualizacaoConta({
    required this.success,
    required this.user,
    required this.twoFactorRequired,
    this.twoFactorToken,
    this.twoFactorDestination,
    required this.message,
  });

  factory FolhioResultadoAtualizacaoConta.deJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return FolhioResultadoAtualizacaoConta(
      success: json['success'] == true,
      user: userJson is Map<String, dynamic>
          ? FolhioUsuario.deJson(userJson)
          : null,
      twoFactorRequired: json['twoFactorRequired'] == true,
      twoFactorToken: json['twoFactorToken'] as String?,
      twoFactorDestination: json['twoFactorDestination'] as String?,
      message: json['message'] as String? ?? 'Conta atualizada.',
    );
  }
}

class FolhioAutenticacaoException implements Exception {
  final String message;

  const FolhioAutenticacaoException(this.message);

  @override
  String toString() => message;
}
