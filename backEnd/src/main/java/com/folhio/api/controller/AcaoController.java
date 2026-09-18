package com.folhio.api.controller;

import com.folhio.api.dto.action.AcaoRequest;
import com.folhio.api.dto.action.AcaoResponse;
import com.folhio.api.processing.router.AcaoPrincipalRouter;
import com.folhio.api.security.authentication.UsuarioAutenticado;
import com.folhio.api.security.IdentidadeCliente;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/folhio")
public class AcaoController {

    private final AcaoPrincipalRouter actionRouter;

    public AcaoController(AcaoPrincipalRouter actionRouter) {
        this.actionRouter = actionRouter;
    }

    @GetMapping("/health")
    public Map<String, Object> verificarSaude() {
        return Map.of(
                "status", "ok",
                "app", "folio-api"
        );
    }

    @PostMapping("/actions")
    public ResponseEntity<AcaoResponse> processar(
            @Valid @RequestBody AcaoRequest request,
            HttpServletRequest httpRequest
    ) {
        AcaoResponse response = actionRouter.processar(
                request,
                IdentidadeCliente.obrigatorio(httpRequest),
                identificadorUsuarioAutenticado(httpRequest)
        );
        return response.success() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    private String identificadorUsuarioAutenticado(HttpServletRequest request) {
        Object value = request.getAttribute(UsuarioAutenticado.REQUEST_ATTRIBUTE);
        if (value instanceof UsuarioAutenticado user) {
            return user.id();
        }
        return null;
    }
}
