#! /usr/bin/env bash

# Color definitions
text="#e6d9d4"
blue="#a9d4ff"
peach="#da9367"

tmux menu \
    -T "#[fg=${blue},bold] menu " \
    -b rounded \
    -s "fg=${text}" \
    -S "fg=${peach}" \
    -H "fg=${text}" \
    "abrir nota"      n "neww -n nota ~/.config/scripts/tmux/menu/abrir-nota.sh" \
    "criar nota"      N "neww -n nota ~/.config/scripts/tmux/menu/criar-nota.sh" \
    "" "" "" \
    "nvim file"       p "neww -n nvim ~/.config/scripts/tmux/menu/nvim-file.sh" \
    "nvim dir"        P "neww -n nvim ~/.config/scripts/tmux/menu/nvim-dir.sh" \
    "" "" "" \
    "abrir sessão"    s "neww -n session ~/.config/scripts/tmux/menu/abrir-sessao.sh" \
    "criar sessão"    S "neww -n session ~/.config/scripts/tmux/menu/criar-sessao.sh" \
    "deletar sessão"  d "neww -n session ~/.config/scripts/tmux/menu/deletar-sessao.sh" \
    "renomear sessão" r "command-prompt -p 'rename session to:' 'rename-session %%'" \
    "" "" "" \
    "abrir dir"       f "neww -n files ~/.config/scripts/tmux/menu/abrir-dir.sh" \
    "clonar pwd"      F "neww -c "#{pane_current_path}"" \
    "" "" "" \
    "man"             m "neww -n man ~/.config/scripts/tmux/menu/man.sh"\
    "go doc"          g "neww -n man ~/.config/scripts/tmux/menu/go-doc.sh"
