part of 'configuracoes_screen.dart';

class ConfiguracoesAparenciaScreen extends StatefulWidget {
  const ConfiguracoesAparenciaScreen({super.key});

  @override
  State<ConfiguracoesAparenciaScreen> createState() =>
      _ConfiguracoesAparenciaScreenState();
}

class _ConfiguracoesAparenciaScreenState extends State<ConfiguracoesAparenciaScreen> {
  final _viewModel = ConfiguracoesAparenciaViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_aoVisualizacaoModeloAlterado);
  }

  void _aoVisualizacaoModeloAlterado() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_aoVisualizacaoModeloAlterado);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _definirModoTema(String value) async {
    final message = await _viewModel.definirModoTema(value);
    if (!mounted) return;
    _avisar(context, message);
  }

  Future<void> _definirCorDestaque(String value) async {
    final message = await _viewModel.definirCorDestaque(value);
    if (!mounted) return;
    _avisar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return _ConfiguracoesPagina(
      title: 'Aparência',
      children: [
        _GrupoConfiguracoes(
          children: [
            _DropdownConfiguracao(
              label: 'Tema',
              value: _viewModel.themeMode,
              values: const ['Escuro', 'Seguir sistema', 'Claro'],
              onChanged: _definirModoTema,
            ),
            _DropdownConfiguracao(
              label: 'Cor principal',
              value: _viewModel.accentColor,
              values: const ['Verde padrão', 'Azul', 'Roxo', 'Amarelo', 'Rosa'],
              onChanged: _definirCorDestaque,
            ),
          ],
        ),
      ],
    );
  }
}

class ConfiguracoesAcessibilidadeScreen extends StatefulWidget {
  const ConfiguracoesAcessibilidadeScreen({super.key});

  @override
  State<ConfiguracoesAcessibilidadeScreen> createState() =>
      _ConfiguracoesAcessibilidadeScreenState();
}

class _ConfiguracoesAcessibilidadeScreenState
    extends State<ConfiguracoesAcessibilidadeScreen> {
  final _viewModel = ConfiguracoesAcessibilidadeViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_aoVisualizacaoModeloAlterado);
    _viewModel.carregar();
  }

  void _aoVisualizacaoModeloAlterado() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_aoVisualizacaoModeloAlterado);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _definirAltoContraste(bool value) async {
    final message = await _viewModel.definirAltoContraste(value);
    if (!mounted) return;
    _avisar(context, message);
  }

  Future<void> _definirTamanhoFonte(String value) async {
    final message = await _viewModel.definirTamanhoFonte(value);
    if (!mounted) return;
    _avisar(context, message);
  }

  Future<void> _definirDescricoesExtras(bool value) async {
    final message = await _viewModel.definirDescricoesExtras(value);
    if (!mounted) return;
    _avisar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return _ConfiguracoesPagina(
      title: 'Acessibilidade',
      children: [
        _GrupoConfiguracoes(
          children: [
            _DropdownConfiguracao(
              label: 'Tamanho da fonte',
              value: _viewModel.fontSize,
              values: const ['Pequeno', 'Padrão', 'Grande'],
              onChanged: _definirTamanhoFonte,
            ),
            _ConfiguracaoAlternancia(
              title: 'Alto contraste',
              value: _viewModel.highContrast,
              onChanged: _definirAltoContraste,
            ),
            _ConfiguracaoAlternancia(
              title: 'Mostrar descrições extras',
              value: _viewModel.extraDescriptions,
              onChanged: _definirDescricoesExtras,
            ),
          ],
        ),
      ],
    );
  }
}
