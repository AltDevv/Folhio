package com.folhio.api.controller;

import com.folhio.api.security.authentication.UsuarioAutenticado;
import com.folhio.api.service.AutenticacaoService;

import com.folhio.api.dto.auth.AutenticacaoDtos.AutenticacaoResponse;
import com.folhio.api.dto.auth.AutenticacaoDtos.AtualizacaoContaResponse;
import com.folhio.api.dto.auth.AutenticacaoDtos.ExclusaoContaRequest;
import com.folhio.api.dto.auth.AutenticacaoDtos.RecuperacaoSenhaRequest;
import com.folhio.api.dto.auth.AutenticacaoDtos.EntradaGoogleRequest;
import com.folhio.api.dto.auth.AutenticacaoDtos.EntradaRequest;
import com.folhio.api.dto.auth.AutenticacaoDtos.MensagemResponse;
import com.folhio.api.dto.auth.AutenticacaoDtos.RenovacaoRequest;
import com.folhio.api.dto.auth.AutenticacaoDtos.CadastroRequest;
import com.folhio.api.dto.auth.AutenticacaoDtos.RedefinicaoSenhaRequest;
import com.folhio.api.dto.auth.AutenticacaoDtos.ConfiguracaoDoisFatoresResponse;
import com.folhio.api.dto.auth.AutenticacaoDtos.AtualizacaoContaRequest;
import com.folhio.api.dto.auth.AutenticacaoDtos.UsuarioResponse;
import com.folhio.api.dto.auth.AutenticacaoDtos.AtualizacaoDoisFatoresRequest;
import com.folhio.api.dto.auth.AutenticacaoDtos.AtualizacaoPerfilRequest;
import com.folhio.api.dto.auth.AutenticacaoDtos.VerificacaoDoisFatoresRequest;
import com.folhio.api.service.RegistroSistemaService;
import com.folhio.api.security.IdentidadeCliente;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/folhio/auth")
public class AutenticacaoController {
    private final AutenticacaoService auth;
    private final RegistroSistemaService registros;
    private final com.folhio.api.audit.AuditoriaService audit;

    public AutenticacaoController(AutenticacaoService auth, RegistroSistemaService registros, com.folhio.api.audit.AuditoriaService audit) {
        this.auth = auth;
        this.registros = registros;
        this.audit = audit;
    }

    @PostMapping("/register")
    public AutenticacaoResponse cadastrar(@Valid @RequestBody CadastroRequest request, HttpServletRequest httpRequest) {
        AutenticacaoResponse response = auth.cadastrar(request.name(), request.email(), request.password(), IdentidadeCliente.obrigatorio(httpRequest));
        registrarCliente("auth.register", "Conta criada pelo app.", response);
        return comUsuarioAutenticado(response, httpRequest);
    }

    @PostMapping("/login")
    public AutenticacaoResponse entrar(@Valid @RequestBody EntradaRequest request, HttpServletRequest httpRequest) {
        AutenticacaoResponse response = auth.entrar(request.email(), request.password(), IdentidadeCliente.obrigatorio(httpRequest));
        registrarCliente("auth.login", response.twoFactorRequired() ? "Login aguardando verificacao em duas etapas." : "Login concluido pelo app.", response);
        return comUsuarioAutenticado(response, httpRequest);
    }

    @PostMapping("/google")
    public AutenticacaoResponse entrarComGoogle(@Valid @RequestBody EntradaGoogleRequest request, HttpServletRequest httpRequest) {
        AutenticacaoResponse response = auth.autenticarComGoogle(request.idToken(), IdentidadeCliente.obrigatorio(httpRequest));
        registrarCliente("auth.google", response.twoFactorRequired() ? "Login Google aguardando verificacao em duas etapas." : "Login Google concluido pelo app.", response);
        return comUsuarioAutenticado(response, httpRequest);
    }

    @PostMapping("/refresh")
    public AutenticacaoResponse renovar(@Valid @RequestBody RenovacaoRequest request, HttpServletRequest httpRequest) {
        return comUsuarioAutenticado(
                auth.renovar(request.refreshToken(), IdentidadeCliente.obrigatorio(httpRequest)),
                httpRequest
        );
    }

    @PostMapping("/2fa/verify")
    public AutenticacaoResponse verificarDoisFatores(@Valid @RequestBody VerificacaoDoisFatoresRequest request, HttpServletRequest httpRequest) {
        AutenticacaoResponse response = auth.verificarDoisFatores(request.twoFactorToken(), request.code(), IdentidadeCliente.obrigatorio(httpRequest));
        registrarCliente("auth.2fa.verificada", "Verificacao em duas etapas concluida.", response);
        return comUsuarioAutenticado(response, httpRequest);
    }

    @PostMapping("/logout")
    public MensagemResponse sair(@Valid @RequestBody RenovacaoRequest request) {
        auth.sair(request.refreshToken());
        registros.informacao("CLIENTE", "auth.logout", "Sessao encerrada pelo app.", Map.of());
        return new MensagemResponse(true, "Sessao encerrada.");
    }

    @PostMapping("/password/forgot")
    public MensagemResponse recuperarSenha(@Valid @RequestBody RecuperacaoSenhaRequest request) {
        auth.solicitarRecuperacaoSenha(request.email());
        registros.informacao("CLIENTE", "auth.password.forgot", "Recuperacao de senha solicitada.", Map.of());
        return new MensagemResponse(true, "Se o email estiver cadastrado, enviaremos instrucoes de recuperacao.");
    }

    @PostMapping("/password/reset")
    public MensagemResponse redefinirSenha(@Valid @RequestBody RedefinicaoSenhaRequest request) {
        auth.redefinirSenha(request.token(), request.newPassword());
        registros.informacao("CLIENTE", "auth.password.reset", "Senha atualizada por recuperacao.", Map.of());
        return new MensagemResponse(true, "Senha atualizada.");
    }

    @GetMapping("/me")
    public UsuarioResponse consultarUsuarioAtual(HttpServletRequest request) {
        return auth.consultarUsuarioAtual(usuarioObrigatorio(request));
    }

    @PatchMapping("/me")
    public UsuarioResponse atualizarPerfil(@Valid @RequestBody AtualizacaoPerfilRequest profile, HttpServletRequest request) {
        UsuarioAutenticado user = usuarioObrigatorio(request);
        UsuarioResponse response = auth.atualizarPerfil(user, profile.name());
        registros.informacao("CLIENTE", "auth.profile.updated", "Perfil atualizado pelo app.", Map.of("userId", user.id()));
        return response;
    }

    @PatchMapping("/me/account")
    public AtualizacaoContaResponse atualizarConta(
            @Valid @RequestBody AtualizacaoContaRequest account,
            HttpServletRequest request
    ) {
        UsuarioAutenticado user = usuarioObrigatorio(request);
        AtualizacaoContaResponse response = auth.atualizarConta(
                user,
                account.name(),
                account.email(),
                account.currentPassword(),
                account.newPassword(),
                account.twoFactorToken(),
                account.twoFactorCode(),
                IdentidadeCliente.obrigatorio(request)
        );
        registros.informacao("CLIENTE", "auth.account.updated", response.twoFactorRequired() ? "Atualizacao de conta aguardando 2FA." : "Conta atualizada pelo app.", Map.of("userId", user.id()));
        if (!response.twoFactorRequired()) audit.registrar(com.folhio.api.enums.AcaoAuditoria.UPDATE_ACCOUNT, user.id(), user.id());
        return response;
    }

    @DeleteMapping("/me/account")
    public AtualizacaoContaResponse excluirConta(
            @Valid @RequestBody ExclusaoContaRequest account,
            HttpServletRequest request
    ) {
        UsuarioAutenticado user = usuarioObrigatorio(request);
        AtualizacaoContaResponse response = auth.excluirConta(
                user,
                account.currentPassword(),
                account.twoFactorToken(),
                account.twoFactorCode(),
                IdentidadeCliente.obrigatorio(request)
        );
        registros.informacao("CLIENTE", "auth.account.deleted", response.twoFactorRequired() ? "Exclusao de conta aguardando 2FA." : "Conta removida pelo app.", Map.of("userId", user.id()));
        if (!response.twoFactorRequired()) audit.registrar(com.folhio.api.enums.AcaoAuditoria.DELETE_ACCOUNT, user.id(), user.id());
        return response;
    }

    @GetMapping("/me/2fa")
    public ConfiguracaoDoisFatoresResponse configuracaoDoisFatores(HttpServletRequest request) {
        return auth.configuracaoDoisFatores(usuarioObrigatorio(request));
    }

    @PatchMapping("/me/2fa")
    public ConfiguracaoDoisFatoresResponse atualizarConfiguracaoDoisFatores(
            @Valid @RequestBody AtualizacaoDoisFatoresRequest settings,
            HttpServletRequest request
    ) {
        UsuarioAutenticado user = usuarioObrigatorio(request);
        ConfiguracaoDoisFatoresResponse response = auth.atualizarConfiguracaoDoisFatores(
                user,
                settings.enabled(),
                settings.method(),
                settings.currentPassword(),
                settings.twoFactorToken(),
                settings.twoFactorCode(),
                IdentidadeCliente.obrigatorio(request)
        );
        registros.informacao("CLIENTE", "auth.2fa.updated", "Configuracao de 2FA alterada pelo app.", Map.of("userId", user.id(), "enabled", response.enabled()));
        return response;
    }

    private UsuarioAutenticado usuarioObrigatorio(HttpServletRequest request) {
        Object value = request.getAttribute(UsuarioAutenticado.REQUEST_ATTRIBUTE);
        if (value instanceof UsuarioAutenticado user) {
            return user;
        }
        throw new com.folhio.api.handler.auth.exception.SessaoObrigatoriaException("Sessao obrigatoria.");
    }

    private AutenticacaoResponse comUsuarioAutenticado(AutenticacaoResponse response, HttpServletRequest request) {
        if (response.user() != null) {
            request.setAttribute(
                    UsuarioAutenticado.REQUEST_ATTRIBUTE,
                    new UsuarioAutenticado(response.user().id(), "", response.user().name())
            );
        }
        return response;
    }

    private void registrarCliente(String evento, String mensagem, AutenticacaoResponse response) {
        if (response.user() != null && !response.twoFactorRequired()) {
            audit.registrar(com.folhio.api.enums.AcaoAuditoria.LOGIN, response.user().id(), null);
        }
        Map<String, Object> detalhes = response.user() == null
                ? Map.of("twoFactorRequired", response.twoFactorRequired())
                : Map.of("userId", response.user().id(), "twoFactorRequired", response.twoFactorRequired());
        registros.informacao("CLIENTE", evento, mensagem, detalhes);
    }
}
