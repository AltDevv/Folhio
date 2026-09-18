package com.folhio.api.controller;

import com.folhio.api.dto.layout.LayoutDtos.*;
import com.folhio.api.service.LayoutMaterialService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/folhio/admin/studio/layouts")
public class LayoutMaterialController {
    private final LayoutMaterialService service;
    public LayoutMaterialController(LayoutMaterialService service) { this.service=service; }
    @GetMapping public List<LayoutResponse> listar(@RequestParam(defaultValue="0") int pagina) {
        return service.listar(pagina);
    }
    @GetMapping("/{id}") public LayoutResponse buscar(@PathVariable String id) { return service.buscar(id); }
    @PostMapping public LayoutResponse criar(@Valid @RequestBody LayoutRequest request) {
        return service.salvar(null,request);
    }
    @PutMapping("/{id}") public LayoutResponse atualizar(@PathVariable String id,@Valid @RequestBody LayoutRequest request) {
        return service.salvar(id,request);
    }
    @DeleteMapping("/{id}") public void excluir(@PathVariable String id,@RequestParam long versao) {
        service.excluir(id,versao);
    }
}
