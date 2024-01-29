" paste directly from the OS clipboard to Neovim using Neovim paste keystroke
set clipboard+=unnamedplus
set timeoutlen=200

" Disable arrow keys
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

" no swap file
set noswapfile

" save undo-trees in files
set undofile
set undodir=$HOME/.config/nvim/undo

" number of undo saved
set undolevels=10000
set undoreload=10000

" set line number
set number

" use 2 spaces instead of tab ()
" copy indent from current line when starting a new line
set autoindent
set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2

" Leader Key
nnoremap <space> <nop>
let mapleader = "\<space>"

" Leader Key example
nnoremap <leader>bn :bn<CR> ;buffer next
nnoremap <leader>tn gt ;new tab

" Apply on current file
nnoremap <leader>x :!chmod u+x %<CR>

" Centering automatically
" source: https://stackoverflow.com/a/16136133/9103915
" augroup VCenterCursor
"   au!
"   au BufEnter,WinEnter,WinNew,VimResized *,*.*
"         \ let &scrolloff=winheight(win_getid())/2
" augroup END

" Disable search highlight
" nnoremap <nowait><silent> <C-C> :noh<CR>

" Add a new line and preserve cursor position
" when opening newlines into differnt levels
" source: https://stackoverflow.com/a/16136133/9103915
nmap oo m`o<Esc>``
nmap OO m`O<Esc>``
