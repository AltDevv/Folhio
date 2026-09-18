part of 'tools_flows_screen.dart';

class RenomeacaoLoteScreen extends StatefulWidget {
  const RenomeacaoLoteScreen({super.key});

  @override
  State<RenomeacaoLoteScreen> createState() => _RenomeacaoLoteScreenState();
}

class _RenomeacaoLoteScreenState extends State<RenomeacaoLoteScreen> {
  final _baseNameController = TextEditingController(text: 'Atividade');
  final List<File> _files = [];
  int _counterIndex = 1;
  bool _processing = false;

  @override
  void dispose() {
    _baseNameController.dispose();
    super.dispose();
  }

  Future<void> _selecionarArquivos() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    final paths =
        result?.files.map((file) => file.path).whereType<String>().toList() ??
        [];
    if (paths.isEmpty) return;
    setState(() {
      _files
        ..clear()
        ..addAll(paths.map(File.new));
    });
  }

  Future<void> _renomearArquivos() async {
    if (_files.isEmpty) {
      await _selecionarArquivos();
      return;
    }

    final baseName = _higienizarArquivoNome(_baseNameController.text);
    if (baseName.isEmpty) {
      _mostrarResultadoFerramenta(
        context,
        'Informe um nome padrão para os arquivos.',
        null,
      );
      return;
    }

    setState(() => _processing = true);
    try {
      var renamed = 0;
      for (var index = 0; index < _files.length; index++) {
        final file = _files[index];
        if (!await file.exists()) continue;
        final target = _destinoUnicoPara(
          file,
          _novoNomePara(file, baseName, index),
        );
        await file.rename(target.path);
        renamed++;
      }
      if (!mounted) return;
      _mostrarResultadoFerramenta(context, '$renamed arquivos renomeados.', null);
      setState(_files.clear);
    } catch (_) {
      if (!mounted) return;
      _mostrarResultadoFerramenta(
        context,
        'Não foi possível renomear todos os arquivos. Verifique se eles estao abertos em outro app.',
        null,
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  String _novoNomePara(File file, String baseName, int index) {
    return '$baseName-${_contadorPara(index)}${_extensaoDe(file.path)}';
  }

  String _contadorPara(int index) {
    final number = index + 1;
    return switch (_counterIndex) {
      0 => '$number',
      1 => number.toString().padLeft(2, '0'),
      _ => _letrasPara(number),
    };
  }

  String _letrasPara(int number) {
    var value = number;
    var result = '';
    while (value > 0) {
      value--;
      result = String.fromCharCode(65 + (value % 26)) + result;
      value ~/= 26;
    }
    return result;
  }

  File _destinoUnicoPara(File source, String fileName) {
    final directory = _diretorioDe(source.path);
    final extension = _extensaoDe(fileName);
    final nameWithoutExtension = extension.isEmpty
        ? fileName
        : fileName.substring(0, fileName.length - extension.length);
    var target = File('$directory${Platform.pathSeparator}$fileName');
    var copy = 2;
    while (target.existsSync() && target.path != source.path) {
      target = File(
        '$directory${Platform.pathSeparator}$nameWithoutExtension-$copy$extension',
      );
      copy++;
    }
    return target;
  }

  String _diretorioDe(String path) {
    final index = path.lastIndexOf(Platform.pathSeparator);
    return index < 0 ? '.' : path.substring(0, index);
  }

  String _nomeArquivoDe(String path) {
    final index = path.lastIndexOf(Platform.pathSeparator);
    return index < 0 ? path : path.substring(index + 1);
  }

  String _extensaoDe(String path) {
    final name = _nomeArquivoDe(path);
    final index = name.lastIndexOf('.');
    return index <= 0 ? '' : name.substring(index);
  }

  String _higienizarArquivoNome(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> _linhasPrevia() {
    if (_files.isEmpty) {
      return ['Selecione arquivos para ver a prévia.'];
    }
    final baseName = _higienizarArquivoNome(_baseNameController.text);
    return _files.take(5).toList().asMap().entries.map((entry) {
      final file = entry.value;
      final newName = baseName.isEmpty
          ? 'nome-padrão-${_contadorPara(entry.key)}${_extensaoDe(file.path)}'
          : _novoNomePara(file, baseName, entry.key);
      return '${_nomeArquivoDe(file.path)}  ->  $newName';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FolhioScaffold(
      title: 'Renomear em lote',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          _ArquivosSelecionadosCard(
            count: _files.length,
            detail: _files.isEmpty
                ? 'Toque para escolher os arquivos'
                : 'Toque para trocar a selecao',
            onTap: _processing ? null : _selecionarArquivos,
          ),
          const TituloSecao('Nome padrão'),
          _CampoTextoFerramenta(
            label: 'Nome base',
            hint: 'Ex: Atividade 8A Matemática',
            controller: _baseNameController,
            onChanged: () => setState(() {}),
          ),
          const TituloSecao('Contagem'),
          SeletorChip(
            labels: const ['1, 2, 3', '01, 02, 03', 'A, B, C'],
            selectedIndex: _counterIndex,
            onSelected: (index) => setState(() => _counterIndex = index),
          ),
          const SizedBox(height: 14),
          _PreviaBox(title: 'Antes e depois', lines: _linhasPrevia()),
          const SizedBox(height: 14),
          AcaoPrincipalButton(
            label: _processing ? 'Renomeando...' : 'Renomear arquivos',
            icon: Icons.sell,
            onPressed: _processing ? null : _renomearArquivos,
          ),
        ],
      ),
    );
  }
}
