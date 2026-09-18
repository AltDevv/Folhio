import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../style/estilo_folhio.dart';
import '../../service/api/folhio_api_gateway.dart';
import '../../controller/tools/ferramentas_controller.dart';
import '../../database/folhio_database.dart';
import '../../repository/local/persistencia_local_repository.dart';
import '../../widget/actions.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';

part '../../widget/tools/tools_flow_widgets.dart';
part 'lista_alunos_screen.dart';
part 'lista_presenca_screen.dart';
part 'planilha_notas_screen.dart';
part 'comunicado_individual_screen.dart';
part 'renomeacao_lote_screen.dart';
part 'organizacao_por_turma_screen.dart';
part 'carimbo_pdf_screen.dart';

void _mostrarResultadoFerramenta(BuildContext context, String message, String? fileName) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(fileName == null ? message : '$message Arquivo: $fileName'),
    ),
  );
}
