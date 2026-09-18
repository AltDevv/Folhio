package com.folhio.api.logs;

import java.util.*;

public final class DetalhesRegistroSanitizer {
    private DetalhesRegistroSanitizer() {}
    public static Map<String,Object> limpar(Map<String,Object> dados) {
        return limparMapa(dados==null?Map.of():dados,0);
    }
    private static Map<String,Object> limparMapa(Map<?,?> dados,int nivel) {
        Map<String,Object> resultado=new LinkedHashMap<>();
        dados.entrySet().stream().limit(40).forEach(entrada->{
            String chave=String.valueOf(entrada.getKey());
            String normal=chave.toLowerCase(Locale.ROOT).replaceAll("[^a-z]","");
            boolean segredo=normal.equals("codigo") || normal.matches(".*(password|senha|secret|token|authorization|cookie|apikey|codehash|payload|email).*");
            resultado.put(chave.substring(0,Math.min(chave.length(),100)),
                    segredo?"[oculto]":limparValor(entrada.getValue(),nivel+1));
        });
        return resultado;
    }
    private static Object limparValor(Object valor,int nivel) {
        if(nivel>6) return "[limite de profundidade]";
        if(valor==null || valor instanceof Number || valor instanceof Boolean) return valor;
        if(valor instanceof Map<?,?> mapa) return limparMapa(mapa,nivel);
        if(valor instanceof Iterable<?> lista) {
            List<Object> resultado=new ArrayList<>();
            for(Object item:lista) { if(resultado.size()>=20) break; resultado.add(limparValor(item,nivel+1)); }
            return resultado;
        }
        return textoSeguro(valor.toString());
    }
    public static String textoSeguro(String valor) {
        if(valor==null) return "";
        String texto=valor.replaceAll("(?i)(bearer\\s+)[^\\s,;]+","$1[oculto]")
                .replaceAll("(?i)((?:password|senha|secret|token|api[_-]?key|authorization)\\s*[=:]\\s*)[^\\s,;&]+","$1[oculto]")
                .replaceAll("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}","[email oculto]");
        return texto.substring(0,Math.min(texto.length(),1000));
    }
}
