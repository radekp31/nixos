" /etc/nixos/common-nvim.vim

" Load the TokyoNight colorscheme
" packadd tokyonight-nvim

colorscheme tokyonight-night

" Other common settings can go here
set number         " Show line numbers
set relativenumber " Show relative line numbers
au VimLeavePre * silent! :!clear
