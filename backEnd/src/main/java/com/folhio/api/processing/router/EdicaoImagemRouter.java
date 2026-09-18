package com.folhio.api.processing.router;

import com.folhio.api.dto.action.AcaoRequest;
import com.folhio.api.dto.action.AcaoResponse;
import com.folhio.api.common.util.MapasJson;
import com.folhio.api.processing.conversion.ResultadoConversao;
import com.folhio.api.processing.conversion.EdicaoImagemEngine;
import com.folhio.api.service.ArquivoArmazenadoService;
import com.folhio.api.files.model.ArquivoArmazenado;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class EdicaoImagemRouter {

    private final ArquivoArmazenadoService storageService;
    private final EdicaoImagemEngine imageEditEngine;

    public EdicaoImagemRouter(ArquivoArmazenadoService storageService, EdicaoImagemEngine imageEditEngine) {
        this.storageService = storageService;
        this.imageEditEngine = imageEditEngine;
    }

    public AcaoResponse processar(AcaoRequest request) {
        if (!"visual_image_edit".equals(request.type())) {
            throw new UnsupportedOperationException("Edição de imagem ainda não implementada: " + request.type());
        }

        ArquivoArmazenado input = storageService.buscar(SuporteAcaoRouter.identificadorArquivoObrigatorio(request.payload(), "file"));
        LimitesProcessamentoAcao.validarImagem(input);
        Map<String, Object> visual = MapasJson.filho(request.payload(), "visual");
        ResultadoConversao result = imageEditEngine.editarImagemVisual(
                input,
                MapasJson.inteiro(visual, "quarterTurns", 0),
                MapasJson.decimal(visual, "rotationDegrees", 0),
                MapasJson.booleano(visual, "mirrored", false),
                MapasJson.inteiro(visual, "brightness", 0),
                MapasJson.inteiro(visual, "contrast", 0),
                MapasJson.booleano(visual, "removeBackground", false),
                MapasJson.texto(visual, "cropShape", "basic"),
                MapasJson.filho(visual, "crop"),
                mapearCamadas(visual, "textLayers"),
                camadasImagem(visual),
                mapearCamadas(visual, "marks")
        );

        return AcaoResponse.sucesso(
                request.requestId(),
                result.message(),
                Map.of(
                        "type", request.type(),
                        "engine", "zilch-compatible"
                ),
                SuporteAcaoRouter.arquivoSaida(result.file())
        );
    }

    private List<Map<String, Object>> mapearCamadas(Map<String, Object> source, String key) {
        List<Map<String, Object>> layers = new ArrayList<>();
        for (Object item : MapasJson.listar(source, key)) {
            if (item instanceof Map<?, ?> raw) {
                @SuppressWarnings("unchecked")
                Map<String, Object> layer = (Map<String, Object>) raw;
                layers.add(layer);
            }
        }
        return layers;
    }

    private List<EdicaoImagemEngine.CamadaImagemVisual> camadasImagem(Map<String, Object> visual) {
        List<EdicaoImagemEngine.CamadaImagemVisual> imageLayers = new ArrayList<>();
        for (Object item : MapasJson.listar(visual, "imageLayers")) {
            if (item instanceof Map<?, ?> raw) {
                @SuppressWarnings("unchecked")
                Map<String, Object> layer = (Map<String, Object>) raw;
                String imageId = MapasJson.texto(MapasJson.filho(layer, "file"), "id", "");
                if (!imageId.isBlank()) {
                    ArquivoArmazenado image = storageService.buscar(imageId);
                    LimitesProcessamentoAcao.validarImagem(image);
                    imageLayers.add(new EdicaoImagemEngine.CamadaImagemVisual(
                            image,
                            MapasJson.filho(layer, "rect")
                    ));
                }
            }
        }
        return imageLayers;
    }
}
