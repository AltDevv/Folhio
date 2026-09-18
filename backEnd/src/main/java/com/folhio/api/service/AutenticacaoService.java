package com.folhio.api.service;

import com.folhio.api.entity.Usuario;
import com.folhio.api.entity.TokenRecuperacaoSenha;
import com.folhio.api.mapper.UsuarioMapper;
import com.folhio.api.repository.UsuarioRepository;
import com.folhio.api.repository.TokenRecuperacaoSenhaRepository;
import com.folhio.api.security.authentication.UsuarioAutenticado;
import com.folhio.api.security.authentication.IdentidadeGoogleVerifier;
import com.folhio.api.security.authentication.TokenHasher;
import com.folhio.api.security.password.SenhaHasher;
import com.folhio.api.security.passwordreset.RecuperacaoSenhaEmailSender;

import com.folhio.api.dto.auth.AutenticacaoDtos.AutenticacaoResponse;
import com.folhio.api.dto.auth.AutenticacaoDtos.AtualizacaoContaResponse;
import com.folhio.api.dto.auth.AutenticacaoDtos.ConfiguracaoDoisFatoresResponse;
import com.folhio.api.dto.auth.AutenticacaoDtos.UsuarioResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;

@Service
public class AutenticacaoService {
    private static final String GENERIC_LOGIN_ERROR = "Email ou senha invalidos.";
    private static final String TWO_FACTOR_EMAIL = "email";

    private final UsuarioRepository users;
    private final TokenRecuperacaoSenhaRepository resets;
    private final SenhaHasher passwords;
    private final TokenHasher tokens;
    private final SessaoAutenticacaoService authSessions;
    private final IdentidadeGoogleVerifier googleIdentity;
    private final RecuperacaoSenhaEmailSender resetEmailSender;
    private final long resetMinutes;

    public AutenticacaoService(
            UsuarioRepository users,
            TokenRecuperacaoSenhaRepository resets,
            SenhaHasher passwords,
            TokenHasher tokens,
            SessaoAutenticacaoService authSessions,
            IdentidadeGoogleVerifier googleIdentity,
            RecuperacaoSenhaEmailSender resetEmailSender,
            @Value("${folhio.auth.password-reset-minutes:30}") long resetMinutes
    ) {
        this.users = users;
        this.resets = resets;
        this.passwords = passwords;
        this.tokens = tokens;
        this.authSessions = authSessions;
        this.googleIdentity = googleIdentity;
        this.resetEmailSender = resetEmailSender;
        this.resetMinutes = Math.max(5, resetMinutes);
    }

    @Transactional
    public AutenticacaoResponse cadastrar(String name, String email, String password, String clientId) {
        validarSenha(password);
        String normalized = Usuario.normalizarEmail(email);
        if (users.buscarPorEmailNormalizado(normalized).isPresent()) {
            throw new com.folhio.api.handler.user.exception.EmailJaCadastradoException("Ja existe uma conta com este email.");
        }
        Usuario user = new Usuario(email.trim(), limparNome(name));
        user.definirHashSenha(passwords.calcularHash(password));
        users.save(user);
        return authSessions.emitirSessao(user, clientId);
    }

    @Transactional
    public AutenticacaoResponse entrar(String email, String password, String clientId) {
        Usuario user = users.buscarPorEmailNormalizado(Usuario.normalizarEmail(email))
                .filter(found -> !found.estaDesativado())
                .orElseThrow(() -> new com.folhio.api.handler.auth.exception.CredenciaisInvalidasException(GENERIC_LOGIN_ERROR));
        if (!passwords.corresponde(password, user.obterHashSenha())) {
            throw new com.folhio.api.handler.auth.exception.CredenciaisInvalidasException(GENERIC_LOGIN_ERROR);
        }
        return authSessions.emitirSessaoOuDoisFatores(user, clientId, false);
    }

    @Transactional
    public AutenticacaoResponse autenticarComGoogle(String idToken, String clientId) {
        IdentidadeGoogleVerifier.PerfilGoogle profile = googleIdentity.verificar(idToken);
        Usuario user = resolverUsuarioGoogle(profile);
        boolean needsAccountSetup = !temSenha(user);
        if (user.estaDesativado()) {
            throw new com.folhio.api.handler.auth.exception.ContaDesativadaException("Conta desativada.");
        }
        user.definirIdentificadorGoogle(profile.subject());
        user.definirEmail(profile.email());
        if (!profile.name().isBlank()) {
            user.definirNomeExibicao(limparNome(profile.name()));
        }
        user.definirUrlAvatar(profile.picture());
        user.definirEmailVerificado(true);
        users.save(user);
        return authSessions.emitirSessaoOuDoisFatores(user, clientId, needsAccountSetup);
    }

    private Usuario resolverUsuarioGoogle(IdentidadeGoogleVerifier.PerfilGoogle profile) {
        Optional<Usuario> linked = users.buscarPorIdentificadorGoogle(profile.subject());
        Optional<Usuario> exactEmail = users.buscarPorEmailNormalizado(Usuario.normalizarEmail(profile.email()));
        Optional<Usuario> passwordAccount = buscarContaComSenhaPorEmailGoogleCanonico(profile.email(), linked.orElse(null));
        Optional<Usuario> exactPasswordAccount = exactEmail.filter(this::temSenha);
        Usuario selected = exactPasswordAccount
                .or(() -> passwordAccount)
                .or(() -> exactEmail)
                .or(() -> linked)
                .orElseGet(() -> new Usuario(profile.email(), limparNome(profile.name())));

        linked.filter(current -> current != selected).ifPresent(current -> {
            current.definirIdentificadorGoogle(null);
            users.save(current);
        });
        return selected;
    }

    private Optional<Usuario> buscarContaComSenhaPorEmailGoogleCanonico(String email, Usuario linked) {
        String canonical = Usuario.emailGoogleCanonico(email);
        if (!canonical.endsWith("@gmail.com")) {
            return Optional.empty();
        }
        List<Usuario> matches = users.findAll().stream()
                .filter(user -> user != linked)
                .filter(this::temSenha)
                .filter(user -> Usuario.emailGoogleCanonico(user.obterEmail()).equals(canonical))
                .toList();
        if (matches.size() > 1) {
            throw new com.folhio.api.handler.user.exception.ContaAmbiguaException("Ha mais de uma conta local equivalente a este email do Google.");
        }
        return matches.stream().findFirst();
    }

    private boolean temSenha(Usuario user) {
        return user.obterHashSenha() != null && !user.obterHashSenha().isBlank();
    }

    @Transactional
    public AutenticacaoResponse renovar(String refreshToken, String clientId) {
        return authSessions.renovar(refreshToken, clientId);
    }

    @Transactional
    public void sair(String refreshToken) {
        authSessions.sair(refreshToken);
    }

    @Transactional
    public void solicitarRecuperacaoSenha(String email) {
        resetEmailSender.exigirDisponibilidade();
        users.buscarPorEmailNormalizado(Usuario.normalizarEmail(email))
                .filter(user -> !user.estaDesativado())
                .ifPresent(user -> {
                    String raw = tokens.novoToken();
                    TokenRecuperacaoSenha reset = new TokenRecuperacaoSenha(
                            user,
                            tokens.calcularHash(raw),
                            Instant.now().plus(resetMinutes, ChronoUnit.MINUTES)
                    );
                    resets.save(reset);
                    resetEmailSender.enviar(user, raw);
                });
    }

    @Transactional
    public void redefinirSenha(String rawToken, String newPassword) {
        validarSenha(newPassword);
        TokenRecuperacaoSenha reset = resets.buscarPorHashToken(tokens.calcularHash(rawToken))
                .orElseThrow(() -> new com.folhio.api.handler.auth.exception.RecuperacaoSenhaInvalidaException("Token de recuperacao invalido ou expirado."));
        if (reset.obterDataUso() != null || reset.obterDataExpiracao().isBefore(Instant.now())) {
            throw new com.folhio.api.handler.auth.exception.RecuperacaoSenhaInvalidaException("Token de recuperacao invalido ou expirado.");
        }
        Usuario user = reset.obterUsuario();
        user.definirHashSenha(passwords.calcularHash(newPassword));
        users.save(user);
        reset.marcarUsado();
        resets.save(reset);
        authSessions.revogarTodasDoUsuario(user);
    }

    @Transactional(readOnly = true)
    public UsuarioResponse consultarUsuarioAtual(UsuarioAutenticado authenticatedUser) {
        Usuario user = users.findById(authenticatedUser.id())
                .filter(found -> !found.estaDesativado())
                .orElseThrow(() -> new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Sessao invalida."));
        return UsuarioMapper.respostaUsuario(user);
    }

    @Transactional
    public UsuarioResponse atualizarPerfil(UsuarioAutenticado authenticatedUser, String name) {
        Usuario user = users.findById(authenticatedUser.id())
                .filter(found -> !found.estaDesativado())
                .orElseThrow(() -> new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Sessao invalida."));
        user.definirNomeExibicao(limparNome(name));
        users.save(user);
        return UsuarioMapper.respostaUsuario(user);
    }

    @Transactional(readOnly = true)
    public ConfiguracaoDoisFatoresResponse configuracaoDoisFatores(UsuarioAutenticado authenticatedUser) {
        Usuario user = users.findById(authenticatedUser.id())
                .filter(found -> !found.estaDesativado())
                .orElseThrow(() -> new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Sessao invalida."));
        return UsuarioMapper.respostaConfiguracaoDoisFatores(user, authSessions.emailDoisFatoresDisponivel());
    }

    @Transactional
    public ConfiguracaoDoisFatoresResponse atualizarConfiguracaoDoisFatores(
            UsuarioAutenticado authenticatedUser,
            boolean enabled,
            String method,
            String currentPassword,
            String twoFactorToken,
            String twoFactorCode,
            String clientId
    ) {
        Usuario user = users.findById(authenticatedUser.id())
                .filter(found -> !found.estaDesativado())
                .orElseThrow(() -> new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Sessao invalida."));
        String normalizedMethod = method == null || method.isBlank() ? TWO_FACTOR_EMAIL : method.trim().toLowerCase();
        if (!TWO_FACTOR_EMAIL.equals(normalizedMethod)) {
            throw new com.folhio.api.handler.validation.exception.DadosInvalidosException("No momento, a verificacao em duas etapas esta disponivel apenas por email.");
        }
        if (enabled && !authSessions.emailDoisFatoresDisponivel()) {
            throw new com.folhio.api.handler.integration.exception.ServicoEmailIndisponivelException("Envio de email de seguranca nao configurado no servidor.");
        }
        if (!enabled && user.doisFatoresAtivado()) {
            exigirSenhaAtualSeDefinida(user, currentPassword);
            Optional<AutenticacaoResponse> challenge = authSessions.exigirDoisFatoresNaAcao(
                    user,
                    clientId,
                    "disable_2fa",
                    twoFactorToken,
                    twoFactorCode
            );
            if (challenge.isPresent()) {
                AutenticacaoResponse response = challenge.get();
                return new ConfiguracaoDoisFatoresResponse(
                        true,
                        UsuarioMapper.metodoConfiguracaoDoisFatores(user),
                        authSessions.emailDoisFatoresDisponivel(),
                        true,
                        response.twoFactorToken(),
                        response.twoFactorDestination()
                );
            }
        }
        user.definirDoisFatoresAtivado(enabled);
        user.definirMetodoDoisFatores(enabled ? normalizedMethod : null);
        users.save(user);
        return UsuarioMapper.respostaConfiguracaoDoisFatores(user, authSessions.emailDoisFatoresDisponivel());
    }

    @Transactional
    public AtualizacaoContaResponse atualizarConta(
            UsuarioAutenticado authenticatedUser,
            String name,
            String email,
            String currentPassword,
            String newPassword,
            String twoFactorToken,
            String twoFactorCode,
            String clientId
    ) {
        Usuario user = users.findById(authenticatedUser.id())
                .filter(found -> !found.estaDesativado())
                .orElseThrow(() -> new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Sessao invalida."));

        String normalizedEmail = Usuario.normalizarEmail(email);
        boolean changesEmail = !normalizedEmail.isBlank() && !normalizedEmail.equals(user.obterEmailNormalizado());
        boolean changesPassword = newPassword != null && !newPassword.isBlank();
        boolean sensitive = changesEmail || changesPassword;

        if (sensitive) {
            exigirSenhaAtualSeDefinida(user, currentPassword);
            String purpose = changesEmail && !changesPassword
                    ? "change_email"
                    : changesPassword && !changesEmail
                    ? "change_password"
                    : "account_update";
            Optional<AutenticacaoResponse> challenge = authSessions.exigirDoisFatoresNaAcao(
                    user,
                    clientId,
                    purpose,
                    twoFactorToken,
                    twoFactorCode
            );
            if (challenge.isPresent()) {
                AutenticacaoResponse response = challenge.get();
                return new AtualizacaoContaResponse(
                        false,
                        null,
                        true,
                        response.twoFactorToken(),
                        response.twoFactorDestination(),
                        "Confirme o codigo enviado ao seu email."
                );
            }
        }

        if (name != null && !name.isBlank()) {
            user.definirNomeExibicao(limparNome(name));
        }
        if (changesEmail) {
            users.buscarPorEmailNormalizado(normalizedEmail)
                    .filter(found -> found != user)
                    .ifPresent(found -> {
                        throw new com.folhio.api.handler.user.exception.EmailJaCadastradoException("Ja existe uma conta com este email.");
                    });
            user.definirEmail(email.trim());
            user.definirEmailVerificado(false);
        }
        if (changesPassword) {
            validarSenha(newPassword);
            user.definirHashSenha(passwords.calcularHash(newPassword));
        }
        users.save(user);
        return new AtualizacaoContaResponse(
                true,
                UsuarioMapper.respostaUsuario(user),
                false,
                null,
                null,
                "Conta atualizada."
        );
    }

    @Transactional
    public AtualizacaoContaResponse excluirConta(
            UsuarioAutenticado authenticatedUser,
            String currentPassword,
            String twoFactorToken,
            String twoFactorCode,
            String clientId
    ) {
        Usuario user = users.findById(authenticatedUser.id())
                .filter(found -> !found.estaDesativado())
                .orElseThrow(() -> new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Sessao invalida."));

        exigirSenhaAtualSeDefinida(user, currentPassword);
        Optional<AutenticacaoResponse> challenge = authSessions.exigirDoisFatoresNaAcao(
                user,
                clientId,
                "delete_account",
                twoFactorToken,
                twoFactorCode
        );
        if (challenge.isPresent()) {
            AutenticacaoResponse response = challenge.get();
            return new AtualizacaoContaResponse(
                    false,
                    null,
                    true,
                    response.twoFactorToken(),
                    response.twoFactorDestination(),
                    "Confirme o codigo enviado ao seu email para apagar a conta."
            );
        }

        authSessions.excluirSessoesDoUsuario(user);
        resets.excluirPorUsuario(user);
        authSessions.excluirDesafiosDoisFatoresDoUsuario(user);
        users.delete(user);
        return new AtualizacaoContaResponse(
                true,
                null,
                false,
                null,
                null,
                "Conta apagada."
        );
    }

    @Transactional
    public AutenticacaoResponse verificarDoisFatores(String twoFactorToken, String code, String clientId) {
        return authSessions.verificarEntradaDoisFatores(twoFactorToken, code, clientId);
    }

    private void exigirSenhaAtualSeDefinida(Usuario user, String currentPassword) {
        if (!temSenha(user)) {
            return;
        }
        if (!senhaAtualCorresponde(user, currentPassword)) {
            throw new com.folhio.api.handler.auth.exception.SenhaAtualInvalidaException("Senha atual invalida.");
        }
    }

    private boolean senhaAtualCorresponde(Usuario user, String currentPassword) {
        if (currentPassword == null || currentPassword.isBlank()) {
            return false;
        }
        if (passwords.corresponde(currentPassword, user.obterHashSenha())) {
            return true;
        }
        String trimmed = currentPassword.trim();
        return !trimmed.equals(currentPassword) && passwords.corresponde(trimmed, user.obterHashSenha());
    }

    private void validarSenha(String password) {
        if (password == null || password.length() < 8 || password.length() > 120) {
            throw new com.folhio.api.handler.validation.exception.DadosInvalidosException("Use uma senha com pelo menos 8 caracteres.");
        }
        boolean hasLetter = password.chars().anyMatch(Character::isLetter);
        boolean hasDigit = password.chars().anyMatch(Character::isDigit);
        if (!hasLetter || !hasDigit) {
            throw new com.folhio.api.handler.validation.exception.DadosInvalidosException("Use letras e numeros na senha.");
        }
    }

    private String limparNome(String name) {
        String clean = name == null ? "" : name.trim().replaceAll("\\s+", " ");
        return clean.isBlank() ? "Professor" : clean.substring(0, Math.min(clean.length(), 120));
    }

}
