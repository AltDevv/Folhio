import 'package:flutter/material.dart';
import 'dart:ui';
import 'service/observabilidade_service.dart';

import 'controller/settings/aparencia_controller.dart';
import 'app/folhio_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (detalhes) {
    FlutterError.presentError(detalhes);
    ObservabilidadeService.registrar(
      'app.interface.erro',
      'O aplicativo encontrou uma falha ao atualizar a interface.',
      nivel: 'ERRO',
      detalhes: {
        'classeErro': detalhes.exception.runtimeType.toString(),
        'biblioteca': detalhes.library,
        'local': detalhes.stack?.toString().split('\n').take(6).join('\n'),
      },
    );
  };
  PlatformDispatcher.instance.onError = (erro, pilha) {
    ObservabilidadeService.registrar(
      'app.execucao.erro',
      'Uma operacao assincrona do aplicativo falhou.',
      nivel: 'ERRO',
      detalhes: {
        'classeErro': erro.runtimeType.toString(),
        'local': pilha.toString().split('\n').take(6).join('\n'),
      },
    );
    return false;
  };
  await AparenciaController.instance.carregar();
  runApp(const FolhioApp());
  ObservabilidadeService.registrar(
    'app.iniciado',
    'O aplicativo foi iniciado.',
  );
}
