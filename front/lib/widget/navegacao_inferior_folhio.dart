import 'package:flutter/material.dart';
import '../style/estilo_folhio.dart';

class NavegacaoInferiorFolhio extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NavegacaoInferiorFolhio({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedFontSize: EstiloFolhio.navigationFontSize,
      unselectedFontSize: EstiloFolhio.navigationFontSize,
      iconSize: EstiloFolhio.navigationIconSize,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome_outlined),
          activeIcon: Icon(Icons.auto_awesome),
          label: 'Criar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_library_outlined),
          activeIcon: Icon(Icons.local_library),
          label: 'Biblioteca',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.handyman_outlined),
          activeIcon: Icon(Icons.handyman),
          label: 'Ferramentas',
        ),
      ],
    );
  }
}
