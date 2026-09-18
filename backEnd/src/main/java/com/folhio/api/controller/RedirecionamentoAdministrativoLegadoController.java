package com.folhio.api.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@Controller
public class RedirecionamentoAdministrativoLegadoController {

    @GetMapping({"/admin", "/admin/"})
    public String indice() {
        return "redirect:/studio#logs";
    }

    @GetMapping("/admin/{nomeArquivo:.+}")
    public String recurso(@PathVariable String nomeArquivo) {
        return "redirect:/studio#logs";
    }
}
