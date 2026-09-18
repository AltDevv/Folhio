import 'dart:convert';

import 'package:flutter/material.dart';

import '../../repository/local/persistencia_local_repository.dart';
import '../../style/estilo_folhio.dart';

class AparenciaController extends ChangeNotifier {
  AparenciaController._();

  static final AparenciaController instance =
      AparenciaController._();

  final PersistenciaLocalRepository _repo = PersistenciaLocalRepository.instance;

  String themeModeLabel = 'Claro';
  String accentLabel = 'Verde padrão';
  String fontSizeLabel = 'Padrão';
  bool highContrast = false;
  bool extraDescriptions = true;

  ThemeMode get themeMode {
    return switch (themeModeLabel) {
      'Claro' => ThemeMode.light,
      'Seguir sistema' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Color get accentColor => _corPara(accentLabel);

  double get textScale {
    return switch (fontSizeLabel) {
      'Pequeno' => 0.94,
      'Grande' => 1.18,
      _ => 1.0,
    };
  }

  Future<void> carregar() async {
    final values = await Future.wait([
      _repo.configuracao('appearance.theme'),
      _repo.configuracao('appearance.accent'),
      _repo.configuracao('appearance.fontSize'),
      _repo.configuracao('accessibility.highContrast'),
      _repo.configuracao('accessibility.iconLabels'),
    ]);

    themeModeLabel = _escolher(_normalizarRotulo(values[0]), const [
      'Escuro',
      'Seguir sistema',
      'Claro',
    ], themeModeLabel);
    accentLabel = _escolher(_normalizarRotulo(values[1]), const [
      'Verde padrão',
      'Azul',
      'Roxo',
      'Amarelo',
      'Rosa',
    ], accentLabel);
    fontSizeLabel = _escolher(_normalizarRotulo(values[2]), const [
      'Pequeno',
      'Padrão',
      'Grande',
    ], fontSizeLabel);
    highContrast = values[3] == 'true';
    extraDescriptions = values[4] != 'false';
    notifyListeners();
  }

  Future<void> definirRotuloModoTema(String value) async {
    themeModeLabel = _escolher(_normalizarRotulo(value), const [
      'Escuro',
      'Seguir sistema',
      'Claro',
    ], themeModeLabel);
    await _repo.definirConfiguracao('appearance.theme', themeModeLabel);
    notifyListeners();
  }

  Future<void> definirRotuloDestaque(String value) async {
    accentLabel = _escolher(_normalizarRotulo(value), const [
      'Verde padrão',
      'Azul',
      'Roxo',
      'Amarelo',
      'Rosa',
    ], accentLabel);
    await _repo.definirConfiguracao('appearance.accent', accentLabel);
    notifyListeners();
  }

  Future<void> definirRotuloTamanhoFonte(String value) async {
    fontSizeLabel = _escolher(_normalizarRotulo(value), const [
      'Pequeno',
      'Padrão',
      'Grande',
    ], fontSizeLabel);
    await _repo.definirConfiguracao('appearance.fontSize', fontSizeLabel);
    notifyListeners();
  }

  Future<void> definirAltoContraste(bool value) async {
    highContrast = value;
    await _repo.definirConfiguracao('accessibility.highContrast', value.toString());
    notifyListeners();
  }

  Future<void> definirDescricoesExtras(bool value) async {
    extraDescriptions = value;
    await _repo.definirConfiguracao('accessibility.iconLabels', value.toString());
    notifyListeners();
  }

  Color _corPara(String label) {
    return switch (label) {
      'Azul' => CoresFolhio.blue,
      'Roxo' => CoresFolhio.violet,
      'Amarelo' => CoresFolhio.orange,
      'Rosa' => CoresFolhio.pink,
      _ => CoresFolhio.green,
    };
  }

  String _escolher(String? value, List<String> allowed, String fallback) {
    return value != null && allowed.contains(value) ? value : fallback;
  }

  String? _normalizarRotulo(String? value) {
    final repaired = _corrigirCodificacao(value);
    return switch (repaired) {
      'Padrao' => 'Padrão',
      _ => value,
    };
  }

  String? _corrigirCodificacao(String? value) {
    if (value == null || !value.contains('Ã')) {
      return value;
    }
    try {
      return utf8.decode(latin1.encode(value));
    } catch (_) {
      return value;
    }
  }
}
