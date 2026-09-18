package com.folhio.api.service;

import com.folhio.api.entity.Usuario;
import com.folhio.api.entity.SessaoRenovacao;
import com.folhio.api.entity.DesafioDoisFatores;
import com.folhio.api.mapper.UsuarioMapper;
import com.folhio.api.repository.SessaoRenovacaoRepository;
import com.folhio.api.repository.DesafioDoisFatoresRepository;
import com.folhio.api.security.authentication.TokenAcessoService;
import com.folhio.api.security.authentication.TokenHasher;
import com.folhio.api.security.twofactor.DoisFatoresEmailSender;

import com.folhio.api.dto.auth.AutenticacaoDtos.AutenticacaoResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;

@Service
public class SessaoAutenticacaoService {

    private static final String TWO_FACTOR_EMAIL = "email";
    private static final SecureRandom TWO_FACTOR_RANDOM = new SecureRandom();
    private static final Instant SESSION_NEVER_EXPIRES_AT = Instant.parse("9999-12-31T23:59:59Z");

    private final SessaoRenovacaoRepository sessions;
    private final DesafioDoisFatoresRepository twoFactorChallenges;
    private final TokenHasher tokens;
    private final TokenAcessoService accessTokens;
    private final DoisFatoresEmailSender twoFactorEmailSender;
    private final long twoFactorMinutes;

    public SessaoAutenticacaoService(
            SessaoRenovacaoRepository sessions,
            DesafioDoisFatoresRepository twoFactorChallenges,
            TokenHasher tokens,
            TokenAcessoService accessTokens,
            DoisFatoresEmailSender twoFactorEmailSender,
            @Value("${folhio.auth.two-factor-minutes:10}") long twoFactorMinutes
    ) {
        this.sessions = sessions;
        this.twoFactorChallenges = twoFactorChallenges;
        this.tokens = tokens;
        this.accessTokens = accessTokens;
        this.twoFactorEmailSender = twoFactorEmailSender;
        this.twoFactorMinutes = Math.max(3, twoFactorMinutes);
    }

    AutenticacaoResponse renovar(String refreshToken, String clientId) {
        SessaoRenovacao current = sessions.buscarPorHashToken(tokens.calcularHash(refreshToken))
                .orElseThrow(() -> new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Sessão inválida."));
        if (current.obterDataRevogacao() != null
                || (current.obterDataExpiracao() != null && current.obterDataExpiracao().isBefore(Instant.now()))
                || current.obterUsuario().estaDesativado()) {
            throw new com.folhio.api.handler.auth.exception.SessaoInvalidaException("Sessão inválida.");
        }
        return renovarTokenAcesso(current.obterUsuario(), refreshToken);
    }

    void sair(String refreshToken) {
        sessions.buscarPorHashToken(tokens.calcularHash(refreshToken)).ifPresent(session -> {
            session.revogar();
            sessions.save(session);
        });
    }

    void revogarTodasDoUsuario(Usuario user) {
        for (SessaoRenovacao session : sessions.buscarSessoesNaoRevogadasPorUsuario(user)) {
            session.revogar();
            sessions.save(session);
        }
    }

    void excluirSessoesDoUsuario(Usuario user) {
        sessions.excluirPorUsuario(user);
    }

    void excluirDesafiosDoisFatoresDoUsuario(Usuario user) {
        twoFactorChallenges.excluirPorUsuario(user);
    }

    boolean emailDoisFatoresDisponivel() {
        return twoFactorEmailSender.estaDisponivel();
    }

    AutenticacaoResponse verificarEntradaDoisFatores(String twoFactorToken, String code, String clientId) {
        DesafioDoisFatores challenge = verificarDesafioDoisFatores(null, clientId, "login", twoFactorToken, code);
        return emitirSessao(challenge.obterUsuario(), clientId, challenge.precisaConfirmacaoNome());
    }

    AutenticacaoResponse emitirSessao(Usuario user, String clientId) {
        return emitirSessao(user, clientId, false);
    }

    AutenticacaoResponse emitirSessaoOuDoisFatores(Usuario user, String clientId, boolean needsNameConfirmation) {
        if (!user.doisFatoresAtivado()) {
            return emitirSessao(user, clientId, needsNameConfirmation);
        }
        return emitirDesafioDoisFatores(user, clientId, needsNameConfirmation);
    }

    Optional<AutenticacaoResponse> exigirDoisFatoresNaAcao(
            Usuario user,
            String clientId,
            String purpose,
            String twoFactorToken,
            String twoFactorCode
    ) {
        if (!user.doisFatoresAtivado()) {
            return Optional.empty();
        }
        if (twoFactorToken == null || twoFactorToken.isBlank() || twoFactorCode == null || twoFactorCode.isBlank()) {
            return Optional.of(emitirDesafioDoisFatores(user, clientId, false, purpose));
        }
        verificarDesafioDoisFatores(user, clientId, purpose, twoFactorToken, twoFactorCode);
        return Optional.empty();
    }

    private AutenticacaoResponse emitirSessao(Usuario user, String clientId, boolean needsNameConfirmation) {
        String refreshToken = tokens.novoToken();
        SessaoRenovacao refreshSession = new SessaoRenovacao(
                user,
                tokens.calcularHash(refreshToken),
                clientId == null || clientId.isBlank() ? null : tokens.calcularHash(clientId),
                SESSION_NEVER_EXPIRES_AT
        );
        sessions.save(refreshSession);
        return new AutenticacaoResponse(
                true,
                UsuarioMapper.respostaUsuario(user),
                accessTokens.emitir(user),
                refreshToken,
                accessTokens.expiraEmSegundos(),
                needsNameConfirmation,
                false,
                null,
                null,
                null
        );
    }

    private AutenticacaoResponse renovarTokenAcesso(Usuario user, String refreshToken) {
        return new AutenticacaoResponse(
                true,
                UsuarioMapper.respostaUsuario(user),
                accessTokens.emitir(user),
                refreshToken,
                accessTokens.expiraEmSegundos(),
                false,
                false,
                null,
                null,
                null
        );
    }

    private AutenticacaoResponse emitirDesafioDoisFatores(Usuario user, String clientId, boolean needsNameConfirmation) {
        return emitirDesafioDoisFatores(user, clientId, needsNameConfirmation, "login");
    }

    private AutenticacaoResponse emitirDesafioDoisFatores(
            Usuario user,
            String clientId,
            boolean needsNameConfirmation,
            String purpose
    ) {
        String method = user.obterMetodoDoisFatores() == null || user.obterMetodoDoisFatores().isBlank()
                ? TWO_FACTOR_EMAIL
                : user.obterMetodoDoisFatores();
        if (!TWO_FACTOR_EMAIL.equals(method)) {
            throw new com.folhio.api.handler.validation.exception.DadosInvalidosException("Método de verificação em duas etapas indisponível.");
        }
        String rawToken = tokens.novoToken();
        String code = novoCodigoDoisFatores();
        DesafioDoisFatores challenge = new DesafioDoisFatores(
                user,
                tokens.calcularHash(rawToken),
                tokens.calcularHash(code),
                clientId == null || clientId.isBlank() ? null : tokens.calcularHash(clientId),
                method,
                purpose,
                needsNameConfirmation,
                Instant.now().plus(twoFactorMinutes, ChronoUnit.MINUTES)
        );
        twoFactorChallenges.save(challenge);
        twoFactorEmailSender.enviar(user, code, purpose);
        return new AutenticacaoResponse(
                true,
                null,
                null,
                null,
                0,
                false,
                true,
                rawToken,
                method,
                mascararEmail(user.obterEmail())
        );
    }

    private DesafioDoisFatores verificarDesafioDoisFatores(
            Usuario expectedUser,
            String clientId,
            String purpose,
            String twoFactorToken,
            String code
    ) {
        DesafioDoisFatores challenge = twoFactorChallenges.buscarPorHashToken(tokens.calcularHash(twoFactorToken))
                .orElseThrow(() -> new com.folhio.api.handler.auth.exception.CodigoSegurancaInvalidoException("Código de segurança inválido ou expirado."));
        if (challenge.obterDataUso() != null
                || challenge.obterDataExpiracao().isBefore(Instant.now())
                || challenge.obterUsuario().estaDesativado()
                || !purpose.equals(challenge.obterFinalidade())
                || (expectedUser != null && challenge.obterUsuario() != expectedUser)) {
            throw new com.folhio.api.handler.auth.exception.CodigoSegurancaInvalidoException("Código de segurança inválido ou expirado.");
        }
        if (challenge.obterHashIdentificadorCliente() != null && !challenge.obterHashIdentificadorCliente().equals(tokens.calcularHash(clientId))) {
            throw new com.folhio.api.handler.auth.exception.CodigoSegurancaInvalidoException("Código de segurança inválido ou expirado.");
        }
        if (!tokens.calcularHash(normalizarCodigoDoisFatores(code)).equals(challenge.obterHashCodigo())) {
            throw new com.folhio.api.handler.auth.exception.CodigoSegurancaInvalidoException("Código de segurança inválido ou expirado.");
        }
        challenge.marcarUsado();
        twoFactorChallenges.save(challenge);
        return challenge;
    }

    private String novoCodigoDoisFatores() {
        return "%06d".formatted(TWO_FACTOR_RANDOM.nextInt(1_000_000));
    }

    private String normalizarCodigoDoisFatores(String code) {
        return code == null ? "" : code.replaceAll("\\D", "");
    }

    private String mascararEmail(String email) {
        String clean = email == null ? "" : email.trim();
        int at = clean.indexOf('@');
        if (at <= 1) {
            return "seu email";
        }
        String local = clean.substring(0, at);
        String domain = clean.substring(at);
        int visible = Math.min(2, local.length());
        return local.substring(0, visible) + "***" + domain;
    }
}
