package com.folhio.api.common.util;

import java.util.List;
import java.util.Map;
import java.util.ArrayList;

public final class MapasJson {

    private MapasJson() {
    }

    public static Map<String, Object> filho(Map<String, Object> map, String key) {
        Object value = map == null ? null : map.get(key);
        if (value instanceof Map<?, ?> child) {
            @SuppressWarnings("unchecked")
            Map<String, Object> typed = (Map<String, Object>) child;
            return typed;
        }
        return Map.of();
    }

    public static List<?> listar(Map<String, Object> map, String key) {
        Object value = map == null ? null : map.get(key);
        return value instanceof List<?> list ? list : List.of();
    }

    public static String texto(Map<String, Object> map, String key, String fallback) {
        Object value = map == null ? null : map.get(key);
        return value == null ? fallback : value.toString();
    }

    public static int inteiro(Map<String, Object> map, String key, int fallback) {
        Object value = map == null ? null : map.get(key);
        if (value instanceof Number number) {
            return number.intValue();
        }
        if (value != null) {
            try {
                return Integer.parseInt(value.toString());
            } catch (NumberFormatException ignored) {
                return fallback;
            }
        }
        return fallback;
    }

    public static double decimal(Map<String, Object> map, String key, double fallback) {
        Object value = map == null ? null : map.get(key);
        if (value instanceof Number number) {
            return number.doubleValue();
        }
        if (value != null) {
            try {
                return Double.parseDouble(value.toString());
            } catch (NumberFormatException ignored) {
                return fallback;
            }
        }
        return fallback;
    }

    public static boolean booleano(Map<String, Object> map, String key, boolean fallback) {
        Object value = map == null ? null : map.get(key);
        if (value instanceof Boolean bool) {
            return bool;
        }
        if (value != null) {
            return Boolean.parseBoolean(value.toString());
        }
        return fallback;
    }

    public static List<Integer> listaInteiros(Map<String, Object> map, String key) {
        List<Integer> values = new ArrayList<>();
        for (Object item : listar(map, key)) {
            if (item instanceof Number number) {
                values.add(number.intValue());
            } else if (item != null) {
                values.add(Integer.parseInt(item.toString()));
            }
        }
        return values;
    }

    public static String comExtensao(String fileName, String extension) {
        int dot = fileName.lastIndexOf('.');
        String base = dot > 0 ? fileName.substring(0, dot) : fileName;
        return base + "." + extension;
    }
}
