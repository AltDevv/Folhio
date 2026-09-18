part of '../../screen/library/meus_arquivos_screen.dart';

const _templateCatalogSections = [
  _DadosSecaoCatalogoModelos('Atividades', [
    _ItemCatalogoModelos(
      Icons.assignment_outlined,
      'Atividade simples',
      'Pronta para editar',
      CoresFolhio.green,
      'Gratis',
      [],
    ),
    _ItemCatalogoModelos(
      Icons.format_list_numbered,
      'Lista de exercícios',
      'Questões organizadas',
      CoresFolhio.orange,
      'Gratis',
      [],
    ),
    _ItemCatalogoModelos(
      Icons.palette_outlined,
      'Infantil colorida',
      'Mais visual',
      CoresFolhio.violet,
      'Premium',
      ['visual', 'infantil'],
    ),
  ]),
  _DadosSecaoCatalogoModelos('Provas e simulados', [
    _ItemCatalogoModelos(
      Icons.quiz_outlined,
      'Prova com gabarito',
      'Com respostas',
      CoresFolhio.blue,
      'Gratis',
      ['gabarito'],
    ),
    _ItemCatalogoModelos(
      Icons.school_outlined,
      'Simulado ENEM',
      'Modelo objetivo',
      CoresFolhio.coral,
      'Premium',
      ['enem'],
    ),
    _ItemCatalogoModelos(
      Icons.restart_alt,
      'Recuperação',
      'Revisão final',
      CoresFolhio.violet,
      'Gratis',
      [],
    ),
  ]),
  _DadosSecaoCatalogoModelos('Planos e extras', [
    _ItemCatalogoModelos(
      Icons.event_note_outlined,
      'Plano de aula',
      'Etapas e objetivos',
      CoresFolhio.green,
      'Gratis',
      [],
    ),
    _ItemCatalogoModelos(
      Icons.checklist_outlined,
      'Gabarito',
      'Para professor',
      CoresFolhio.blue,
      'Gratis',
      ['gabarito'],
    ),
    _ItemCatalogoModelos(
      Icons.splitscreen,
      'Impressão econômica',
      'Menos páginas',
      CoresFolhio.orange,
      'Gratis',
      ['econômico'],
    ),
  ]),
];

List<String> get _templateCatalogTags {
  final labelsByLower = <String, String>{};
  for (final section in _templateCatalogSections) {
    for (final item in section.items) {
      for (final tag in item.tags) {
        labelsByLower.putIfAbsent(tag.toLowerCase(), () => tag);
      }
    }
  }
  return labelsByLower.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}
