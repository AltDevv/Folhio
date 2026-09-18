import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folhio/config/rotas_folhio.dart';
import 'package:folhio/style/estilo_folhio.dart';
import 'package:folhio/widget/folhio_scaffold.dart';

void main() {
  for (final width in [360.0, 1280.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('navegacao sem Espacos: $width $brightness', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: EstiloFolhio.tema(brightness: brightness),
            home: const FolhioScaffold(
              title: 'Ferramentas',
              currentIndex: 3,
              body: SizedBox(),
            ),
            routes: {
              RotasFolhio.create: (_) => const Scaffold(body: Text('Criacao')),
            },
          ),
        );
        final nav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(nav.items.length, RotasFolhio.tabs.length);
        expect(nav.items.map((item) => item.label), [
          'Início',
          'Criar',
          'Biblioteca',
          'Ferramentas',
        ]);
        expect(find.text('Espaços'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Criar'));
        await tester.pumpAndSettle();
        expect(find.text('Criacao'), findsOneWidget);
      });
    }
  }
}
