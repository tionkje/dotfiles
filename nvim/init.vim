" let g:vim_svelte_plugin_load_full_syntax = 1
" let g:vim_svelte_plugin_use_typescript = 1
" let g:svelte_preprocessors = ['typescript']

" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
" Automatically install vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(data_dir . '/plugins')

Plug 'github/copilot.vim'

Plug 'Yggdroot/indentLine' "show indent line thingy

Plug 'tomtom/tcomment_vim' " do commenting
" Plug 'tpope/vim-commentary' " do commenting

" FZF {{{
  Plug 'junegunn/fzf'
  Plug 'junegunn/fzf.vim'
  if isdirectory(".git")
    " if in a git project, use :GFiles
    nmap <silent> <c-p> :GitFiles --cached --others --exclude-standard<cr>
  else
    " otherwise, use :FZF
    nmap <silent> <c-p> :FZF<cr>
  endif


  " " alternative CtrlP
  " nnoremap <c-p> :Files<CR>
  nnoremap <leader>rg :Ag<CR>
" }}}


" vim-fugitive {{{
    Plug 'tpope/vim-fugitive'
    nmap <silent> <leader>gs :Git status<cr>
    nmap <leader>ge :Git edit<cr>
    nmap <silent><leader>gr :Git read<cr>
    nmap <silent><leader>gb :Git blame<cr>

    Plug 'tpope/vim-rhubarb' " hub extension for fugitive
    Plug 'sodapopcan/vim-twiggy'
    Plug 'rbong/vim-flog'
" }}}

" https://github.com/nicknisi/dotfiles/blob/master/config/nvim/init.vim
    " coc {{{

Plug 'neoclide/coc.nvim', {'branch': 'release'}

Plug 'neoclide/coc-vetur'

" lsp
Plug 'neovim/nvim-lspconfig'

 let g:coc_global_extensions = [
        \ 'coc-css',
        \ 'coc-json',
        \ 'coc-git',
        \ 'coc-eslint',
        \ 'coc-sh',
        \ 'coc-vimlsp',
        \ 'coc-prettier',
        \ 'coc-tsserver',
        \ 'coc-svelte',
        \ 'coc-vetur',
        \ ]
        "
        " \ 'coc-tslint-plugin',
        " \ 'coc-pairs',
        " \ 'coc-emmet',
        " \ 'coc-ultisnips',
        " \ 'coc-explorer',
        " \ 'coc-diagnostic'

   " JavaScript {{{
        " Plug 'othree/yajs.vim', { 'for': [ 'javascript', 'javascript.jsx', 'html' ] }
        " Plug 'pangloss/vim-javascript', { 'for': ['javascript', 'javascript.jsx', 'html'] }
        Plug 'moll/vim-node', { 'for': 'javascript' }
        Plug 'ternjs/tern_for_vim', { 'for': ['javascript', 'javascript.jsx'], 'do': 'npm install' }
        Plug 'MaxMEllon/vim-jsx-pretty'
        let g:vim_jsx_pretty_highlight_close_tag = 1
    " }}}

    " TypeScript {{{
        Plug 'leafgarland/typescript-vim', { 'for': ['typescript', 'typescript.tsx'] }
        " Plug 'Shougo/vimproc.vim', { 'do': 'make' } TODO what still needs this?
    " }}}
    
    " Svelte {{{
        " Plug 'sheerun/vim-polyglot'
        " Plug 'evanleck/vim-svelte', {'branch': 'main'}
        Plug 'leafOfTree/vim-svelte-plugin'
        " Plug 'Shougo/context_filetype.vim'
    " }}}
    
    " Nix {{{
    Plug 'LnL7/vim-nix'
    " }}}

" Initialize plugin system
call plug#end()

" if !exists('g:context_filetype#same_filetypes')
"   let g:context_filetype#filetypes = {}
" endif
"
" let g:context_filetype#filetypes.svelte =
" \ [
" \   {'filetype' : 'javascript', 'start' : '<script>', 'end' : '</script>'},
" \   {
" \     'filetype': 'typescript',
" \     'start': '<script\%( [^>]*\)\? \%(ts\|lang="\%(ts\|typescript\)"\)\%( [^>]*\)\?>',
" \     'end': '',
" \   },
" \   {'filetype' : 'css', 'start' : '<style \?.*>', 'end' : '</style>'},
" \ ]
"
" let g:ft = ''

" https://github.com/leafOfTree/vim-svelte-plugin/issues/10?ts=2
" Set local options based on subtype
function! OnChangeSvelteSubtype(subtype)
  echom 'Subtype is '.a:subtype
  if empty(a:subtype) || a:subtype == 'html'
    setlocal commentstring=<!--%s-->
    setlocal comments=s:<!--,m:\ \ \ \ ,e:-->
  elseif a:subtype =~ 'css'
    setlocal comments=s1:/*,mb:*,ex:*/ commentstring&
  else
    setlocal commentstring=//%s
    setlocal comments=sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/,://
  endif
endfunction


set number
set nocompatible
set showcmd " show partial commands
 "Set tabs to 2 spaces and auto insert spaces http://vimcasts.org/episodes/tabs-and-spaces/
set ts=2 sts=2 sw=2 expandtab
"http://vimcasts.org/episodes/whitespace-preferences-and-filetypes/

" remember more history than default 20
set history=10000

function TabsOrSpaces()
    " Determines whether to use spaces or tabs on the current buffer.
    if getfsize(bufname("%")) > 256000
        " File is very large, just use the default.
        return
    endif

    let numTabs=len(filter(getbufline(bufname("%"), 1, 250), 'v:val =~ "^\\t"'))
    let numSpaces=len(filter(getbufline(bufname("%"), 1, 250), 'v:val =~ "^ "'))

    if numTabs > numSpaces
        setlocal noexpandtab
    endif
endfunction

" Call the function after opening a buffer
autocmd BufReadPost * call TabsOrSpaces()


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
set cmdheight=1


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

" auto save changes after updatetime idle
autocmd CursorHold * silent! update
autocmd VimSuspend * silent! update
" check file changed on insert 
autocmd InsertEnter * checktime

autocmd bufwritepost ~/.config/nvim/init.vim source $MYVIMRC

" set non modifieable if read only
autocmd BufRead * let &l:modifiable = !&readonly


""""" stuff for COC """"""""""
" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=200

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
" inoremap <silent><expr> <TAB>
"       \ pumvisible() ? "\<C-n>" :
"       \ <SID>check_back_space() ? "\<TAB>" :
"       \ coc#refresh()
" inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

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
" inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
"                               \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"


" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1):
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"



" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> gq <Plug>(coc-float-hide)
nmap <silent> gf <Plug>(coc-refactor)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-cursor)
nmap <leader>a  <Plug>(coc-codeaction-cursor)

command! -nargs=0 Prettier :CocCommand prettier.formatFile
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>F  <Plug>(coc-format)

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

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

" prevent Ctrl+J in insert mode
inoremap <C-J> <Esc>

" disable copy(yank) on paste in visual
vnoremap p pgvy

" edit files
nmap <leader>ev :tabedit $MYVIMRC<CR>  
nmap <leader>et :tabedit ~/.tmux.conf<CR> 
nmap <leader>ep :tabedit push.sh<CR> 
" \s to save all and run local push.sh
nmap <leader>s :wa<CR>:!$SHELL ./push.sh<CR><CR>
nmap <leader>S :wa<CR>:!$SHELL ./push.sh<CR>
nmap <leader>t :wa<CR>:!$SHELL ./push.sh test<CR>


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
au BufRead,BufNewFile *.svelte set filetype=svelte
au BufRead,BufNewFile *.cjs set filetype=javascript
au BufRead,BufNewFile *.mjs set filetype=javascript
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
highlight CocFadeOut    guifg=grey

" === STATUSLINE === " Needs to come after colorscheme or colors get reset
set laststatus=2 " always show statusline
"define 3 custom highlight groups
" hi User1 guibg=#268bd2 guifg=#ffffff ctermbg=27 ctermfg=15
" hi User2 guibg=NONE guifg=#268bd2 ctermbg=0 ctermfg=blue
" hi User3 guibg=#268bd2 guifg=#82b414 ctermbg=blue  ctermfg=green

if version >= 700
  augroup NrHighlight
    autocmd!
    " highlight the status bar when in insert mode
    " au InsertEnter * hi User2 guibg=#82b414
    " au InsertLeave * hi User2 guibg=NONE

    au InsertEnter * hi StatusLine guifg=#82b414
    au InsertLeave * hi StatusLine guifg=#268bd2

    " au WinEnter * hi User1 guibg=#268bd2
    " au WinLeave * hi User1 guibg=NONE
  augroup END
endif

set ruler " uverruled by statusline
set statusline=
set statusline+=\ %f\ [%n]\ %3*%(\ %R%M\ %)\%*    "switch to User1 highlight "full filename modified, readonly
set statusline+=%(%1*\ %Y%W%)\   "filetype, preview

"Syntastic
" set statusline+=%1*%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*


set statusline+=%2*\ %=     "right side
" set statusline+=%*\ %b\        "char under cursor
set statusline+=%1*\   " color
set statusline+=%l:%c\    "column number
set statusline+=%0*   "switch back to statusline highlight
set statusline+=\ %P\ %L\    "percentage thru file
" ================== "


" nnoremap <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
" \ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
" \ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

function! SynGroup()                                                            
    let l:s = synID(line('.'), col('.'), 1)                                       
    echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
endfun

nnoremap <leader>d :call SynGroup()<CR>
