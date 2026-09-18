import 'dart:io';

import 'package:flutter/material.dart';

class CamadaTextoVisual {
  final String text;
  final Rect? rect;
  final Color color;

  const CamadaTextoVisual({
    this.text = 'Texto',
    this.rect,
    this.color = Colors.black,
  });

  CamadaTextoVisual copiarCom({String? text, Rect? rect, Color? color}) {
    return CamadaTextoVisual(
      text: text ?? this.text,
      rect: rect ?? this.rect,
      color: color ?? this.color,
    );
  }
}

class CamadaImagemVisual {
  final File file;
  final Rect? rect;

  const CamadaImagemVisual({required this.file, this.rect});

  CamadaImagemVisual copiarCom({Rect? rect}) {
    return CamadaImagemVisual(file: file, rect: rect ?? this.rect);
  }
}

class TracoMarcacaoVisual {
  final List<Offset> points;
  final Color color;

  const TracoMarcacaoVisual({required this.points, required this.color});

  TracoMarcacaoVisual copiarCom({List<Offset>? points, Color? color}) {
    return TracoMarcacaoVisual(
      points: points ?? List<Offset>.from(this.points),
      color: color ?? this.color,
    );
  }
}

class VisualEdicaoFerramenta {
  static const none = '';
  static const removeBackground = 'remover_fundo';
  static const crop = 'cortar';
  static const adjustments = 'ajustes';
  static const text = 'texto';
  static const image = 'imagem';
  static const mark = 'marcar';

  const VisualEdicaoFerramenta._();
}

class VisualEdicaoSessao {
  final List<CamadaTextoVisual> textLayers = [];
  final List<CamadaImagemVisual> imageLayers = [];
  final List<TracoMarcacaoVisual> markStrokes = [];

  String selectedTool = VisualEdicaoFerramenta.none;
  int? selectedTextIndex;
  int? selectedImageIndex;
  int quarterTurns = 0;
  double rotationDegrees = 0;
  int cropZoom = 0;
  int brightness = 0;
  int contrast = 0;
  bool mirrored = false;
  bool removeBackground = false;
  String cropShape = 'basic';
  String cropShapeBeforeCrop = 'basic';
  Map<String, double>? cropRatio;
  Rect? draftCropRect;
  Color markColor = const Color(0xFF21C89A);

  void redefinirCamadasESelecao() {
    selectedTool = VisualEdicaoFerramenta.none;
    selectedTextIndex = null;
    selectedImageIndex = null;
    textLayers.clear();
    imageLayers.clear();
    markStrokes.clear();
  }

  void redefinirAjustesVisuais() {
    quarterTurns = 0;
    rotationDegrees = 0;
    cropZoom = 0;
    brightness = 0;
    contrast = 0;
    mirrored = false;
    removeBackground = false;
    cropShape = 'basic';
    cropShapeBeforeCrop = 'basic';
    cropRatio = null;
    draftCropRect = null;
  }

  void redefinirTudo() {
    redefinirCamadasESelecao();
    redefinirAjustesVisuais();
  }

  void girarDireita() {
    quarterTurns = (quarterTurns + 1) % 4;
  }

  void alternarEspelhamento() {
    mirrored = !mirrored;
  }

  int adicionarCamadaTexto([CamadaTextoVisual layer = const CamadaTextoVisual()]) {
    textLayers.add(layer);
    selectedTool = VisualEdicaoFerramenta.text;
    selectedTextIndex = textLayers.length - 1;
    return selectedTextIndex!;
  }

  int adicionarCamadaImagem(CamadaImagemVisual layer) {
    imageLayers.add(layer);
    selectedTool = VisualEdicaoFerramenta.image;
    selectedImageIndex = imageLayers.length - 1;
    return selectedImageIndex!;
  }

  void selecionarCamadaTexto(int index) {
    selectedTool = VisualEdicaoFerramenta.text;
    selectedTextIndex = index;
  }

  void selecionarCamadaImagem(int index) {
    selectedTool = VisualEdicaoFerramenta.image;
    selectedImageIndex = index;
  }

  void limparSelecaoTexto() {
    selectedTextIndex = null;
  }

  void limparSelecaoImagem() {
    selectedImageIndex = null;
  }

  void removerCamadaTextoSelecionada() {
    final index = selectedTextIndex;
    if (index == null || index < 0 || index >= textLayers.length) return;
    textLayers.removeAt(index);
    selectedTextIndex = null;
  }

  void removerCamadaImagemSelecionada() {
    final index = selectedImageIndex;
    if (index == null || index < 0 || index >= imageLayers.length) return;
    imageLayers.removeAt(index);
    selectedImageIndex = imageLayers.isEmpty
        ? null
        : index.clamp(0, imageLayers.length - 1).toInt();
  }
}
