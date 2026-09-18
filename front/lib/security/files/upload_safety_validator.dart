part of '../../service/api/folhio_api_gateway.dart';

void _garantirPermitidoEnvioTamanho(int sizeBytes) {
  if (sizeBytes <= 0) {
    throw const FolhioExibicaoUsuarioException(
      'O arquivo está vazio. Escolha outro arquivo.',
    );
  }
  if (!EnvioPolicy.permiteTamanho(sizeBytes)) {
    throw FolhioExibicaoUsuarioException(_mensagemLimiteTamanhoEnvio());
  }
}

String _mensagemLimiteTamanhoEnvio() {
  return 'O arquivo precisa ter menos de ${FolhioApiGateway.maxUploadMegabytes} MiB. '
      'Escolha um arquivo menor para enviar.';
}

Future<void> _validarSegurancaArquivoEnvio(
  File file,
  String fileName,
  int fileSize,
) async {
  // A varredura de segurança de arquivos fica a cargo de um scanner dedicado
}

String _extensaoArquivoLocal(String fileName) {
  if (!fileName.contains('.')) return '';
  final extension = fileName
      .split('.')
      .last
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]'), '');
  return extension.isEmpty ? '' : '.$extension';
}

String _nomeSeguroArquivoBiblioteca(String fileName) {
  final cleaned = fileName
      .replaceAll(RegExp(r'[\x00-\x1F\\/:*?"<>|]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') return '';
  return cleaned.length <= 120 ? cleaned : cleaned.substring(0, 120).trim();
}

String _nomeArquivoComExtensaoDetectada(String fileName, List<int> bytes) {
  final safeName = _nomeSeguroArquivoBiblioteca(fileName);
  final baseName = safeName.isEmpty ? 'arquivo' : safeName;
  final currentExtension = _extensaoArquivoLocal(baseName);
  final detected = _detectarExtensaoArquivo(bytes);
  if (currentExtension.isNotEmpty &&
      _tipoConteudoPorNomeArquivo(baseName) != 'application/octet-stream' &&
      (detected == null ||
          _extensaoCorrespondeDetectada(currentExtension.substring(1), detected))) {
    return baseName;
  }

  if (detected == null) return baseName;
  return '$baseName.$detected';
}

Future<String> _nomeArquivoComExtensaoDetectadaDoArquivo(
  String fileName,
  File file,
) async {
  final safeName = _nomeSeguroArquivoBiblioteca(fileName);
  final fallback = safeName.isEmpty ? 'arquivo' : safeName;
  try {
    final header = await file
        .openRead(0, 32)
        .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk))
        .timeout(const Duration(seconds: 3));
    return _nomeArquivoComExtensaoDetectada(fallback, header);
  } catch (_) {
    return fallback;
  }
}

bool _extensaoCorrespondeDetectada(String extension, String detected) {
  if (extension == detected) return true;
  const equivalentGroups = [
    {'jpg', 'jpeg'},
    {'mp4', 'm4v', 'mov', '3gp'},
    {'webm', 'mkv'},
    {'doc', 'ppt', 'xls'},
    {'docx', 'pptx', 'xlsx'},
    {'mpeg', 'mpg', 'mts', 'm2ts', 'ts'},
  ];
  return equivalentGroups.any(
    (group) => group.contains(extension) && group.contains(detected),
  );
}

String? _detectarExtensaoArquivo(List<int> bytes) {
  if (_comecaComAscii(bytes, '%PDF')) return 'pdf';
  if (_comecaCom(bytes, const [0x89, 0x50, 0x4E, 0x47])) return 'png';
  if (_comecaCom(bytes, const [0xFF, 0xD8, 0xFF])) return 'jpg';
  if (_comecaCom(bytes, const [0xD0, 0xCF, 0x11, 0xE0])) return 'doc';
  if (_comecaComAscii(bytes, 'PK')) return 'docx';
  if (_comecaCom(bytes, const [0x1A, 0x45, 0xDF, 0xA3])) return 'webm';
  if (_temAsciiEm(bytes, 4, 'ftyp')) {
    final brand = _asciiTrecho(bytes, 8, 12);
    if (brand.startsWith('M4A')) return null;
    if (brand.startsWith('qt')) return 'mov';
    if (brand.startsWith('3g')) return '3gp';
    return 'mp4';
  }
  if (_comecaComAscii(bytes, 'RIFF')) {
    if (_temAsciiEm(bytes, 8, 'AVI ')) return 'avi';
  }
  if (_comecaCom(bytes, const [0x30, 0x26, 0xB2, 0x75])) return 'wmv';
  if (_comecaComAscii(bytes, 'FLV')) return 'flv';
  if (_comecaCom(bytes, const [0x00, 0x00, 0x01])) return 'mpeg';
  if (_comecaCom(bytes, const [0x47])) return 'ts';
  return null;
}

bool _comecaCom(List<int> bytes, List<int> signature) {
  if (bytes.length < signature.length) return false;
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) return false;
  }
  return true;
}

bool _comecaComAscii(List<int> bytes, String value) {
  return _temAsciiEm(bytes, 0, value);
}

bool _temAsciiEm(List<int> bytes, int offset, String value) {
  final codes = value.codeUnits;
  if (bytes.length < offset + codes.length) return false;
  for (var index = 0; index < codes.length; index++) {
    if (bytes[offset + index] != codes[index]) return false;
  }
  return true;
}

String _asciiTrecho(List<int> bytes, int start, int end) {
  if (bytes.length <= start) return '';
  final safeEnd = min(bytes.length, end);
  return String.fromCharCodes(bytes.sublist(start, safeEnd));
}

String _tipoConteudoPorNomeArquivo(String fileName) {
  final extension = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
  return switch (extension) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'ppt' => 'application/vnd.ms-powerpoint',
    'pptx' =>
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'webm' => 'video/webm',
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime',
    'm4v' => 'video/x-m4v',
    'avi' => 'video/x-msvideo',
    'mkv' => 'video/x-matroska',
    '3gp' => 'video/3gpp',
    'mpeg' || 'mpg' => 'video/mpeg',
    'mts' || 'm2ts' => 'video/mp2t',
    'ts' => 'video/mp2t',
    'wmv' => 'video/x-ms-wmv',
    'flv' => 'video/x-flv',
    _ => 'application/octet-stream',
  };
}
