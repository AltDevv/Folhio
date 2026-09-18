part of '../service/api/folhio_api_gateway.dart';

class FolhioEventoRegistroClienteRequest {
  final String level;
  final String category;
  final String event;
  final String message;
  final String? requestId;
  final Map<String, Object?> details;

  const FolhioEventoRegistroClienteRequest({
    required this.level,
    required this.category,
    required this.event,
    required this.message,
    this.requestId,
    this.details = const {},
  });

  Map<String, Object?> toJson() {
    return {
      'nivel': level,
      'categoria': category,
      'evento': event,
      'mensagem': message,
      'requestId': requestId,
      'detalhes': details,
    };
  }
}
