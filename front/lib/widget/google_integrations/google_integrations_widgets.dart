part of '../../screen/google_integrations/google_integrations_screen.dart';

class _ContaCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback? onPrimaryTap;

  const _ContaCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      child: Row(
        children: [
          IconeArredondado(
            icon: icon,
            color: CoresFolhio.green,
            backgroundColor: const Color(0xFF123D33),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: CoresFolhio.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onPrimaryTap, child: Text(primaryLabel)),
        ],
      ),
    );
  }
}

class _SecaoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SecaoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _PrincipalButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _PrincipalButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _SecundarioButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _SecundarioButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: CoresFolhio.cream,
          side: const BorderSide(color: CoresFolhio.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _ArquivoSelecionadoBox extends StatelessWidget {
  final String? fileName;

  const _ArquivoSelecionadoBox({required this.fileName});

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: CoresFolhio.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFile ? CoresFolhio.green : CoresFolhio.borderSoft,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasFile ? Icons.insert_drive_file : Icons.info_outline,
            size: 18,
            color: hasFile ? CoresFolhio.green : CoresFolhio.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasFile ? fileName! : 'Nenhum arquivo escolhido',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CoresFolhio.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaAcoesPequena extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _LinhaAcoesPequena({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.refresh, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _LinhaSimples extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LinhaSimples({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return FolhioItemLista(
      icon: icon,
      iconColor: CoresFolhio.green,
      iconBackground: const Color(0xFF123D33),
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.check_circle, color: CoresFolhio.green),
    );
  }
}

class _TextoStatus extends StatelessWidget {
  final String? message;

  const _TextoStatus({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox(height: 10);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message!,
        style: const TextStyle(
          color: CoresFolhio.green,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MensagemVazia extends StatelessWidget {
  final String message;

  const _MensagemVazia(this.message);

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: CoresFolhio.muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _mensagemAmigavel(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '');
  if (text.contains('clientConfigurationError') ||
      text.contains('serverClientId')) {
    return 'A conexão com o Google ainda não foi configurada neste APK. Configure o login do Google e gere o app novamente.';
  }
  if (text.contains('SocketException') || text.contains('Failed host lookup')) {
    return 'Não foi possível conectar. Verifique sua internet e tente novamente.';
  }
  return text;
}

IconData _iconePorMime(String mimeType) {
  if (mimeType.contains('folder')) return Icons.folder;
  if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
  if (mimeType.contains('image')) return Icons.image;
  if (mimeType.contains('spreadsheet')) return Icons.table_chart;
  if (mimeType.contains('presentation')) return Icons.slideshow;
  if (mimeType.contains('document')) return Icons.description;
  return Icons.insert_drive_file;
}

String _formatarData(DateTime date) {
  String dois(int value) => value.toString().padLeft(2, '0');
  return '${dois(date.day)}/${dois(date.month)}/${date.year}';
}
