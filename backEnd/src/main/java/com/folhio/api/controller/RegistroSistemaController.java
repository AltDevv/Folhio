package com.folhio.api.controller;

import com.folhio.api.entity.RegistroSistema;
import com.folhio.api.service.RegistroSistemaService;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/folhio")
public class RegistroSistemaController {

    private final RegistroSistemaService registros;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public RegistroSistemaController(RegistroSistemaService registros) {
        this.registros = registros;
    }

    @GetMapping("/admin/logs")
    public List<Map<String, Object>> listar(
            @RequestParam(required = false) String nivel,
            @RequestParam(required = false) String categoria,
            @RequestParam(required = false) String busca,
            @RequestParam(defaultValue = "150") int limite
    ) {
        return registros.listar(nivel, categoria, busca, limite)
                .stream()
                .map(this::resposta)
                .toList();
    }

    @GetMapping("/admin/logs/resumo")
    public Map<String, Object> resumo() {
        return registros.resumo();
    }

    @GetMapping("/admin/logs/metricas")
    public Map<String, Object> metricas() {
        return registros.metricas();
    }

    @PostMapping("/logs/client")
    public Map<String, Object> registrarCliente(@RequestBody Map<String, Object> payload,
            jakarta.servlet.http.HttpServletRequest request) {
        Map<String,Object> seguro=new LinkedHashMap<>(payload);
        Map<String,Object> detalhes=new LinkedHashMap<>();
        if(payload.get("detalhes") instanceof Map<?,?> mapa) {
            mapa.forEach((chave,valor)->detalhes.put(String.valueOf(chave),valor));
        }
        detalhes.put("appVersao",request.getHeader("X-Folhio-App-Version"));
        detalhes.put("dispositivo",request.getHeader("X-Folhio-Device"));
        detalhes.put("origemDeclarada","Telemetria enviada pelo aplicativo; nao e prova de auditoria.");
        seguro.put("detalhes",detalhes);
        if(!java.util.Set.of("INFO","AVISO","ERRO").contains(String.valueOf(seguro.get("nivel")))) seguro.put("nivel","INFO");
        seguro.put("requestId",request.getHeader("X-Request-Id"));
        registros.registrarCliente(seguro);
        return Map.of("success", true);
    }

    private Map<String, Object> resposta(RegistroSistema registro) {
        Map<String, Object> detalhes = detalhesMap(registro.obterDetalhes());
        Map<String, Object> leitura = leituraAmigavel(registro, detalhes);

        Map<String, Object> json = new LinkedHashMap<>();
        json.put("id", registro.obterId());
        json.put("criadoEm", registro.obterCriadoEm());
        json.put("nivel", registro.obterNivel());
        json.put("origem", registro.obterOrigem());
        json.put("categoria", registro.obterCategoria());
        json.put("evento", registro.obterEvento());
        json.put("mensagem", registro.obterMensagem());
        json.put("titulo", leitura.get("titulo"));
        json.put("descricao", leitura.get("descricao"));
        json.put("ferramenta", leitura.get("ferramenta"));
        json.put("arquivo", leitura.get("arquivo"));
        json.put("detalhesClaros", leitura.get("detalhesClaros"));
        json.put("requestId", registro.obterIdentificadorRequisicao());
        json.put("metodo", registro.obterMetodo());
        json.put("caminho", registro.obterCaminho());
        json.put("statusHttp", registro.obterStatusHttp());
        json.put("duracaoMs", registro.obterDuracaoMs());
        json.put("userAgent", registro.obterAgenteUsuario());
        json.put("detalhesTecnicos", detalhes);
        json.put("orientacao", orientacao(registro.obterStatusHttp(), detalhes));
        return json;
    }

    private Map<String, Object> leituraAmigavel(RegistroSistema registro, Map<String, Object> detalhes) {
        String evento = texto(registro.obterEvento());
        String categoria = texto(registro.obterCategoria());
        String grupoAcao = grupoAcao(detalhes);
        String ferramenta = primeiroTexto(detalhes, "title", "legacyOperationName", "type");
        String arquivo = primeiroTexto(detalhes, "fileExtension", "mimeType", "mimeTypeGerado");

        String titulo = switch (evento) {
            case "arquivo.upload" -> "Usuário enviou arquivo";
            case "arquivo.download" -> "Devolvendo arquivo finalizado";
            case "biblioteca.arquivo_salvo" -> "Arquivo salvo em Meus arquivos";
            case "biblioteca.pasta_criada" -> "Pasta criada";
            case "biblioteca.pasta_atualizada" -> "Pasta atualizada";
            case "biblioteca.pasta_apagada" -> "Pasta apagada";
            case "acao.iniciada" -> "Processando arquivo";
            case "acao.concluida" -> "Arquivo processado";
            case "acao.rejeitada" -> "Processamento recusado";
            case "acao.erro" -> "Erro ao processar arquivo";
            default -> tituloHttpOuPadrao(registro, categoria, evento);
        };

        String descricao = descricaoAmigavel(registro, detalhes, titulo, grupoAcao, ferramenta, arquivo);
        Map<String, Object> detalhesClaros = detalhesClaros(registro, detalhes, grupoAcao, ferramenta, arquivo);

        Map<String, Object> leitura = new LinkedHashMap<>();
        leitura.put("titulo", titulo);
        leitura.put("descricao", descricao);
        leitura.put("ferramenta", ferramenta);
        leitura.put("arquivo", arquivo);
        leitura.put("detalhesClaros", detalhesClaros);
        return leitura;
    }

    private String descricaoAmigavel(
            RegistroSistema registro,
            Map<String, Object> detalhes,
            String titulo,
            String grupoAcao,
            String ferramenta,
            String arquivo
    ) {
        if ("ACAO".equalsIgnoreCase(registro.obterCategoria())) {
            String prefixo = grupoAcao.isBlank() ? "Operação" : grupoAcao;
            String alvo = ferramenta.isBlank() ? "ferramenta não informada" : ferramenta;
            return "%s: %s.".formatted(prefixo, alvo);
        }
        if ("ARQUIVO".equalsIgnoreCase(registro.obterCategoria())) {
            return arquivo.isBlank() ? titulo + "." : "%s: %s.".formatted(titulo, arquivo);
        }
        if ("HTTP".equalsIgnoreCase(registro.obterCategoria())) {
            String caminho = texto(registro.obterCaminho());
            if (caminho.contains("/download") && registro.obterStatusHttp() != null && registro.obterStatusHttp() < 300) {
                return "Arquivo finalizado devolvido ao app.";
            }
            String causa=primeiroTexto(detalhes,"causa","mensagemErro");
            return tituloHttp(registro) + ". " + registro.obterMensagem()
                    + (causa.isBlank() ? "" : " Causa: " + causa);
        }
        return texto(registro.obterMensagem()).isBlank() ? titulo + "." : registro.obterMensagem();
    }

    private Map<String, Object> detalhesClaros(
            RegistroSistema registro,
            Map<String, Object> detalhes,
            String grupoAcao,
            String ferramenta,
            String arquivo
    ) {
        Map<String, Object> claros = new LinkedHashMap<>();
        colocar(claros, "Quando aconteceu", registro.obterCriadoEm());
        colocar(claros, "Origem", origemHumana(registro.obterOrigem()));
        colocar(claros, "Código do erro", detalhes.get("codigoErro"));
        colocar(claros, "Causa informada", detalhes.get("causa"));
        colocar(claros, "Próximo passo", orientacao(registro.obterStatusHttp(), detalhes));
        colocar(claros, "Tipo", registro.obterNivel());
        colocar(claros, "Ator", atorDoLog(registro, detalhes));
        colocar(claros, "Usuário", primeiroTexto(detalhes, "usuario", "userName", "nomeUsuario"));
        colocar(claros, "Método", registro.obterMetodo());
        colocar(claros, "Área", categoriaHumana(registro.obterCategoria()));
        colocar(claros, "Operação", grupoAcao);
        colocar(claros, "Ferramenta", ferramenta);
        colocar(claros, "Arquivo", arquivo);
        colocar(claros, "Tamanho", tamanhoHumano(detalhes.get("sizeBytes")));
        colocar(claros, "Status", registro.obterStatusHttp());
        colocar(claros, "Mensagem do erro", mensagemErro(registro, detalhes));
        colocar(claros, "Tempo", registro.obterDuracaoMs() == null ? "" : registro.obterDuracaoMs() + " ms");
        colocar(claros, "Request ID", registro.obterIdentificadorRequisicao());
        colocar(claros, "Ambiente", primeiroTexto(detalhes, "ambiente", "environment"));
        colocar(claros, "App/versão", primeiroTexto(detalhes, "appVersao", "appVersion"));
        colocar(claros, "Dispositivo", primeiroTexto(detalhes, "dispositivo", "device"));
        colocar(claros, "User-Agent", registro.obterAgenteUsuario());
        colocar(claros, "Caminho", registro.obterCaminho());
        return claros;
    }

    private String tituloHttpOuPadrao(RegistroSistema registro, String categoria, String evento) {
        if ("HTTP".equalsIgnoreCase(categoria)) {
            String caminho = texto(registro.obterCaminho());
            if (caminho.contains("/download") && registro.obterStatusHttp() != null && registro.obterStatusHttp() < 300) {
                return "Arquivo finalizado devolvido";
            }
            return tituloHttp(registro);
        }
        return registro.obterMensagem() == null || registro.obterMensagem().isBlank()
                ? "Evento registrado" : registro.obterMensagem();
    }

    private String tituloHttp(RegistroSistema registro) {
        String caminho=texto(registro.obterCaminho());
        String metodo=texto(registro.obterMetodo());
        if(caminho.contains("/auth/refresh")) return "Renovacao da sessao";
        if(caminho.contains("/auth/login")) return "Entrada com email e senha";
        if(caminho.contains("/auth/google")) return "Entrada com Google";
        if(caminho.contains("/auth/2fa")) return "Verificacao em duas etapas";
        if(caminho.contains("/password/forgot")) return "Solicitacao de recuperacao de senha";
        if(caminho.contains("/password/reset")) return "Redefinicao de senha";
        if(caminho.contains("/auth/register")) return "Cadastro de uma conta";
        if(caminho.contains("/auth/me")) return "Consulta ou alteracao da conta";
        if(caminho.contains("/layouts")) return switch(metodo) {
            case "POST" -> "Criacao de layout de material";
            case "PUT" -> "Atualizacao de layout de material";
            case "DELETE" -> "Exclusao de layout de material";
            default -> "Consulta de layouts de materiais";
        };
        if(caminho.contains("/upload")) return "Envio de arquivo ao servidor";
        if(caminho.contains("/download")) return "Transferencia de arquivo ao aplicativo";
        if(caminho.contains("/preview")) return "Preparacao da previa do arquivo";
        if(caminho.contains("/actions")) return "Processamento de uma ferramenta";
        if(caminho.contains("/materials/build")) return "Criacao de material didatico";
        if(caminho.contains("/materials")) return "Consulta do catalogo de materiais";
        if(caminho.contains("/dashboard")) return "Atualizacao do painel administrativo";
        if(caminho.contains("/files")) return "Consulta dos arquivos armazenados";
        if(caminho.contains("/health")) return "Verificacao da disponibilidade do servidor";
        return "Requisicao " + metodo + " ao servidor";
    }

    private String orientacao(Integer status, Map<String,Object> detalhes) {
        String codigo=texto(detalhes.get("codigoErro"));
        if("CHAVE_API_INVALIDA".equals(codigo)) return "Confira a chave configurada no aplicativo e no servidor.";
        if(status==null || status<400) return "Nenhuma intervencao necessaria.";
        return switch(status) {
            case 400,422 -> "Confira os dados enviados e os parametros da ferramenta.";
            case 401 -> "Confira a validade da sessao e a renovacao da autenticacao.";
            case 403 -> "Confira as permissoes do usuario para esta operacao.";
            case 404 -> "Confira se o recurso existe e pertence ao usuario.";
            case 409 -> "Recarregue o registro antes de repetir a alteracao.";
            case 413 -> "Reduza o arquivo ou confira o limite de envio.";
            case 415 -> "Confira o formato real e o tipo de conteudo do arquivo.";
            case 429 -> "Aguarde o intervalo de novas tentativas.";
            case 502,503,504 -> "Confira a disponibilidade do backend e dos servicos dependentes.";
            default -> "Localize os eventos com o mesmo Request ID para investigar a causa.";
        };
    }

    private String grupoAcao(Map<String, Object> detalhes) {
        return switch (texto(detalhes.get("category"))) {
            case "converter" -> "Conversão";
            case "edit" -> "Edição";
            case "tools" -> "Ferramenta";
            default -> "";
        };
    }

    private String origemHumana(String origem) {
        return switch (texto(origem)) {
            case "backend" -> "Servidor";
            case "flutter" -> "Aplicativo";
            default -> texto(origem);
        };
    }

    private String categoriaHumana(String categoria) {
        return switch (texto(categoria).toUpperCase()) {
            case "ARQUIVO" -> "Arquivos";
            case "ACAO" -> "Processamento";
            case "BIBLIOTECA" -> "Meus arquivos";
            case "CLIENTE" -> "Aplicativo";
            case "SISTEMA" -> "Sistema";
            default -> categoria;
        };
    }

    private String tamanhoHumano(Object valor) {
        if (!(valor instanceof Number numero)) {
            return "";
        }
        double bytes = numero.doubleValue();
        if (bytes < 1024) {
            return "%.0f B".formatted(bytes);
        }
        if (bytes < 1024 * 1024) {
            return "%.1f KB".formatted(bytes / 1024);
        }
        return "%.1f MB".formatted(bytes / (1024 * 1024));
    }

    private String mensagemErro(RegistroSistema registro, Map<String, Object> detalhes) {
        String mensagem = primeiroTexto(detalhes, "mensagemErro", "erroMensagem", "errorMessage", "exceptionMessage");
        if (!mensagem.isBlank() && !"***".equals(mensagem)) {
            return mensagem;
        }
        Integer status = registro.obterStatusHttp();
        if ("ERRO".equalsIgnoreCase(registro.obterNivel()) || (status != null && status >= 400)) {
            return texto(registro.obterMensagem());
        }
        return "";
    }

    private String atorDoLog(RegistroSistema registro, Map<String, Object> detalhes) {
        if (!primeiroTexto(detalhes, "usuario", "userName", "nomeUsuario").isBlank()) {
            return "Usuário";
        }
        String categoria = texto(registro.obterCategoria());
        String evento = texto(registro.obterEvento());
        String caminho = texto(registro.obterCaminho());
        if ("SISTEMA".equalsIgnoreCase(categoria) || evento.startsWith("backend.")) {
            return "Sistema";
        }
        if (caminho.startsWith("/api/folhio/auth/refresh")
                || caminho.startsWith("/api/folhio/logs/client")) {
            return "Sistema";
        }
        return "Usuário";
    }

    private void colocar(Map<String, Object> mapa, String chave, Object valor) {
        if (valor == null) {
            return;
        }
        String texto = valor.toString();
        if (!texto.isBlank()) {
            mapa.put(chave, valor);
        }
    }

    private String primeiroTexto(Map<String, Object> mapa, String... chaves) {
        for (String chave : chaves) {
            String valor = texto(mapa.get(chave));
            if (!valor.isBlank()) {
                return valor;
            }
        }
        return "";
    }

    private Map<String, Object> detalhesMap(String detalhes) {
        if (detalhes == null || detalhes.isBlank()) {
            return Map.of();
        }
        try {
            return objectMapper.readValue(detalhes, new TypeReference<>() {
            });
        } catch (Exception ignored) {
            return Map.of("texto", detalhes);
        }
    }

    private String texto(Object valor) {
        return valor == null ? "" : valor.toString().trim();
    }
}
