import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:folhio/style/estilo_folhio.dart';
import 'package:folhio/screen/ai/ia_screen.dart';
import 'package:folhio/screen/library/meus_arquivos_screen.dart';
import 'package:folhio/screen/create/detalhes_modelo_screen.dart';

void main() {
  testWidgets('mostra detalhes e exemplo de visualizacao do modelo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EstiloFolhio.tema(
          brightness: Brightness.light,
          accentColor: CoresFolhio.green,
        ),
        home: const DetalhesModeloScreen(
          template: DetalhesModelo(
            id: 'atividade-simples',
            title: 'Atividade simples',
            category: 'Atividades',
            description: 'Modelo de exemplo.',
            access: 'Grátis',
            icon: Icons.assignment_outlined,
            color: CoresFolhio.green,
          ),
        ),
      ),
    );

    expect(find.text('Atividade simples'), findsWidgets);
    expect(find.text('EXEMPLO DE VISUALIZAÇÃO'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sobre este modelo'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sobre este modelo'), findsOneWidget);
    expect(find.text('Modelo disponível em breve'), findsOneWidget);
  });

  testWidgets('destaca quando gerar material esta inativo no tema claro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EstiloFolhio.tema(
          brightness: Brightness.light,
          accentColor: CoresFolhio.green,
        ),
        home: const IaScreen(),
      ),
    );

    BoxDecoration decoracaoBotao() {
      final button = tester.widget<Container>(
        find.byKey(const Key('generate-material-button')),
      );
      return button.decoration! as BoxDecoration;
    }

    expect(decoracaoBotao().color, const Color(0xFFD5DAD8));

    await tester.enterText(
      find.byType(TextField).first,
      'Frações equivalentes',
    );
    await tester.pump();

    expect(decoracaoBotao().color, CoresFolhio.green);
  });

  testWidgets('biblioteca mostra modelos sem tela vazia', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EstiloFolhio.tema(
          brightness: Brightness.dark,
          accentColor: CoresFolhio.green,
        ),
        home: const MeusArquivosScreen(),
      ),
    );

    expect(find.text('Biblioteca'), findsWidgets);
    expect(find.text('Modelos'), findsWidgets);
    expect(find.text('Modelos em destaque'), findsOneWidget);
    expect(find.text('Todos'), findsWidgets);
  });

  testWidgets('biblioteca mostra busca flutuante ao rolar modelos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EstiloFolhio.tema(
          brightness: Brightness.dark,
          accentColor: CoresFolhio.green,
        ),
        home: const MeusArquivosScreen(),
      ),
    );

    final floatingSearch = find.byKey(
      const Key('library-floating-template-search'),
    );
    expect(tester.widget<AnimatedOpacity>(floatingSearch).opacity, 0);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(tester.widget<AnimatedOpacity>(floatingSearch).opacity, 1);
  });
}
