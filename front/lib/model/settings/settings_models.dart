class ConfiguracoesAcessibilidadeState {
  final bool highContrast;
  final bool extraDescriptions;
  final String fontSize;

  const ConfiguracoesAcessibilidadeState({
    this.highContrast = false,
    this.extraDescriptions = true,
    this.fontSize = 'Padrão',
  });

  ConfiguracoesAcessibilidadeState copiarCom({
    bool? highContrast,
    bool? extraDescriptions,
    String? fontSize,
  }) {
    return ConfiguracoesAcessibilidadeState(
      highContrast: highContrast ?? this.highContrast,
      extraDescriptions: extraDescriptions ?? this.extraDescriptions,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class ConfiguracoesAparenciaState {
  final String themeMode;
  final String accentColor;

  const ConfiguracoesAparenciaState({
    this.themeMode = 'Claro',
    this.accentColor = 'Verde padrão',
  });

  ConfiguracoesAparenciaState copiarCom({String? themeMode, String? accentColor}) {
    return ConfiguracoesAparenciaState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

enum ModoEdicaoConta { none, name, email, password }

class PerfilContaState {
  final String name;
  final String email;
  final ModoEdicaoConta editMode;
  final bool savingName;
  final bool savingEmail;
  final bool savingPassword;
  final bool savingDelete;
  final bool sendingPasswordReset;

  const PerfilContaState({
    this.name = '',
    this.email = '',
    this.editMode = ModoEdicaoConta.none,
    this.savingName = false,
    this.savingEmail = false,
    this.savingPassword = false,
    this.savingDelete = false,
    this.sendingPasswordReset = false,
  });

  bool get isSaving =>
      savingName ||
      savingEmail ||
      savingPassword ||
      savingDelete ||
      sendingPasswordReset;

  String get displayName =>
      name.trim().isNotEmpty ? name.trim() : 'Sem nome definido';

  String get displayEmail =>
      email.trim().isNotEmpty ? email.trim() : 'Email não disponível';

  PerfilContaState copiarCom({
    String? name,
    String? email,
    ModoEdicaoConta? editMode,
    bool? savingName,
    bool? savingEmail,
    bool? savingPassword,
    bool? savingDelete,
    bool? sendingPasswordReset,
  }) {
    return PerfilContaState(
      name: name ?? this.name,
      email: email ?? this.email,
      editMode: editMode ?? this.editMode,
      savingName: savingName ?? this.savingName,
      savingEmail: savingEmail ?? this.savingEmail,
      savingPassword: savingPassword ?? this.savingPassword,
      savingDelete: savingDelete ?? this.savingDelete,
      sendingPasswordReset: sendingPasswordReset ?? this.sendingPasswordReset,
    );
  }
}

class ConfiguracoesDoisFatoresState {
  final bool enabled;
  final bool emailAvailable;
  final bool loading;
  final bool saving;
  final bool signedIn;
  final String? savingMessage;
  final String? email;

  const ConfiguracoesDoisFatoresState({
    this.enabled = false,
    this.emailAvailable = false,
    this.loading = true,
    this.saving = false,
    this.signedIn = false,
    this.savingMessage,
    this.email,
  });

  ConfiguracoesDoisFatoresState copiarCom({
    bool? enabled,
    bool? emailAvailable,
    bool? loading,
    bool? saving,
    bool? signedIn,
    String? savingMessage,
    String? email,
    bool clearSavingMessage = false,
  }) {
    return ConfiguracoesDoisFatoresState(
      enabled: enabled ?? this.enabled,
      emailAvailable: emailAvailable ?? this.emailAvailable,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      signedIn: signedIn ?? this.signedIn,
      savingMessage: clearSavingMessage
          ? null
          : savingMessage ?? this.savingMessage,
      email: email ?? this.email,
    );
  }
}
