import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../controller/settings/aparencia_controller.dart';
import '../../service/api/folhio_api_gateway.dart';
import '../../repository/local/persistencia_local_repository.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';
import '../ai/ia_screen.dart';
import '../converter/conversor_screen.dart';
import '../edit/edit_flows_screen.dart';
import '../library/meus_arquivos_screen.dart';
import '../settings/configuracoes_screen.dart';

part '../../widget/home/home_widgets.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final FolhioApiGateway _api = FolhioApiGateway();
  List<FolhioArquivoBiblioteca> _recentFiles = const [];
  bool _loadingFiles = true;

  @override
  void initState() {
    super.initState();
    _carregarArquivosRecentes();
  }

  @override
  void dispose() {
    _api.fechar();
    super.dispose();
  }

  Future<void> _carregarArquivosRecentes() async {
    try {
      final files = await _api.listarArquivosLocaisRecentes(limit: 3);
      if (mounted) {
        setState(() {
          _recentFiles = files;
          _loadingFiles = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFiles = false);
    }
  }

  void _abrir(Widget screen) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen)).then((_) {
      if (mounted) {
        _carregarArquivosRecentes();
      }
    });
  }

  void _abrirArquivos({String search = ''}) {
    _abrir(MeusArquivosScreen(initialSearch: search, startInFiles: true));
  }

  Future<void> _baixarArquivo(FolhioArquivoBiblioteca file) async {
    try {
      await _api.baixarArquivoBiblioteca(file);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FolhioApiGateway.humanizarErro(error))),
      );
    }
  }

  Future<void> _excluirArquivoRecente(FolhioArquivoBiblioteca file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir material?'),
        content: Text(
          'O arquivo "${file.fileName}" será removido da Biblioteca.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.excluirArquivoBiblioteca(file.id);
      await _carregarArquivosRecentes();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Material excluído.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FolhioApiGateway.humanizarErro(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return FolhioScaffold(
      title: 'Início',
      currentIndex: 0,
      actions: [
        IconButton(
          tooltip: 'Configurações',
          icon: Icon(Icons.settings_outlined, color: colors.text),
          onPressed: () => _abrir(const ConfiguracoesScreen()),
        ),
        const SizedBox(width: 6),
      ],
      body: FolhioCorpoPagina(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        children: [
          const _CabecalhoSaudacao(),
          const SizedBox(height: 14),
          const TituloSecao('Criar rapidamente'),
          SizedBox(
            height: 124,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _AcaoRapidaCard(
                  icon: Icons.assignment_outlined,
                  iconColor: CoresFolhio.green,
                  title: 'Criar atividade',
                  subtitle: 'Com IA',
                  onTap: () => _abrir(const IaScreen(materialType: 'Atividade')),
                ),
                _AcaoRapidaCard(
                  icon: Icons.quiz_outlined,
                  iconColor: CoresFolhio.blue,
                  title: 'Gerar prova',
                  subtitle: 'Com gabarito',
                  onTap: () => _abrir(const IaScreen(materialType: 'Prova')),
                ),
                _AcaoRapidaCard(
                  icon: Icons.event_note_outlined,
                  iconColor: CoresFolhio.orange,
                  title: 'Plano de aula',
                  subtitle: 'Roteiro rápido',
                  onTap: () =>
                      _abrir(const IaScreen(materialType: 'Plano de aula')),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Expanded(child: TituloSecao('Continuar')),
              TextButton(
                onPressed: () => _abrirArquivos(),
                child: const Text('Ver meus arquivos'),
              ),
            ],
          ),
          if (_loadingFiles)
            const _TextoVazioDiscreto('Carregando materiais...')
          else if (_recentFiles.isEmpty)
            const _ArquivosInicioVazios()
          else
            ..._recentFiles.map(
              (file) => _ArquivoBibliotecaTile(
                file: file,
                onDownload: () => _baixarArquivo(file),
                onOpenFiles: () => _abrirArquivos(),
                onDelete: () => _excluirArquivoRecente(file),
              ),
            ),
          const TituloSecao('Ações rápidas'),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _MiniAcaoCard(
                icon: Icons.cached_outlined,
                title: 'Converter',
                subtitle: 'PDF e imagens',
                onTap: () => _abrir(const ConversorScreen()),
              ),
              _MiniAcaoCard(
                icon: Icons.compress,
                title: 'Compactar PDF',
                subtitle: 'Enviar menor',
                onTap: () => _abrir(const CompactacaoPdfScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
