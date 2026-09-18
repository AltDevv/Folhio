part of '../service/api/folhio_api_gateway.dart';

class FolhioSemInternetException implements Exception {
  const FolhioSemInternetException();
}

class FolhioConfiguracaoException implements Exception {
  final String message;

  const FolhioConfiguracaoException(this.message);

  @override
  String toString() => message;
}

class FolhioApiException implements Exception {
  final int statusCode;
  final String message;

  const FolhioApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'FolhioApiException($statusCode): $message';
}

class FolhioExibicaoUsuarioException implements Exception {
  final String message;

  const FolhioExibicaoUsuarioException(this.message);

  @override
  String toString() => message;
}

class FolhioConflitoBibliotecaException implements Exception {
  final String rawMessage;

  const FolhioConflitoBibliotecaException(this.rawMessage);
}
