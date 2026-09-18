import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech;

import '../../style/estilo_folhio.dart';
import '../../widget/actions.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';

part '../../widget/ai/ai_screen_widgets.dart';

class IaScreen extends StatefulWidget {
  final String materialType;

  const IaScreen({super.key, this.materialType = 'Atividade'});

  @override
  State<IaScreen> createState() => _IaScreenState();
}

class _IaScreenState extends State<IaScreen> {
  final _themeController = TextEditingController();
  final _detailsController = TextEditingController();
  final speech.SpeechToText _speech = speech.SpeechToText();

  int? _subjectIndex = 1;
  int _levelIndex = 1;
  int _adaptationIndex = 0;
  int _questions = 10;
  bool _includeAnswerKey = true;
  bool _moreOptionsOpen = false;
  bool _listeningDetails = false;
  bool _speechReady = false;
  bool _generating = false;
  String? _generationStep;
  String _dictationBaseText = '';

  static const _subjects = [
    'Português',
    'Matemática',
    'Ciências',
    'História',
    'Geografia',
    'Inglês',
    'Artes',
  ];

  static const _levels = ['Fácil', 'Médio', 'Difícil'];

  static const _adaptations = [
    'Padrão',
    'Texto simples',
    'TDAH',
    'Dislexia',
    'TEA',
    'Baixa visão',
  ];

  bool get _readyToGenerate {
    return _subjectIndex != null && _themeController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _speech.stop();
    _themeController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _alternarDetalhesVoz() async {
    if (_listeningDetails) {
      await _speech.stop();
      if (mounted) setState(() => _listeningDetails = false);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final available =
        _speechReady ||
        await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            if (status == 'done' || status == 'notListening') {
              setState(() => _listeningDetails = false);
            }
          },
          onError: (_) {
            if (!mounted) return;
            setState(() => _listeningDetails = false);
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Não foi possível ouvir agora. Tente novamente.'),
              ),
            );
          },
        );

    if (!available) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Permita o uso do microfone para ditar os detalhes.'),
        ),
      );
      return;
    }

    setState(() {
      _speechReady = true;
      _listeningDetails = true;
      _dictationBaseText = _detailsController.text.trim();
    });

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Pode falar. Vou colocar o texto nos detalhes.'),
      ),
    );

    await _speech.listen(
      listenOptions: speech.SpeechListenOptions(
        localeId: 'pt_BR',
        partialResults: true,
        listenMode: speech.ListenMode.dictation,
      ),
      onResult: (result) {
        if (!mounted) return;
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        final text = _dictationBaseText.isEmpty
            ? words
            : '$_dictationBaseText $words';
        setState(() {
          _detailsController.text = text;
          _detailsController.selection = TextSelection.collapsed(
            offset: _detailsController.text.length,
          );
        });
      },
    );
  }

  void _gerarMaterial() {
    if (!_readyToGenerate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha a disciplina e informe o tema.')),
      );
      return;
    }

    setState(() => _generating = true);
    final steps = [
      'Lendo informações',
      'Criando conteúdo',
      'Revisando estrutura',
      'Preparando gabarito',
      'Material pronto',
    ];
    Future<void>(() async {
      for (final step in steps) {
        if (!mounted) return;
        setState(() => _generationStep = step);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      if (!mounted) return;
      setState(() {
        _generating = false;
        _generationStep = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Material gerado com sucesso: ${widget.materialType} de '
            '${_subjects[_subjectIndex!]} sobre ${_themeController.text.trim()}.',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.folhioColors;
    return FolhioScaffold(
      title: 'Criar com IA',
      currentIndex: 1,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Icon(Icons.history, color: colors.text),
        ),
      ],
      body: Stack(
        children: [
          FolhioCorpoPagina(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              _SecaoEtiquetas(
                title: 'Disciplina',
                isRequired: true,
                labels: _subjects,
                selectedIndex: _subjectIndex,
                onSelected: (index) => setState(() => _subjectIndex = index),
              ),
              const TituloSecao('Conteúdo'),
              _EntradaTema(
                controller: _themeController,
                onChanged: () => setState(() {}),
              ),
              _EntradaDetalhes(
                controller: _detailsController,
                pickingAudio: _listeningDetails,
                onMicTap: _alternarDetalhesVoz,
                onChanged: () => setState(() {}),
              ),
              _MaisOpcoesButton(
                open: _moreOptionsOpen,
                onTap: () =>
                    setState(() => _moreOptionsOpen = !_moreOptionsOpen),
              ),
              if (_moreOptionsOpen) ...[
                const SizedBox(height: 12),
                const TituloSecao('Configurações'),
                _MaisOpcoesPanel(
                  levelIndex: _levelIndex,
                  adaptationIndex: _adaptationIndex,
                  questions: _questions,
                  includeAnswerKey: _includeAnswerKey,
                  levels: _levels,
                  adaptations: _adaptations,
                  onLevelSelected: (index) =>
                      setState(() => _levelIndex = index),
                  onAdaptationSelected: (index) {
                    setState(() => _adaptationIndex = index);
                  },
                  onQuestionsChanged: (value) =>
                      setState(() => _questions = value),
                  onAnswerKeyChanged: (value) {
                    setState(() => _includeAnswerKey = value);
                  },
                ),
              ],
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BarraGeracaoFixa(
              enabled: _readyToGenerate && !_generating,
              label: _generating
                  ? (_generationStep ?? 'Gerando...')
                  : 'Gerar material',
              helper: _readyToGenerate
                  ? null
                  : 'Preencha o tema para continuar.',
              onTap: _gerarMaterial,
            ),
          ),
        ],
      ),
    );
  }
}
