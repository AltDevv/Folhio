import 'package:flutter/material.dart';

import '../config/rotas_folhio.dart';
import '../style/estilo_folhio.dart';
import '../service/api/folhio_api_gateway.dart';
import 'navegacao_inferior_folhio.dart';

class FolhioScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final List<Widget>? actions;
  final bool showBack;

  const FolhioScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    this.actions,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: EstiloFolhio.toolbarHeight,
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(title),
        actions: actions,
      ),
      body: Stack(
        children: [
          SafeArea(top: false, child: body),
          const _FolhioProgressoOverlay(),
        ],
      ),
      bottomNavigationBar: NavegacaoInferiorFolhio(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return;

          Navigator.of(context).pushReplacementNamed(RotasFolhio.tabs[index]);
        },
      ),
    );
  }
}

class _FolhioProgressoOverlay extends StatelessWidget {
  const _FolhioProgressoOverlay();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FolhioArquivoGerado?>(
      valueListenable: FolhioApiGateway.generatedFile,
      builder: (context, file, child) {
        if (file != null) {
          return _FolhioArquivoProntoOverlay(file: file);
        }

        return ValueListenableBuilder<FolhioProgressoOperacao?>(
          valueListenable: FolhioApiGateway.progress,
          builder: (context, current, child) {
            if (current == null) {
              return const SizedBox.shrink();
            }

            final percent = (current.progress * 100).clamp(0, 100).round();
            final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
            return Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.62),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: CoresFolhio.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: CoresFolhio.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sync, color: colors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                current.message,
                                style: const TextStyle(
                                  color: CoresFolhio.cream,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: current.progress.clamp(0, 1).toDouble(),
                            minHeight: 12,
                            backgroundColor: CoresFolhio.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Mantenha o app aberto até terminar.',
                          style: TextStyle(
                            color: colors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FolhioArquivoProntoOverlay extends StatelessWidget {
  final FolhioArquivoGerado file;

  const _FolhioArquivoProntoOverlay({required this.file});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.62),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Center(
          child: Container(
            width: 340,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: CoresFolhio.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: CoresFolhio.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 26,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: _AcoesArquivoGerado(
              key: ValueKey(
                '${file.fileName}-${file.storageKey ?? ''}-${file.downloadUrl ?? ''}',
              ),
              file: file,
            ),
          ),
        ),
      ),
    );
  }
}

class _AcoesArquivoGerado extends StatefulWidget {
  final FolhioArquivoGerado file;

  const _AcoesArquivoGerado({super.key, required this.file});

  @override
  State<_AcoesArquivoGerado> createState() => _AcoesArquivoGeradoState();
}

class _AcoesArquivoGeradoState extends State<_AcoesArquivoGerado> {
  final FolhioApiGateway _api = FolhioApiGateway();
  bool _busy = false;
  bool _saveInLibrary = false;
  String? _message;

  @override
  void dispose() {
    _api.fechar();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() => _message = FolhioApiGateway.humanizarErro(error));
      }
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _alternarSalvamentoBiblioteca(bool? checked) async {
    if (checked != true) {
      setState(() => _saveInLibrary = false);
      return;
    }

    await _executar(() async {
      try {
        await _api.salvarArquivoGeradoNaBiblioteca(widget.file);
        if (mounted) {
          setState(() {
            _saveInLibrary = true;
            _message = 'Salvo na biblioteca em Conversões.';
          });
        }
      } on FolhioConflitoBibliotecaException {
        final choice = await _solicitarEscolhaConflito();
        if (choice == null) {
          if (mounted) {
            setState(() {
              _saveInLibrary = false;
              _message = 'O arquivo não foi salvo na biblioteca.';
            });
          }
          return;
        }
        await _api.salvarArquivoGeradoNaBiblioteca(
          widget.file,
          conflictStrategy: choice,
        );
        if (mounted) {
          setState(() {
            _saveInLibrary = true;
            _message = choice == 'overwrite'
                ? 'Arquivo substituído na biblioteca.'
                : 'Salvo na biblioteca mantendo os dois arquivos.';
          });
        }
      }
    });
  }

  Future<String?> _solicitarEscolhaConflito() {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CoresFolhio.surface,
        title: const Text('Arquivo já existe'),
        content: const Text(
          'Já existe um arquivo com esse nome em Conversões. O que deseja fazer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('keep_both'),
            child: const Text('Manter os dois'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('overwrite'),
            child: const Text('Sobrescrever'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoresTemaFolhio>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.check_rounded, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arquivo pronto',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _nomeArquivoAbreviado(widget.file.fileName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Fechar',
              onPressed: _busy ? null : FolhioApiGateway.limparArquivoGerado,
              icon: Icon(Icons.close, color: colors.muted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        CheckboxListTile(
          value: _saveInLibrary,
          onChanged: _busy ? null : _alternarSalvamentoBiblioteca,
          dense: true,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          activeColor: colors.primary,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Salvar na biblioteca',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Pasta Conversões',
            style: TextStyle(
              color: colors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _AcaoProgressoButton(
          icon: Icons.download,
          label: 'Salvar em Downloads',
          enabled: !_busy,
          onTap: () => _executar(() async {
            final path = await FolhioApiGateway.salvarEmDownloads(widget.file);
            if (mounted) setState(() => _message = 'Salvo em $path');
          }),
        ),
        const SizedBox(height: 8),
        _AcaoProgressoButton(
          icon: Icons.folder_open,
          label: 'Escolher onde salvar',
          enabled: !_busy,
          onTap: () => _executar(() async {
            final path = await FolhioApiGateway.escolherOndeSalvar(widget.file);
            if (mounted) {
              setState(
                () => _message = path == null
                    ? 'Salvamento cancelado'
                    : 'Salvo em $path',
              );
            }
          }),
        ),
        const SizedBox(height: 8),
        _AcaoProgressoButton(
          icon: Icons.share,
          label: 'Compartilhar',
          enabled: !_busy,
          onTap: () =>
              _executar(() => FolhioApiGateway.compartilharArquivoGerado(widget.file)),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  String _nomeArquivoAbreviado(String fileName) {
    if (fileName.length <= 34) return fileName;
    final dot = fileName.lastIndexOf('.');
    final extension = dot > 0 ? fileName.substring(dot) : '';
    final baseLimit = extension.isEmpty ? 31 : 31 - extension.length;
    if (baseLimit <= 8) return '${fileName.substring(0, 31)}...';
    return '${fileName.substring(0, baseLimit)}...$extension';
  }
}

class _AcaoProgressoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _AcaoProgressoButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: CoresFolhio.cream,
          side: const BorderSide(color: CoresFolhio.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class FolhioCorpoPagina extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  const FolhioCorpoPagina({
    super.key,
    required this.children,
    this.padding = EstiloFolhio.pagePadding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: padding,
      children: children,
    );
  }
}

class TituloSecao extends StatelessWidget {
  final String title;

  const TituloSecao(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final folhio = Theme.of(context).extension<CoresTemaFolhio>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 12),
      child: Text(
        title,
        style: TextStyle(
          color: folhio.muted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
