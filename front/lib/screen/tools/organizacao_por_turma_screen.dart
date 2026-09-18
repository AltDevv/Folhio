part of 'tools_flows_screen.dart';

class OrganizacaoPorTurmaScreen extends StatefulWidget {
  const OrganizacaoPorTurmaScreen({super.key});

  @override
  State<OrganizacaoPorTurmaScreen> createState() => _OrganizacaoPorTurmaScreenState();
}

class _OrganizacaoPorTurmaScreenState extends State<OrganizacaoPorTurmaScreen> {
  int _modeIndex = 0;
  bool _createMissingFolders = true;

  @override
  Widget build(BuildContext context) {
    return FolhioScaffold(
      title: 'Organizar por turma',
      currentIndex: 3,
      showBack: true,
      body: FolhioCorpoPagina(
        children: [
          const _ArquivosSelecionadosCard(
            count: 28,
            detail: 'Arquivos da pasta Downloads',
          ),
          const TituloSecao('Organizar por'),
          SeletorChip(
            labels: const ['Turma', 'Disciplina', 'Bimestre'],
            selectedIndex: _modeIndex,
            onSelected: (index) => setState(() => _modeIndex = index),
          ),
          const SizedBox(height: 14),
          _LinhaAlternancia(
            title: 'Criar pastas faltantes',
            subtitle: 'Ex: 8º A, 8º B, 7º A',
            value: _createMissingFolders,
            onChanged: (value) => setState(() => _createMissingFolders = value),
          ),
          const SizedBox(height: 14),
          const _PreviaBox(
            title: 'Prévia das pastas',
            lines: [
              '8º A / Prova_Mat_8A.pdf',
              '8º B / Atividade_Port_8B.docx',
              '7º A / Gabarito_Cie_7A.pdf',
            ],
          ),
          const SizedBox(height: 14),
          const AcaoPrincipalButton(
            label: 'Organizar arquivos',
            icon: Icons.folder_open,
          ),
        ],
      ),
    );
  }
}
