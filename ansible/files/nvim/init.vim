
set number
set nocompatible
set showcmd " show partial commands
 "Set tabs to 2 spaces and auto insert spaces http://vimcasts.org/episodes/tabs-and-spaces/
set ts=2 sts=2 sw=2 expandtab
"http://vimcasts.org/episodes/whitespace-preferences-and-filetypes/
syntax on " syntax highlighting
set termguicolors

" Also switch on highlighting the last used search pattern.
set hlsearch
set incsearch

set autoindent " always set autoindenting on
set backup
set backupdir=~/.vim/backup//,/tmp//
set directory=~/.vim/swap//,/tmp//
set undodir=~/.vim/undo//,/tmp//
set undofile
set writebackup

set backspace=2 "allow backspace over eol, indent and start of insert


" better wildmode for Tab Completion in commands
set wildmode=longest:full,full
set wildmenu

set mouse=a
set hidden "http://stackoverflow.com/questions/102384/using-vims-tabs-like-buffers

" shortcut to toggle paste
set pastetoggle=<F8>

""" Show whitespaces """
set list
" Use the same symbols as TextMate for tabstops and EOLs
set listchars=tab:▸\ ,eol:¬,trail:.
"""""""""""""""""""""""

" netrw settings for preview
let g:netrw_preview   = 1
let g:netrw_liststyle = 3
let g:netrw_winsize   = 30
" split vertically to the right
let g:netrw_altv   = 1



" move to beginning of commandline using Ctrl+A
cnoremap <C-A> <Home>
" resize window to a third
nnoremap <silent> <Leader>+ :exe "resize " . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "resize " . (winheight(0) * 2/3)<CR>
nnoremap <silent> <Leader>> :exe "vertical resize " . (winwidth(0) * 3/2)<CR>
nnoremap <silent> <Leader>< :exe "vertical resize " . (winwidth(0) * 2/3)<CR>

" edit files
nmap <leader>ev :tabedit $MYVIMRC<CR>  
nmap <leader>et :tabedit ~/.tmux.conf<CR> 
nmap <leader>ep :tabedit push.sh<CR> 
" \s to save all and run local push.sh
nmap <leader>s :wa<CR>:!./push.sh<CR><CR>
nmap <leader>S :wa<CR>:!./push.sh<CR>
nmap <leader>t :wa<CR>:!./push.sh test<CR>


" removes crap to easy copy stuff
function! CopyMode()
  set number!
  set list!
  IndentLinesToggle
  " !IndentLine
  echo "use :only to close other panes"
endfunction
command! CopyMode call CopyMode()



" Use Ag over Grep
set grepprg=ag\ --nogroup\ --nocolor
autocmd QuickFixCmdPost *grep* cwindow


" associate jakeFile with javascript filetype
" au BufRead,BufNewFile jakefile setfiletype javascript
" au BufRead,BufNewFile *.ejs set filetype=html
" au BufRead,BufNewFile *.vue set filetype=html
" au BufRead,BufNewFile *.svelte set filetype=html
" au BufRead,BufNewFile *.ts set filetype=typescript
" au BufRead,BufNewFile *.njk set filetype=jinja
" au BufRead,BufNewFile *.vue setfiletype vue
" autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o


" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif


" have Vim jump to the last position when reopening a file
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif


" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin(stdpath('data') . '/plugged')

Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

Plug 'Yggdroot/indentLine' "show indent line thingy

Plug 'tomtom/tcomment_vim' " do commenting

" Initialize plugin system
call plug#end()


let g:indentLine_faster = 1
" let g:indentLine_setConceal = 0
" let g:indentLine_noConcealCursor=""
let g:indentLine_concealcursor=""


colorscheme Tomorrow-Night-Bright

" === STATUSLINE === " Needs to come after colorscheme or colors get reset
set laststatus=2 " always show statusline
"define 3 custom highlight groups
hi User1 guibg=#268bd2 guifg=#ffffff ctermbg=27 ctermfg=15
hi User2 guibg=#000000 guifg=#268bd2 ctermbg=0 ctermfg=blue
hi User3 guibg=#268bd2 guifg=#82b414 ctermbg=blue  ctermfg=green

if version >= 700
  augroup NrHighlight
    autocmd!
    " highlight the status bar when in insert mode
    au InsertEnter * hi User2 guibg=#82b414 ctermfg=15 ctermbg=2
    au InsertLeave * hi User2 guibg=#000000 ctermfg=15 ctermbg=0
    " au WinEnter * hi User2 ctermfg=15 ctermbg=27
    " au WinLeave * hi User2 ctermfg=15 ctermbg=0
  augroup END
endif

set ruler " uverruled by statusline
set statusline=
set statusline+=%1*\ %F\ [%n]%(\ %M%R%)\    "switch to User1 highlight "full filename modified, readonly
set statusline+=%(%*\ %Y%W%)   "filetype, preview

"Syntastic
set statusline+=%1*%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

set statusline+=\ %2*%=     "right side
" set statusline+=%*\ %b\        "char under cursor
set statusline+=%1*\   " color
set statusline+=%l:%c\    "column number
" set statusline+=%1*\ %l/%L  "line number
" set statusline+=:%c\    "column number
set statusline+=%*   "switch back to statusline highlight
set statusline+=\ %P\ %L\    "percentage thru file
" ================== "
