" --- Obsidian Vimrc Support ---
" This file mimics the Neovim configuration for a seamless transition.

" --- Basic Settings ---
set clipboard=unnamed

" Have j and k navigate visual lines rather than logical ones
nmap j gj
nmap k gk

" --- Leader Key Setup ---
" Unmap Space to use it as a leader key
unmap <Space>

" --- Navigation & Search ---
" Clear search highlights (mimics <leader>/)
exmap nohl obcommand editor:clear-search-highlights
nmap <Space>/ :nohl<CR>

" Scroll and center (mimics <C-d>zz and <C-g>zz)
nmap <C-d> <C-d>zz
" Note: Obsidian doesn't support <C-g> for scrolling up, using <C-u> as alternative
nmap <C-u> <C-u>zz

" Copy entire file (mimics <C-a>)
nmap <C-a> ggVGgy

" --- File Management ---
" Save file (mimics <leader>w)
exmap save obcommand editor:save-file
nmap <Space>w :save<CR>

" Close window (mimics <leader>q)
exmap close obcommand workspace:close-window
nmap <Space>q :close<CR>

" File Explorer (mimics Oil '-')
exmap toggleLeft obcommand app:toggle-left-sidebar
nmap - :toggleLeft<CR>

" Quick Switcher (mimics Telescope <leader>f)
exmap switcher obcommand switcher:open
nmap <Space>f :switcher<CR>

" Global Search (mimics Telescope <leader>gg)
exmap search obcommand global-search:open
nmap <Space>gg :search<CR>

" --- Line Movement ---
" Move lines (visual mode)
" Obsidian's Vim mode doesn't support :m, but we can use native commands
exmap moveLineUp obcommand editor:swap-line-up
exmap moveLineDown obcommand editor:swap-line-down
vmap K :moveLineUp<CR>
vmap J :moveLineDown<CR>

" Move lines (normal mode - Alt+J/K)
nmap <A-j> :moveLineDown<CR>
nmap <A-k> :moveLineUp<CR>

" --- Void Register Simulation ---
" Delete/Paste without yanking (mimics <leader>d and <leader>p)
" We use the black hole register equivalent '_'
nmap <Space>d "_d
vmap <Space>d "_d
nmap <Space>p "_dP
vmap <Space>p "_dP

" --- QoL Features for Obsidian ---

" Better indenting in visual mode
vmap < <gv
vmap > >gv

" Go back/forward in history (standard Vim behavior)
exmap back obcommand app:go-back
nmap <C-o> :back<CR>
exmap forward obcommand app:go-forward
nmap <C-i> :forward<CR>

" Surround support (requires plugin)
" exmap surround_wiki surround [[ ]]
" exmap surround_double_quotes surround " "
" exmap surround_single_quotes surround ' '
" exmap surround_backticks surround ` `
" exmap surround_brackets surround ( )
" exmap surround_square_brackets surround [ ]
" exmap surround_curly_brackets surround { }
" exmap surround_bold surround ** **
" exmap surround_italic surround * *
" exmap surround_highlight surround == ==
" exmap surround_strike surround ~~ ~~

" Visual mode surround mappings
vmap [[ :surround_wiki<CR>
vmap s" :surround_double_quotes<CR>
vmap s' :surround_single_quotes<CR>
vmap s` :surround_backticks<CR>
vmap sb :surround_brackets<CR>
vmap s[ :surround_square_brackets<CR>
vmap s{ :surround_curly_brackets<CR>
vmap s* :surround_bold<CR>
vmap s_ :surround_italic<CR>
vmap s= :surround_highlight<CR>
vmap s~ :surround_strike<CR>

" Follow link (mimics gd in Neovim)
exmap followLink obcommand editor:follow-link
nmap gd :followLink<CR>

" Daily Notes
exmap daily obcommand daily-notes
nmap <Space>dn :daily<CR>

" Graph View
exmap graph obcommand graph:open
nmap <Space>gV :graph<CR>

" --- LSP-like features ---
" Rename (mimics <leader>rn)
exmap rename obcommand file-explorer:rename-file
nmap <Space>rn :rename<CR>
