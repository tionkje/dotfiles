" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin(stdpath('data') . '/plugged')

Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

Plug 'Yggdroot/indentLine' "show indent line thingy

Plug 'tomtom/tcomment_vim' " do commenting

Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Initialize plugin system
call plug#end()



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

set nobackup
set nowritebackup
" set backup
" set backupdir=~/.vim/backup//,/tmp//
" set writebackup

set directory=~/.vim/swap//,/tmp//
set undodir=~/.vim/undo//,/tmp//
set undofile

set backspace=2 "allow backspace over eol, indent and start of insert

" Give more space for displaying messages.
set cmdheight=2


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


""""" stuff for COC """"""""""
" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

"""""""""""""""""""""""""""""""""

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
