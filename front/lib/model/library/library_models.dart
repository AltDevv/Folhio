import '../../service/api/folhio_api_gateway.dart';

const String libraryFavoriteTag = 'Favoritos';
const String libraryRootMaterialsLabel = 'Meus materiais';

class RetratoConteudoBiblioteca {
  final List<FolhioPastaBiblioteca> folders;
  final List<FolhioArquivoBiblioteca> files;
  final List<FolhioArquivoBiblioteca> favoriteFiles;
  final Set<String> favoriteFileIds;
  final List<String> availableFolderTags;
  final Map<String, List<String>> folderTagsById;

  const RetratoConteudoBiblioteca({
    this.folders = const [],
    this.files = const [],
    this.favoriteFiles = const [],
    this.favoriteFileIds = const <String>{},
    this.availableFolderTags = const [],
    this.folderTagsById = const {},
  });
}

class EntradaPastaBiblioteca {
  final String name;
  final String tags;
  final String notes;
  final String links;

  const EntradaPastaBiblioteca({
    required this.name,
    this.tags = '',
    this.notes = '',
    this.links = '',
  });
}

class OpcaoDestinoPastaBiblioteca {
  final FolhioPastaBiblioteca folder;
  final String label;

  const OpcaoDestinoPastaBiblioteca({required this.folder, required this.label});
}

class BibliotecaState {
  final List<FolhioPastaBiblioteca> folders;
  final List<FolhioArquivoBiblioteca> files;
  final List<FolhioArquivoBiblioteca> favoriteFiles;
  final Set<String> favoriteFileIds;
  final List<String> availableFolderTags;
  final Map<String, List<String>> folderTagsById;
  final bool loading;
  final String? message;

  const BibliotecaState({
    this.folders = const [],
    this.files = const [],
    this.favoriteFiles = const [],
    this.favoriteFileIds = const <String>{},
    this.availableFolderTags = const [],
    this.folderTagsById = const {},
    this.loading = true,
    this.message,
  });

  BibliotecaState copiarCom({
    List<FolhioPastaBiblioteca>? folders,
    List<FolhioArquivoBiblioteca>? files,
    List<FolhioArquivoBiblioteca>? favoriteFiles,
    Set<String>? favoriteFileIds,
    List<String>? availableFolderTags,
    Map<String, List<String>>? folderTagsById,
    bool? loading,
    String? message,
    bool clearMessage = false,
  }) {
    return BibliotecaState(
      folders: folders ?? this.folders,
      files: files ?? this.files,
      favoriteFiles: favoriteFiles ?? this.favoriteFiles,
      favoriteFileIds: favoriteFileIds ?? this.favoriteFileIds,
      availableFolderTags: availableFolderTags ?? this.availableFolderTags,
      folderTagsById: folderTagsById ?? this.folderTagsById,
      loading: loading ?? this.loading,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
