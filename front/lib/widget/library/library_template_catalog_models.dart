part of '../../screen/library/meus_arquivos_screen.dart';

class _DadosSecaoCatalogoModelos {
  final String title;
  final List<_ItemCatalogoModelos> items;

  const _DadosSecaoCatalogoModelos(this.title, this.items);
}

class _ItemListaCatalogoModelos {
  final String section;
  final _ItemCatalogoModelos item;

  const _ItemListaCatalogoModelos(this.section, this.item);
}

class _ItemCatalogoModelos {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String access;
  final List<String> tags;

  const _ItemCatalogoModelos(
    this.icon,
    this.title,
    this.subtitle,
    this.color,
    this.access,
    this.tags,
  );

  String idPara(String category) {
    return '$category-$title'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  DetalhesModelo detalhes(String category) {
    return DetalhesModelo(
      id: idPara(category),
      title: title,
      category: category,
      description:
          '$subtitle. Este modelo de $category oferece uma estrutura pronta para adaptar ao conteúdo da turma. Quando o material for cadastrado, a visualização completa aparecerá nesta página.',
      access: access == 'Gratis' ? 'Grátis' : access,
      icon: icon,
      color: color,
    );
  }
}

bool _modeloCorrespondeFiltros({
  required String section,
  required _ItemCatalogoModelos item,
  required String query,
  required String? type,
  required String? access,
  required Set<String> tags,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final searchable =
      '$section ${item.title} ${item.subtitle} ${item.access} ${item.tags.join(' ')}'
          .toLowerCase();
  if (normalizedQuery.isNotEmpty && !searchable.contains(normalizedQuery)) {
    return false;
  }
  if (type != null && _tipoModeloPara(section, item) != type) {
    return false;
  }
  if (access != null && _normalizarAcessoModelo(item.access) != access) {
    return false;
  }
  for (final tag in tags) {
    if (!searchable.contains(tag.toLowerCase())) {
      return false;
    }
  }
  return true;
}

String _tipoModeloPara(String section, _ItemCatalogoModelos item) {
  final lower = '$section ${item.title} ${item.subtitle} ${item.tags.join(' ')}'
      .toLowerCase();
  if (lower.contains('simulado') || lower.contains('enem')) return 'Simulados';
  if (lower.contains('revis') || lower.contains('recuper')) {
    return 'Revisões';
  }
  if (lower.contains('atividade') || lower.contains('exerc')) {
    return 'Atividades';
  }
  if (lower.contains('prova') ||
      lower.contains('gabarito') ||
      lower.contains('bimestral')) {
    return 'Provas';
  }
  return 'Planos';
}

String _normalizarAcessoModelo(String access) {
  return access == 'Grátis' || access == 'Gratis' ? 'Gratis' : access;
}

String _rotuloAcessoModelo(String access) {
  return _normalizarAcessoModelo(access) == 'Gratis' ? 'Grátis' : access;
}
