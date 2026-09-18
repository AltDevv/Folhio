package com.folhio.api.dto.layout;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;
import java.time.Instant;

public final class LayoutDtos {
    private LayoutDtos() {}
    public record LayoutRequest(
            @NotBlank @Size(max=120) String nome,
            @Size(max=500) String descricao,
            @NotNull Long versao,
            boolean publicado,
            @NotEmpty @Size(max=20) List<@NotNull @Valid Pagina> paginas) {}
    public record Pagina(@NotBlank @Size(max=80) String id,
            @NotNull @Size(max=100) List<@NotNull @Valid Bloco> blocos) {}
    public record Bloco(
            @NotBlank @Size(max=80) String id,
            @Pattern(regexp="titulo|texto|enunciado|imagem|alternativas|resposta|cabecalho") @NotNull String tipo,
            @NotBlank @Size(max=100) String nome,
            @Pattern(regexp="[a-zA-Z][a-zA-Z0-9_.]{0,99}|") @NotNull String campo,
            @NotNull @Size(max=4000) String texto,
            @NotNull @Size(max=1000) String instrucao,
            @DecimalMin("0") @DecimalMax("210") double x,
            @DecimalMin("0") @DecimalMax("297") double y,
            @DecimalMin("5") @DecimalMax("210") double largura,
            @DecimalMin("5") @DecimalMax("297") double altura,
            @Min(8) @Max(48) int fonte,
            @Pattern(regexp="left|center|right") @NotNull String alinhamento,
            boolean borda) {}
    public record LayoutResponse(String id, String nome, String descricao, long versao,
            boolean publicado, Instant atualizadoEm, List<Pagina> paginas, int schemaVersion) {}
}
