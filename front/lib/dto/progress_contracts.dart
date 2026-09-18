part of '../service/api/folhio_api_gateway.dart';

class FolhioProgressoOperacao {
  final double progress;
  final String message;

  const FolhioProgressoOperacao({
    required this.progress,
    required this.message,
  });

  factory FolhioProgressoOperacao.deJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'];
    return FolhioProgressoOperacao(
      progress: rawProgress is num
          ? rawProgress.toDouble().clamp(0, 1).toDouble()
          : 0,
      message: json['message']?.toString() ?? 'Processando',
    );
  }
}
