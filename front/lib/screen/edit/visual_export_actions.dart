part of 'edit_flows_screen.dart';

extension _AcoesExportacaoVisual on _EdicaoImagemScreenState {
  Future<void> _exportarEdicaoVisual() async {
    final file = _selectedFile;
    if (file == null) return;
    if (!_ehImagem(file)) {
      await _exportarDocumentoComoPdf(file);
      return;
    }

    try {
      final response = await _viewModel.exportarImagemVisual(
        file: file,
        quarterTurns: _session.quarterTurns,
        rotationDegrees: _session.rotationDegrees,
        mirrored: _session.mirrored,
        brightness: _session.brightness,
        contrast: _session.contrast,
        removeBackground: _session.removeBackground,
        cropShape: _session.cropShape,
        textLayers: _session.textLayers.map(_dadosCamadaTexto).toList(),
        imageLayers: await _dadosCamadasImagem(),
        crop: _dadosRecorte(),
        marks: _dadosMarcacao(),
      );
      if (!mounted) return;
      _mostrarResultadoEdicao(context, response.message, response.outputFile?.fileName);
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoEdicao(
        context,
        'Não foi possível editar a imagem. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    }
  }

  Future<void> _exportarDocumentoComoPdf(File originalFile) async {
    final wordFile =
        _editableWordFile ?? (_ehWord(originalFile) ? originalFile : null);
    if (wordFile == null) {
      _mostrarResultadoEdicao(
        context,
        'Não foi possível preparar o Word editável para exportar.',
        null,
      );
      return;
    }

    try {
      final response = await _viewModel.exportarDocumentoEditavel(
        file: wordFile,
        sourceMimeType: _tipoMimePara(wordFile),
        outputFormat: 'pdf',
        textLayers: _session.textLayers.map(_dadosCamadaTexto).toList(),
        imageLayers: await _dadosCamadasImagem(),
        marks: _dadosMarcacao(),
      );
      if (!mounted) return;
      _mostrarResultadoEdicao(
        context,
        response.message.isEmpty
            ? 'Word editado e convertido para PDF para baixar.'
            : response.message,
        response.outputFile?.fileName,
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarResultadoEdicao(
        context,
        'Não foi possível exportar o documento. ${FolhioApiGateway.humanizarErro(error)}',
        null,
      );
    }
  }

  Map<String, dynamic>? _dadosRecorte() {
    Rect? rect = _retanguloRecorteDaProporcao(_session.cropRatio);
    if (_session.selectedTool == VisualEdicaoFerramenta.crop) {
      rect = _session.draftCropRect ?? rect ?? _retanguloRecortePadrao();
    } else if (_session.cropShape != 'basic' && rect == null) {
      rect = _session.draftCropRect ?? _retanguloRecortePadrao();
    }
    final ratio = _proporcaoRecorteDoRetangulo(rect) ?? _session.cropRatio;
    if (ratio == null) return null;
    return {
      'x': ratio['x'] ?? 0.0,
      'y': ratio['y'] ?? 0.0,
      'width': ratio['width'] ?? 1.0,
      'height': ratio['height'] ?? 1.0,
      'shape': _session.cropShape,
    };
  }

  Rect? _retanguloRecortePadrao() {
    final bounds = _retanguloConteudoImagem();
    if (bounds == null || bounds.width <= 0 || bounds.height <= 0) return null;
    const minSize = 64.0;
    final margin = (18 + _session.cropZoom * 0.35).clamp(12.0, 80.0).toDouble();
    return Rect.fromLTRB(
      bounds.left + margin,
      bounds.top + margin,
      (bounds.right - margin)
          .clamp(bounds.left + margin + minSize, bounds.right)
          .toDouble(),
      (bounds.bottom - margin)
          .clamp(bounds.top + margin + minSize, bounds.bottom)
          .toDouble(),
    );
  }

  Map<String, double>? _proporcaoRecorteDoRetangulo(Rect? rect) {
    final contentRect = _retanguloConteudoImagem();
    if (rect == null ||
        contentRect == null ||
        contentRect.width <= 0 ||
        contentRect.height <= 0) {
      return null;
    }
    final clipped = rect.intersect(contentRect);
    if (clipped.width <= 1 || clipped.height <= 1) return null;
    return {
      'x': ((clipped.left - contentRect.left) / contentRect.width)
          .clamp(0.0, 1.0)
          .toDouble(),
      'y': ((clipped.top - contentRect.top) / contentRect.height)
          .clamp(0.0, 1.0)
          .toDouble(),
      'width': (clipped.width / contentRect.width).clamp(0.0, 1.0).toDouble(),
      'height': (clipped.height / contentRect.height)
          .clamp(0.0, 1.0)
          .toDouble(),
    };
  }

  Rect? _retanguloRecorteDaProporcao(Map<String, double>? ratio) {
    final contentRect = _retanguloConteudoImagem();
    if (ratio == null ||
        contentRect == null ||
        contentRect.width <= 0 ||
        contentRect.height <= 0) {
      return null;
    }
    final x = (ratio['x'] ?? 0.0).clamp(0.0, 1.0).toDouble();
    final y = (ratio['y'] ?? 0.0).clamp(0.0, 1.0).toDouble();
    final widthRatio = (ratio['width'] ?? 1.0).clamp(0.0, 1.0 - x).toDouble();
    final heightRatio = (ratio['height'] ?? 1.0).clamp(0.0, 1.0 - y).toDouble();
    if (widthRatio <= 0 || heightRatio <= 0) return null;
    return Rect.fromLTWH(
      contentRect.left + x * contentRect.width,
      contentRect.top + y * contentRect.height,
      widthRatio * contentRect.width,
      heightRatio * contentRect.height,
    );
  }

  Rect? _retanguloRecorteQuadrado(Rect? rect) {
    final contentRect = _retanguloConteudoImagem();
    if (rect == null ||
        contentRect == null ||
        contentRect.width <= 0 ||
        contentRect.height <= 0) {
      return rect;
    }
    final clipped = rect.intersect(contentRect);
    final maxSide = math.min(contentRect.width, contentRect.height);
    final side = math
        .max(64.0, math.min(clipped.width, clipped.height))
        .clamp(1.0, maxSide)
        .toDouble();
    final center = clipped.center;
    final left = (center.dx - side / 2)
        .clamp(contentRect.left, contentRect.right - side)
        .toDouble();
    final top = (center.dy - side / 2)
        .clamp(contentRect.top, contentRect.bottom - side)
        .toDouble();
    return Rect.fromLTWH(left, top, side, side);
  }

  List<Map<String, dynamic>> _dadosMarcacao() {
    final contentRect = _retanguloConteudoImagem();
    if (contentRect == null ||
        contentRect.width <= 0 ||
        contentRect.height <= 0) {
      return [];
    }
    return [
      for (final stroke in _session.markStrokes)
        {
          'color': _corHexadecimal(stroke.color),
          'points': [
            for (final point in stroke.points)
              {
                'x': ((point.dx - contentRect.left) / contentRect.width).clamp(
                  0.0,
                  1.0,
                ),
                'y': ((point.dy - contentRect.top) / contentRect.height).clamp(
                  0.0,
                  1.0,
                ),
              },
          ],
        },
    ];
  }

  Map<String, dynamic> _dadosCamadaTexto(CamadaTextoVisual layer) {
    final rect = layer.rect;
    final contentRect = _retanguloConteudoImagem();
    return {
      'text': layer.text,
      'color': _corHexadecimal(layer.color),
      if (rect != null &&
          contentRect != null &&
          contentRect.width > 0 &&
          contentRect.height > 0)
        'rect': {
          'x': ((rect.left - contentRect.left) / contentRect.width).clamp(
            0.0,
            1.0,
          ),
          'y': ((rect.top - contentRect.top) / contentRect.height).clamp(
            0.0,
            1.0,
          ),
          'width': (rect.width / contentRect.width).clamp(0.0, 1.0),
          'height': (rect.height / contentRect.height).clamp(0.0, 1.0),
        },
    };
  }

  Future<List<Map<String, dynamic>>> _dadosCamadasImagem() async {
    final payloads = <Map<String, dynamic>>[];
    for (final layer in _session.imageLayers) {
      final rect = layer.rect ?? _retanguloPadraoCamadaImagem(payloads.length);
      final contentRect = _retanguloConteudoImagem();
      if (rect == null ||
          contentRect == null ||
          contentRect.width <= 0 ||
          contentRect.height <= 0) {
        continue;
      }
      final uploaded = await _viewModel.enviarArquivoCamada(layer.file);
      payloads.add({
        'file': {
          'id': uploaded.fileId,
          'name': uploaded.fileName,
          'mimeType': uploaded.mimeType,
        },
        'rect': {
          'x': (rect.left - contentRect.left) / contentRect.width,
          'y': (rect.top - contentRect.top) / contentRect.height,
          'width': rect.width / contentRect.width,
          'height': rect.height / contentRect.height,
        },
      });
    }
    return payloads;
  }

  Rect? _retanguloPadraoCamadaImagem(int index) {
    final contentRect = _retanguloConteudoImagem();
    if (contentRect == null ||
        contentRect.width <= 0 ||
        contentRect.height <= 0) {
      return null;
    }
    final width = (contentRect.width * 0.24)
        .clamp(42.0, contentRect.width)
        .toDouble();
    final height = (contentRect.height * 0.18)
        .clamp(42.0, contentRect.height)
        .toDouble();
    final offset = (index * 14).clamp(0, 70).toDouble();
    final left = (contentRect.left + ((contentRect.width - width) / 2) + offset)
        .clamp(contentRect.left, contentRect.right - width)
        .toDouble();
    final top = (contentRect.top + ((contentRect.height - height) / 2) + offset)
        .clamp(contentRect.top, contentRect.bottom - height)
        .toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }

  String _corHexadecimal(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
  }

  Future<Size> _lerTamanhoImagem(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    return size;
  }

  Rect? _retanguloConteudoImagem() {
    final canvas = _canvasSize;
    if (canvas == null) return null;
    return _retanguloConteudoPara(canvas);
  }

  Rect? _retanguloConteudoPara(Size canvas) {
    final image = _imageSize;
    if (image == null ||
        canvas.width <= 0 ||
        canvas.height <= 0 ||
        image.width <= 0 ||
        image.height <= 0) {
      return null;
    }
    final displayedImage = _session.quarterTurns.isOdd
        ? Size(image.height, image.width)
        : image;
    final scale = (canvas.width / displayedImage.width)
        .clamp(0.0, canvas.height / displayedImage.height)
        .toDouble();
    final width = displayedImage.width * scale;
    final height = displayedImage.height * scale;
    return Rect.fromLTWH(
      (canvas.width - width) / 2,
      (canvas.height - height) / 2,
      width,
      height,
    );
  }

  Rect _remapearRetangulo(Rect rect, Rect from, Rect to) {
    final x = ((rect.left - from.left) / from.width).clamp(0.0, 1.0).toDouble();
    final y = ((rect.top - from.top) / from.height).clamp(0.0, 1.0).toDouble();
    final width = (rect.width / from.width).clamp(0.0, 1.0 - x).toDouble();
    final height = (rect.height / from.height).clamp(0.0, 1.0 - y).toDouble();
    return Rect.fromLTWH(
      to.left + x * to.width,
      to.top + y * to.height,
      width * to.width,
      height * to.height,
    );
  }

  Offset _remapearPonto(Offset point, Rect from, Rect to) {
    final x = ((point.dx - from.left) / from.width).clamp(0.0, 1.0).toDouble();
    final y = ((point.dy - from.top) / from.height).clamp(0.0, 1.0).toDouble();
    return Offset(to.left + x * to.width, to.top + y * to.height);
  }

  bool _ehImagem(File file) {
    final extension = _extensao(file);
    return extension == 'png' || extension == 'jpg' || extension == 'jpeg';
  }

  bool _ehPdf(File file) => _extensao(file) == 'pdf';

  bool _ehWord(File file) {
    final extension = _extensao(file);
    return extension == 'doc' || extension == 'docx';
  }

  String _nomeArquivo(File file) {
    return file.uri.pathSegments.isEmpty
        ? file.path
        : file.uri.pathSegments.last;
  }

  String _extensao(File file) {
    final name = _nomeArquivo(file);
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }

  String _tipoMimePara(File file) {
    final extension = _extensao(file);
    return switch (extension) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _converterPdfParaWord(File file) async {
    _mostrarResultadoEdicao(
      context,
      'Convertendo PDF para Word para permitir edição.',
      null,
    );
    final document = await _viewModel.converterPdfParaWordEditavel(file);
    _editableWordFile = document.file;
    if (document.file.path.isEmpty) {
      throw const FormatException('A conversão não retornou um Word editável.');
    }
    if (mounted) {
      _mostrarResultadoEdicao(
        context,
        document.response.message.isEmpty
            ? 'PDF convertido para Word.'
            : document.response.message,
        document.response.outputFile?.fileName,
      );
    }
  }

  void _prepararCamadasDocumento() {
    if (_session.textLayers.isEmpty) {
      _session.textLayers.add(
        const CamadaTextoVisual(
          text: 'Toque no texto para editar o conteúdo do Word.',
          rect: Rect.fromLTWH(90, 120, 610, 90),
          color: Colors.black,
        ),
      );
    }
  }
}
