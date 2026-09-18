import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folhio/model/edit/visual_edit_models.dart';

void main() {
  test('VisualEditSession adiciona e seleciona camadas', () {
    final session = VisualEdicaoSessao();

    session.adicionarCamadaTexto(const CamadaTextoVisual(text: 'Titulo'));
    session.adicionarCamadaImagem(CamadaImagemVisual(file: File('grafico.png')));

    expect(session.textLayers.single.text, 'Titulo');
    expect(session.imageLayers.single.file.path, 'grafico.png');
    expect(session.selectedTool, VisualEdicaoFerramenta.image);
    expect(session.selectedTextIndex, 0);
    expect(session.selectedImageIndex, 0);
  });

  test('VisualEditSession remove selecoes e reseta estado visual', () {
    final session = VisualEdicaoSessao();

    session.adicionarCamadaTexto();
    session.adicionarCamadaImagem(CamadaImagemVisual(file: File('foto.png')));
    session.markStrokes.add(
      const TracoMarcacaoVisual(points: [Offset(1, 2)], color: Colors.green),
    );

    session.selecionarCamadaTexto(0);
    session.removerCamadaTextoSelecionada();
    session.removerCamadaImagemSelecionada();

    expect(session.textLayers, isEmpty);
    expect(session.imageLayers, isEmpty);
    expect(session.selectedTextIndex, isNull);
    expect(session.selectedImageIndex, isNull);

    session.redefinirCamadasESelecao();

    expect(session.markStrokes, isEmpty);
    expect(session.selectedTool, VisualEdicaoFerramenta.none);
  });

  test('VisualEditSession reseta ajustes visuais', () {
    final session = VisualEdicaoSessao()
      ..quarterTurns = 2
      ..rotationDegrees = 12
      ..cropZoom = 4
      ..brightness = 8
      ..contrast = 10
      ..mirrored = true
      ..removeBackground = true
      ..cropShape = 'circle'
      ..cropShapeBeforeCrop = 'circle'
      ..cropRatio = const {'x': 0.2}
      ..draftCropRect = const Rect.fromLTWH(1, 2, 3, 4);

    session.girarDireita();
    expect(session.quarterTurns, 3);

    session.alternarEspelhamento();
    expect(session.mirrored, isFalse);

    session.redefinirAjustesVisuais();

    expect(session.quarterTurns, 0);
    expect(session.rotationDegrees, 0);
    expect(session.cropZoom, 0);
    expect(session.brightness, 0);
    expect(session.contrast, 0);
    expect(session.removeBackground, isFalse);
    expect(session.cropShape, 'basic');
    expect(session.cropRatio, isNull);
    expect(session.draftCropRect, isNull);
  });
}
