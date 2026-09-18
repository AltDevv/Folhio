part of 'google_integrations_screen.dart';

class _OpcaoPastaDrive {
  final String value;
  final String label;
  final String? driveFolderName;

  const _OpcaoPastaDrive({
    required this.value,
    required this.label,
    required this.driveFolderName,
  });

  const _OpcaoPastaDrive.nenhum()
    : value = '',
      label = 'Nenhuma pasta',
      driveFolderName = null;
}
