package com.folhio.api.enums;

public enum AcaoAuditoria {
    LOGIN, UPLOAD, DOWNLOAD, GENERATE_FILE, DELETE_FILE, FILE_BLOCKED,
    CREATE_LAYOUT, UPDATE_LAYOUT, DELETE_LAYOUT, LOGOUT, UPDATE_ACCOUNT, DELETE_ACCOUNT;

    public String obterDescricao() {
        return switch(this) {
            case LOGIN -> "Entrada na conta confirmada";
            case LOGOUT -> "Sessao encerrada";
            case UPLOAD -> "Arquivo recebido e armazenado";
            case DOWNLOAD -> "Transferencia do arquivo iniciada";
            case GENERATE_FILE -> "Novo arquivo gerado";
            case DELETE_FILE -> "Arquivo excluido";
            case FILE_BLOCKED -> "Arquivo bloqueado por seguranca";
            case CREATE_LAYOUT -> "Layout de material criado";
            case UPDATE_LAYOUT -> "Layout de material atualizado";
            case DELETE_LAYOUT -> "Layout de material excluido";
            case UPDATE_ACCOUNT -> "Dados da conta atualizados";
            case DELETE_ACCOUNT -> "Conta excluida";
        };
    }
}
