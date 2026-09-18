part of '../../../folhio_api_gateway.dart';

class _FolhioArquivoGeradoIo {
  static Future<String> armazenarArquivoGerado({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final safeName = nomeTemporarioSeguro(fileName);
    final tempFile = File('${tempDir.path}/$safeName');
    await tempFile.writeAsBytes(bytes, flush: true);
    return tempFile.path;
  }

  static Future<File?> arquivoLocalExistente(FolhioArquivoGerado file) async {
    final localPath = file.localPath;
    if (localPath == null || localPath.isEmpty) {
      return null;
    }
    final localFile = File(localPath);
    return await localFile.exists() ? localFile : null;
  }

  static Future<FolhioArquivoGerado> _comBytes(
    FolhioArquivoGerado file,
  ) async {
    if (file.bytes.isNotEmpty) {
      return file;
    }

    final api = FolhioApiGateway();
    try {
      return await api.carregarBytesArquivoGerado(file);
    } finally {
      api.fechar();
    }
  }

  static Future<String?> escolherOndeSalvar(FolhioArquivoGerado file) async {
    final readyFile = await _comBytes(file);
    return FilePicker.platform.saveFile(
      fileName: readyFile.fileName,
      bytes: readyFile.bytes,
    );
  }

  static Future<String> salvarEmDownloads(FolhioArquivoGerado file) async {
    final downloads = Directory('/storage/emulated/0/Download');
    try {
      final localFile = await arquivoLocalExistente(file);
      final targetDir = await downloads.exists()
          ? downloads
          : await getApplicationDocumentsDirectory();
      final target = File('${targetDir.path}/${nomeTemporarioSeguro(file.fileName)}');
      if (localFile != null) {
        await localFile.copy(target.path);
      } else {
        final readyFile = await _comBytes(file);
        await target.writeAsBytes(readyFile.bytes, flush: true);
      }
      return target.path;
    } catch (_) {
      final path = await escolherOndeSalvar(file);
      return path ?? 'salvamento cancelado';
    }
  }

  static Future<void> compartilharArquivoGerado(FolhioArquivoGerado file) async {
    final localFile = await arquivoLocalExistente(file);
    final readyFile = localFile == null ? await _comBytes(file) : file;
    final path = localFile?.path ?? readyFile.localPath;
    final sharePath =
        path ??
        await armazenarArquivoGerado(
          fileName: readyFile.fileName,
          bytes: readyFile.bytes,
        );
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            sharePath,
            mimeType: readyFile.mimeType,
            name: readyFile.fileName,
          ),
        ],
      ),
    );
  }

  static void limparArquivoGerado() {
    FolhioApiGateway.generatedFile.value = null;
    FolhioApiGateway.progress.value = null;
  }

  static String nomeTemporarioSeguro(String fileName) {
    final clean = fileName.trim().isEmpty ? 'folhio-resultado' : fileName;
    return clean.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
