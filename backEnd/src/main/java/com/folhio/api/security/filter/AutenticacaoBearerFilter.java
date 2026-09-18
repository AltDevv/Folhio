package com.folhio.api.security.filter;

import com.folhio.api.security.authentication.TokenAcessoService;
import com.folhio.api.security.authentication.UsuarioAutenticado;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
public class AutenticacaoBearerFilter implements Filter {
    private final TokenAcessoService accessTokenService;

    public AutenticacaoBearerFilter(TokenAcessoService accessTokenService) {
        this.accessTokenService = accessTokenService;
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        String path = httpRequest.getRequestURI();
        if (path == null || !path.startsWith("/api/folhio/")) {
            chain.doFilter(request, response);
            return;
        }
        String authorization = httpRequest.getHeader("Authorization");
        if (authorization == null || authorization.isBlank()) {
            chain.doFilter(request, response);
            return;
        }
        if (!authorization.startsWith("Bearer ")) {
            chain.doFilter(request, response);
            return;
        }
        try {
            UsuarioAutenticado user = accessTokenService.validar(authorization.substring(7).trim());
            httpRequest.setAttribute(UsuarioAutenticado.REQUEST_ATTRIBUTE, user);
        } catch (com.folhio.api.handler.auth.exception.SessaoExpiradaException error) {
            com.folhio.api.handler.RespostaErro.escrever(401, "SESSAO_EXPIRADA",
                    "Sua sessao expirou. Entre novamente.", httpRequest, httpResponse);
            return;
        } catch (com.folhio.api.handler.auth.exception.SessaoInvalidaException | IllegalArgumentException error) {
            com.folhio.api.handler.RespostaErro.escrever(401, "SESSAO_INVALIDA",
                    "Sessao invalida. Entre novamente.", httpRequest, httpResponse);
            return;
        } catch (RuntimeException error) {
            com.folhio.api.handler.RespostaErro.escrever(503, "AUTENTICACAO_INDISPONIVEL",
                    "O servico de autenticacao esta indisponivel no momento.", httpRequest, httpResponse);
            return;
        }
        chain.doFilter(request, response);
    }

}
