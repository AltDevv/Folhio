import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../controller/google_integrations/integracoes_google_controller.dart';
import '../../repository/local/persistencia_local_repository.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';
import '../google_integrations/google_integrations_screen.dart';

class SegurancaBackupScreen extends StatefulWidget {
  const SegurancaBackupScreen({super.key});

  @override
  State<SegurancaBackupScreen> createState() => _SegurancaBackupScreenState();
}

class _SegurancaBackupScreenState extends State<SegurancaBackupScreen> {
  final PersistenciaLocalRepository _local = PersistenciaLocalRepository.instance;
  final IntegracoesGoogleController _google = IntegracoesGoogleController();
  bool _automaticBackup = false;
  bool _wifiOnlyBackup = true;
  bool _busy = false;
  String _backupTarget = 'google_drive';
  DateTime? _lastBackup;
  String? _lastBackupPath;
  String? _googleDriveEmail;
  String? _message;
  String? _currentStep;

  @override
  void initState() {
    super.initState();
    _carregarEstadoBackup();
  }

  Future<void> _carregarEstadoBackup() async {
    final latest = await _local.ultimoBackup();
    final automatic = await _local.automaticBackupEnabled;
    final wifiOnly = await _local.configuracao('backup.wifiOnly');
    final target = await _local.configuracao('backup.target');
    final savedGoogleEmail = await _local.configuracao('google.drive.email');
    String? googleAccountEmail;
    try {
      await _google.inicializar();
      googleAccountEmail = _google.currentAccount?.email;
    } catch (_) {
      googleAccountEmail = null;
    }
    if (googleAccountEmail != null) {
      await _salvarConexaoGoogleDrive(googleAccountEmail);
    }
    final normalizedTarget = _normalizarDestinoBackup(target);
    if (target != normalizedTarget) {
      await _local.definirConfiguracao('backup.target', normalizedTarget);
    }
    if (!mounted) return;
    setState(() {
      _automaticBackup = automatic;
      _wifiOnlyBackup = wifiOnly != 'false';
      _backupTarget = normalizedTarget;
      _lastBackup = latest?.completedAt ?? latest?.createdAt;
      _lastBackupPath = latest?.filePath;
      _googleDriveEmail =
          googleAccountEmail ??
          (savedGoogleEmail?.trim().isNotEmpty == true
              ? savedGoogleEmail!.trim()
              : null);
    });
  }

  Future<void> _selecionarDestinoBackup(String target) async {
    await _local.definirConfiguracao('backup.target', target);
    if (!mounted) return;
    setState(() {
      _backupTarget = target;
      _message = switch (target) {
        'google_drive' =>
          _googleDriveEmail == null
              ? 'Google Drive selecionado. Conecte sua conta para usar backup na nuvem.'
              : 'Google Drive selecionado e conectado.',
        _ =>
          'OneDrive selecionado. A conexão será habilitada em uma próxima versão.',
      };
    });
  }

  String _normalizarDestinoBackup(String? target) {
    return target == 'onedrive' ? 'onedrive' : 'google_drive';
  }

  Future<void> _salvarConexaoGoogleDrive(String email) async {
    await _local.definirConfiguracao('google.drive.connected', 'true');
    await _local.definirConfiguracao('google.drive.email', email);
  }

  Future<void> _abrirConfiguracoesGoogleDrive() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const IntegracaoGoogleDriveScreen(),
      ),
    );
    await _carregarEstadoBackup();
  }

  Future<void> _conectarGoogleDrive() async {
    setState(() {
      _busy = true;
      _currentStep = 'Conectando ao Google Drive';
      _message = null;
    });

    try {
      await _google.inicializar();
      final account = _google.currentAccount ?? await _google.iniciarSessao();
      await _salvarConexaoGoogleDrive(account.email);
      await _local.definirConfiguracao('backup.target', 'google_drive');
      if (!mounted) return;
      setState(() {
        _backupTarget = 'google_drive';
        _googleDriveEmail = account.email;
        _message =
            'Google Drive conectado. Seus backups podem ser enviados para esta conta.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _message = 'Não foi possível conectar ao Google Drive: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _currentStep = null;
        });
      }
    }
  }

  Future<void> _executarBackup() async {
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      for (final step in const [
        'Organizando dados',
        'Gerando exportação protegida',
        'Verificando backup',
      ]) {
        if (!mounted) return;
        setState(() => _currentStep = step);
        await Future<void>.delayed(const Duration(milliseconds: 220));
      }

      final file = await _local.criarBackupManual();
      if (!mounted) return;
      setState(() {
        _lastBackup = DateTime.now();
        _lastBackupPath = file.path;
      });
      if (_backupTarget == 'google_drive') {
        if (!mounted) return;
        setState(() => _currentStep = 'Enviando para o Google Drive');
        await _google.inicializar();
        final account = _google.currentAccount ?? await _google.iniciarSessao();
        await _salvarConexaoGoogleDrive(account.email);
        if (mounted) setState(() => _googleDriveEmail = account.email);
        await _google.enviarArquivoParaDrive(file, folderName: 'Folhio Backups');
      }
      if (!mounted) return;
      setState(() {
        _message = switch (_backupTarget) {
          'google_drive' => 'Backup concluído e enviado para o Google Drive.',
          'onedrive' =>
            'Exportação protegida concluída. Envio ao OneDrive ainda ficará para a próxima etapa.',
          _ => 'Backup concluído e enviado para o Google Drive.',
        };
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _backupTarget == 'google_drive'
            ? 'A exportação foi preparada, mas não foi possível enviar ao Google Drive: $error'
            : 'A exportação foi preparada, mas não foi possível enviar ao OneDrive nesta versão.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _currentStep = null;
        });
      }
    }
  }

  Future<void> _restaurarBackup() async {
    final confirmed = await _confirmar(
      title: 'Restaurar backup?',
      message:
          'Os dados atuais podem ser substituídos pelos dados do backup. Deseja continuar?',
      label: 'Restaurar',
    );
    if (confirmed != true) return;

    final path = _lastBackupPath;
    if (path == null || path.isEmpty || !await File(path).exists()) {
      setState(
        () => _message = 'Não encontramos uma exportação salva neste aparelho.',
      );
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
      _currentStep = 'Restaurando dados';
    });

    try {
      await _local.restaurarArquivoBackup(File(path));
      if (!mounted) return;
      setState(() => _message = 'Backup restaurado. Revise seus arquivos.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Não foi possível restaurar este backup.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _currentStep = null;
        });
      }
    }
  }

  Future<void> _importarBackup() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['folhio-backup', 'json'],
    );
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;

    final confirmed = await _confirmar(
      title: 'Importar backup?',
      message:
          'Os dados atuais podem ser substituídos pelo arquivo importado. Faça backup antes de continuar.',
      label: 'Importar',
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _message = null;
      _currentStep = 'Verificando backup importado';
    });

    try {
      await _local.restaurarArquivoBackup(File(path));
      if (!mounted) return;
      setState(() => _message = 'Dados restaurados com sucesso.');
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _message =
            'Não foi possível importar este backup. Verifique o arquivo e tente novamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _currentStep = null;
        });
      }
    }
  }

  Future<bool?> _confirmar({
    required String title,
    required String message,
    required String label,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastBackup = _lastBackup;
    return FolhioScaffold(
      title: 'Backup e segurança',
      currentIndex: 0,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          FolhioCard(
            borderColor: lastBackup == null
                ? CoresFolhio.borderSoft
                : CoresFolhio.green,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconeArredondado(
                      icon: lastBackup == null
                          ? Icons.shield_outlined
                          : Icons.verified_user_outlined,
                      color: lastBackup == null
                          ? CoresFolhio.orange
                          : CoresFolhio.green,
                      backgroundColor: CoresFolhio.surfaceSoft,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastBackup == null
                                ? 'Backup ainda não feito'
                                : 'Backup ativo',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastBackup == null
                                ? 'Último backup: nunca'
                                : 'Último backup: ${_dataRotulo(lastBackup)}',
                            style: const TextStyle(
                              color: CoresFolhio.muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Destino: ${_rotuloDestino(_backupTarget)}',
                            style: const TextStyle(
                              color: CoresFolhio.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'A nuvem é o armazenamento principal. Esta área exporta uma cópia protegida para você guardar ou restaurar depois.',
                  style: TextStyle(color: CoresFolhio.muted, height: 1.35),
                ),
                const SizedBox(height: 10),
                _BackupSwitch(
                  title: 'Backup automático na nuvem',
                  value: _automaticBackup,
                  enabled: !_busy,
                  onChanged: (value) async {
                    await _local.definirBackupAutomaticoHabilitado(value);
                    if (mounted) setState(() => _automaticBackup = value);
                  },
                ),
                _BackupSwitch(
                  title: 'Sincronizar apenas via Wi-Fi',
                  value: _wifiOnlyBackup,
                  enabled: !_busy,
                  onChanged: (value) async {
                    await _local.definirConfiguracao(
                      'backup.wifiOnly',
                      value.toString(),
                    );
                    if (mounted) setState(() => _wifiOnlyBackup = value);
                  },
                ),
              ],
            ),
          ),
          const TituloSecao('Destino do backup'),
          _DestinoBackupTile(
            icon: Icons.drive_folder_upload,
            title: 'Google Drive',
            subtitle: _googleDriveEmail == null
                ? 'Usar sua conta Google como destino de backup.'
                : 'Conectado: $_googleDriveEmail',
            selected: _backupTarget == 'google_drive',
            onTap: () => _selecionarDestinoBackup('google_drive'),
            actionLabel: _googleDriveEmail == null ? 'Conectar' : 'Gerenciar',
            onAction: _busy
                ? null
                : _googleDriveEmail == null
                ? _conectarGoogleDrive
                : _abrirConfiguracoesGoogleDrive,
          ),
          _DestinoBackupTile(
            icon: Icons.cloud_outlined,
            title: 'OneDrive',
            subtitle: 'Destino preparado para ativação futura.',
            selected: _backupTarget == 'onedrive',
            onTap: () => _selecionarDestinoBackup('onedrive'),
            actionLabel: 'Em breve',
          ),
          if (_currentStep != null)
            FolhioCard(
              color: CoresFolhio.surfaceSoft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_currentStep!)),
                ],
              ),
            ),
          if (_message != null)
            FolhioCard(
              color: CoresFolhio.surfaceSoft,
              child: Text(
                _message!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          const TituloSecao('Ações'),
          FilledButton.icon(
            onPressed: _busy ? null : _executarBackup,
            icon: const Icon(Icons.backup_outlined),
            label: const Text('Fazer backup agora'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _restaurarBackup,
            icon: const Icon(Icons.restore_outlined),
            label: const Text('Restaurar último backup'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _importarBackup,
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Importar backup'),
          ),
          const TituloSecao('Privacidade'),
          const FolhioCard(
            child: Text(
              'Seus conteúdos ficam vinculados à sua conta na nuvem. Preferências e proteção do dispositivo continuam locais.',
              style: TextStyle(color: CoresFolhio.muted, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  String _rotuloDestino(String target) {
    return switch (target) {
      'google_drive' => 'Google Drive',
      'onedrive' => 'OneDrive',
      _ => 'Google Drive',
    };
  }

  String _dataRotulo(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _DestinoBackupTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _DestinoBackupTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return FolhioCard(
      borderColor: selected ? CoresFolhio.green : CoresFolhio.borderSoft,
      onTap: onTap,
      child: Row(
        children: [
          IconeArredondado(
            icon: selected ? Icons.check_circle : icon,
            color: selected ? CoresFolhio.green : CoresFolhio.blue,
            backgroundColor: CoresFolhio.surfaceSoft,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: CoresFolhio.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _BackupSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _BackupSwitch({
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
