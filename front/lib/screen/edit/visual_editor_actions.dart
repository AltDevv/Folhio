part of 'edit_flows_screen.dart';

extension _AcoesEditorVisual on _EdicaoImagemScreenState {
  Future<void> _selecionarArquivo() async {
    final file = await _escolherArquivoEdicaoVisual();
    if (file == null) return;

    _renovar(() {
      _selectedFile = file;
      _editableWordFile = null;
      _session.redefinirTudo();
      _imageSize = null;
    });

    try {
      if (_ehImagem(file)) {
        final size = await _lerTamanhoImagem(file);
        if (!mounted) return;
        _renovar(() => _imageSize = size);
      } else {
        if (_ehPdf(file)) {
          await _converterPdfParaWord(file);
        } else if (_ehWord(file)) {
          _editableWordFile = file;
        }
        if (!mounted) return;
        _renovar(() {
          _imageSize = const Size(794, 1123);
          _prepararCamadasDocumento();
        });
      }
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoEdicao(
        context,
        'Não foi possível preparar o arquivo. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    }
  }

  void _escolherFerramenta(String tool) {
    if (tool == VisualEdicaoFerramenta.image) {
      _escolherCamadaImagem();
      return;
    }
    if (tool == VisualEdicaoFerramenta.removeBackground) {
      _renovar(() => _session.removeBackground = !_session.removeBackground);
      return;
    }
    _renovar(() {
      _session.selectedTool = tool;
      if (tool == VisualEdicaoFerramenta.crop) {
        _session.cropShapeBeforeCrop = _session.cropShape;
        _session.draftCropRect =
            _retanguloRecorteDaProporcao(_session.cropRatio) ?? _retanguloRecortePadrao();
        if (_session.cropShape != 'basic') {
          _session.draftCropRect = _retanguloRecorteQuadrado(_session.draftCropRect);
        }
      }
      if (tool == VisualEdicaoFerramenta.text) {
        _session.selectedTextIndex = null;
      }
    });
  }

  void _girarDireita() {
    _renovar(_session.girarDireita);
  }

  void _definirGrausRotacao(double value) {
    _renovar(() => _session.rotationDegrees = value);
  }

  void _definirFormaRecorte(String shape) {
    _renovar(() {
      _session.cropShape = shape;
      if (shape != 'basic') {
        _session.draftCropRect = _retanguloRecorteQuadrado(
          _session.draftCropRect ??
              _retanguloRecorteDaProporcao(_session.cropRatio) ??
              _retanguloRecortePadrao(),
        );
      }
    });
  }

  void _redefinir() {
    _renovar(() {
      _session.redefinirTudo();
    });
  }

  void _limparArquivoSelecionado() {
    _renovar(() {
      _selectedFile = null;
      _session.redefinirTudo();
      _canvasSize = null;
      _imageSize = null;
    });
  }

  void _cancelarRecorte() {
    _renovar(() {
      _session.cropShape = _session.cropShapeBeforeCrop;
      _session.draftCropRect = _retanguloRecorteDaProporcao(_session.cropRatio);
      if (_session.cropShape != 'basic') {
        _session.draftCropRect = _retanguloRecorteQuadrado(_session.draftCropRect);
      }
      _session.selectedTool = VisualEdicaoFerramenta.none;
    });
  }

  void _confirmarRecorte() {
    final confirmed = _session.draftCropRect ?? _retanguloRecortePadrao();
    _renovar(() {
      _session.cropRatio = _proporcaoRecorteDoRetangulo(confirmed);
      _session.draftCropRect = _retanguloRecorteDaProporcao(_session.cropRatio);
      _session.cropShapeBeforeCrop = _session.cropShape;
      _session.selectedTool = VisualEdicaoFerramenta.none;
    });
  }

  void _alternarEspelhamento() {
    _renovar(_session.alternarEspelhamento);
  }

  void _atualizarTamanhoTela(Size size) {
    final current = _canvasSize;
    if (current != null &&
        (current.width - size.width).abs() < 0.5 &&
        (current.height - size.height).abs() < 0.5) {
      return;
    }
    final oldContentRect = current == null ? null : _retanguloConteudoPara(current);
    final newContentRect = _retanguloConteudoPara(size);
    _renovar(() {
      if (oldContentRect != null &&
          newContentRect != null &&
          oldContentRect.width > 0 &&
          oldContentRect.height > 0) {
        for (var i = 0; i < _session.textLayers.length; i++) {
          final rect = _session.textLayers[i].rect;
          if (rect != null) {
            _session.textLayers[i] = _session.textLayers[i].copiarCom(
              rect: _remapearRetangulo(rect, oldContentRect, newContentRect),
            );
          }
        }
        for (var i = 0; i < _session.imageLayers.length; i++) {
          final rect = _session.imageLayers[i].rect;
          if (rect != null) {
            _session.imageLayers[i] = _session.imageLayers[i].copiarCom(
              rect: _remapearRetangulo(rect, oldContentRect, newContentRect),
            );
          }
        }
        if (_session.draftCropRect != null) {
          _session.draftCropRect = _remapearRetangulo(
            _session.draftCropRect!,
            oldContentRect,
            newContentRect,
          );
        }
        for (var i = 0; i < _session.markStrokes.length; i++) {
          _session.markStrokes[i] = _session.markStrokes[i].copiarCom(
            points: [
              for (final point in _session.markStrokes[i].points)
                _remapearPonto(point, oldContentRect, newContentRect),
            ],
          );
        }
      }
      _canvasSize = size;
    });
  }
}
