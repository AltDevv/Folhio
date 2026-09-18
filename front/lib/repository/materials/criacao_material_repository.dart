import '../../service/api/folhio_api_gateway.dart';

abstract class CriacaoMaterialRepository {
  Future<FolhioCatalogoMateriais> catalogo({String discipline = ''});

  Future<List<FolhioModeloMaterial>> modelos({String materialType = ''});

  Future<FolhioMaterialGerado> montar(FolhioGeracaoMaterialRequest request);

  Future<List<FolhioResumoMaterialGerado>> gerados({int limit = 20});

  void fechar();
}

class FolhioCriacaoMaterialRepository implements CriacaoMaterialRepository {
  final FolhioApiGateway api;
  final bool ownsApi;

  FolhioCriacaoMaterialRepository({FolhioApiGateway? api})
    : api = api ?? FolhioApiGateway(),
      ownsApi = api == null;

  @override
  Future<FolhioCatalogoMateriais> catalogo({String discipline = ''}) {
    return api.catalogoMateriais(discipline: discipline);
  }

  @override
  Future<List<FolhioModeloMaterial>> modelos({String materialType = ''}) {
    return api.modelosMateriais(materialType: materialType);
  }

  @override
  Future<FolhioMaterialGerado> montar(FolhioGeracaoMaterialRequest request) {
    return api.montarMaterial(request);
  }

  @override
  Future<List<FolhioResumoMaterialGerado>> gerados({int limit = 20}) {
    return api.materiaisGerados(limit: limit);
  }

  @override
  void fechar() {
    if (ownsApi) api.fechar();
  }
}
