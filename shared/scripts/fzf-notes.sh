#!/usr/bin/env bash

NOTES_DIR="$HOME/personal/notas/"

entrar_tmux(){
    local arquivo="$1"
    
    # 1. Correção de Lógica: O nome da sessão deve ser consistente. 
    # Removemos a extensão .md para o nome da sessão.
    local nome_sem_extensao=$(echo "$arquivo" | sed 's/\.[^.]*$//')
    local nome_sessao="notas/$nome_sem_extensao"

    # 2. Verifica se a sessão existe
    if tmux has-session -t "$nome_sessao" 2>/dev/null; then
        # Verifica se já está dentro do tmux para não dar erro de aninhamento
        if [ -n "$TMUX" ]; then
            tmux switch-client -t "$nome_sessao"
        else
            tmux attach -t "$nome_sessao"
        fi
        exit 0
    fi

    local diretorio=$(dirname "$arquivo")
    local nome_arquivo=$(basename "$arquivo")

    # 3. Cria a sessão em background (-d)
    # Usa o caminho completo para o diretório de trabalho (-c)
    tmux new-session -d -s "$nome_sessao" -c "${NOTES_DIR}${diretorio}" "nvim '$nome_arquivo'"

    # 4. Conecta na sessão recém-criada
    if [ -n "$TMUX" ]; then
        tmux switch-client -t "$nome_sessao"
    else
        tmux attach -t "$nome_sessao"
    fi
}

# 5. Correção de Sintaxe: $(( )) é para matemática. $() é para comandos.
# Melhoramos o sed para remover o NOTES_DIR independentemente da profundidade.
destino=$( (
    echo "nova"
    fd . "$NOTES_DIR"
) | sed "s|^$NOTES_DIR||" | fzf )

# Se cancelar o fzf, sai do script
[ -z "$destino" ] && exit 0

if [ "$destino" = "nova" ]; then
    echo "Insira o nome da pasta/nota: (sem extensão)"
    read -r nova_nota
    
    # Se der enter vazio, sai
    [ -z "$nova_nota" ] && exit 1

    # Cria o diretório (caso tenha subpastas ex: diario/hoje)
    mkdir -p "$(dirname "${NOTES_DIR}${nova_nota}.md")"
    
    entrar_tmux "${nova_nota}.md"
    exit 0
fi

entrar_tmux "$destino"
