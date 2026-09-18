part of 'edit_flows_screen.dart';

extension _AcoesCamadasVisuais on _EdicaoImagemScreenState {
  void _adicionarCamadaTexto() {
    _session.adicionarCamadaTexto();
  }

  void _selecionarCamadaTexto(int index) {
    _renovar(() {
      _session.selecionarCamadaTexto(index);
    });
  }

  void _desmarcarCamadaTexto() {
    if (_session.selectedTextIndex == null) return;
    _renovar(_session.limparSelecaoTexto);
  }

  void _atualizarCamadaTexto(int index, CamadaTextoVisual layer) {
    if (index < 0 || index >= _session.textLayers.length) return;
    _renovar(() => _session.textLayers[index] = layer);
  }

  void _alterarCorTextoSelecionado(Color color) {
    final index = _session.selectedTextIndex;
    if (index == null || index < 0 || index >= _session.textLayers.length) {
      return;
    }
    _renovar(
      () => _session.textLayers[index] = _session.textLayers[index].copiarCom(
        color: color,
      ),
    );
  }

  void _removerCamadaTextoSelecionada() {
    final index = _session.selectedTextIndex;
    if (index == null || index < 0 || index >= _session.textLayers.length) {
      return;
    }
    _renovar(() {
      _session.removerCamadaTextoSelecionada();
    });
  }

  Future<void> _escolherCamadaImagem() async {
    final file = await _escolherArquivoImagemSobreposta();
    if (file == null || !mounted) return;
    _renovar(() {
      _session.adicionarCamadaImagem(
        CamadaImagemVisual(
          file: file,
          rect: _retanguloPadraoCamadaImagem(_session.imageLayers.length),
        ),
      );
    });
  }

  void _selecionarCamadaImagem(int index) {
    _renovar(() {
      _session.selecionarCamadaImagem(index);
    });
  }

  void _atualizarCamadaImagem(int index, CamadaImagemVisual layer) {
    if (index < 0 || index >= _session.imageLayers.length) return;
    _renovar(() => _session.imageLayers[index] = layer);
  }

  void _removerCamadaImagemSelecionada() {
    final index = _session.selectedImageIndex;
    if (index == null || index < 0 || index >= _session.imageLayers.length) {
      return;
    }
    _renovar(() {
      _session.removerCamadaImagemSelecionada();
    });
  }

  Color _corTextoSelecionado() {
    final index = _session.selectedTextIndex;
    if (index == null || index < 0 || index >= _session.textLayers.length) {
      return Colors.black;
    }
    return _session.textLayers[index].color;
  }
}
