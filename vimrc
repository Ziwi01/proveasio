"Change CWD to where we are before running vim/NT (not working)
" TODO: check why
"autocmd BufEnter * silent! lcd !echo $PWD
autocmd BufEnter * lcd $PWD
set autochdir
autocmd VimEnter * set autochdir
let g:NERDTreeChDirMode=2
let NERDTreeChDirMode=2

" Open NerdTree always
autocmd vimenter * NERDTree
" Select opened file instead of NT
autocmd VimEnter * wincmd p

" copy (write) highlighted text to .vimbuffer (For WSL<-> Windows clipboard integration)
vmap <C-c> :w! ~/.vimbuffer \| !cat ~/.vimbuffer \| clip.exe <CR><CR>

" Turn on system clipboard support
set clipboard=unnamed

" Disable compatible mode
set nocompatible

" Set language
set langmenu=en_US.UTF-8
if has("win32")
  language en
endif

" Apply defaults everyone wants
source $VIMRUNTIME/vimrc_example.vim

" Vundle for plugin management
" Install if not present
" IMPORTANT: works in CLI version only.
cd $HOME
let i_have_vundle=1
let vundle_readme=expand('.vim/bundle/Vundle.vim/README.md')
if !filereadable(vundle_readme)
  echo "Installing Vundle.."
  echo ""
  silent !mkdir -p .vim/bundle
  silent !mkdir -p .vim/tmp
  silent !mkdir -p .vim/backup
  silent !git clone https://github.com/VundleVim/Vundle.vim .vim/bundle/Vundle.vim
  let i_have_vundle=0
endif

" Automatic plugin installation
filetype off
set rtp+=$HOME/.vim/bundle/Vundle.vim
call vundle#begin('$HOME/.vim/bundle/')
Plugin 'VundleVim/Vundle.vim'             "Plugin manager
Plugin 'Ziwi01/ide.vim'                  "Main vimrc configuration
Plugin 'ctrlpvim/ctrlp.vim'               "Buffer Control
Plugin 'scrooloose/nerdtree'              "File manager
Plugin 'Xuyuanp/nerdtree-git-plugin'      "Git highlight for NerdTree
Plugin 'w0rp/ale'                         "Syntax Checker
Plugin 'rodjek/vim-puppet'                "Puppet syntax support
Plugin 'tpope/vim-fugitive'               "git support
Plugin 'tpope/vim-unimpaired'             "Quick switch over mappings
Plugin 'tpope/vim-surround'               "Easy surround changes
Plugin 'tpope/vim-dispatch'               "Run async commands
Plugin 'ludovicchabant/vim-gutentags'     "Generate c-tags
Plugin 'irrationalistic/vim-tasks'        "Todo list
Plugin 'airblade/vim-gitgutter'           "Enable gitgutter
Plugin 'lifepillar/vim-mucomplete'        "Completeion Engine
Plugin 'godlygeek/tabular'                "auto tab
Plugin 'plasticboy/vim-markdown'          "Support for markdown docs
Plugin 'Yggdroot/indentLine'              "Indent line
Plugin 'gilsondev/searchtasks.vim'        "Search tasks: TODO, FIXME, etc.
Plugin 'tpope/vim-endwise'                "Auto end functions
Plugin 'python-mode/python-mode'          "Support for Python
Plugin 'vim-ruby/vim-ruby'                "Support for Ruby
Plugin 'tomtom/tcomment_vim'              "Easy comment
Plugin 'sukima/xmledit'                   "Xml support
Plugin 'airblade/vim-rooter'              "Change root to .git directory
Plugin 'tpope/vim-obsession'              "Session management, intagration with tmux
Plugin 'editorconfig/editorconfig-vim'    "Editorconfig for keeping files neat
Plugin 'maxbrunsfeld/vim-yankstack'       "Enable windows buffer copy with CTRL+C - used with Windows WSL
Plugin 'noprompt/vim-yardoc'              "YARD docs higlight
if i_have_vundle == 0
  echo "Installing Vundles, please ignore key map error messages"
  echo ""
  :PluginInstall
endif
call vundle#end()

" Enable filetype for autocmd
filetype plugin indent on

" Source main config file for windows
if has("win32")
  " Fix for vimdiff on windows
  set diffexpr=MyDiff()
  function MyDiff()
    let opt = '-a --binary '
    if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
    if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
    let arg1 = v:fname_in
    if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
    let arg2 = v:fname_new
    if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
    let arg3 = v:fname_out
    if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
    if $VIMRUNTIME =~ ' '
      if &sh =~ '\<cmd'
        if empty(&shellxquote)
          let l:shxq_sav = ''
          set shellxquote&
        endif
        let cmd = '"' . $VIMRUNTIME . '\diff"'
      else
        let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
      endif
    else
      let cmd = $VIMRUNTIME . '\diff'
    endif
    silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3
    if exists('l:shxq_sav')
      let &shellxquote=l:shxq_sav
    endif
  endfunction
endif

" Set files and directories
set directory=~/.vim/tmp
set backupdir=~/.vim/backup
set viminfo+='1000,n~/.vim/viminfo

" Enable syntax higlight
syntax on

" Set background
set background=dark

" Disable visual bell
set noerrorbells visualbell t_vb=
autocmd GUIEnter * set visualbell t_vb=

" Reread file if was changed
set autoread

" Enable better histroy
set history=10000

" Make sure that we confirm on unsaved files
set confirm

" Better lists
set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+

" Max tab pages
set tabpagemax=50

" Make sure that undofiles are not scatterd
set undodir=~/.vim/undofiles

" Make sure that GVim is in English
set langmenu=en_US
let $LANG = 'en_US'
source $VIMRUNTIME/delmenu.vim
source $VIMRUNTIME/menu.vim

" Work mostly on unix files
set fileformat=unix
set fileformats=unix,dos

" Set font for Gvim
set guifont=Consolas:h9

" Disable mouse tips
"set guioptions-=T

" Disable gvim menus ant toolbars
set go-=m
set go-=T
set go-=r
set go-=L

" Search options
set hlsearch
set incsearch

" Setup encoding for cygwin mostly
setglobal fileencoding=utf-8
set encoding=utf-8
set fileencodings=utf-8
set termencoding=utf-8

" Improve backspace
set backspace=indent,eol,start

" Set update to get faster results with plugins (default i 14400 = 4sec)
set updatetime=250

" Display completion matches in statusline
set wildmenu

" Set path to look into all subdirectories
set path+=**

" Auto line wrapping
set tw=220

" Delete comment character when joining commented lines
set formatoptions+=j

" Line numbers
set number

" Set standard textwidth
set textwidth=220

" Always show one line blow/above cursor
if !&scrolloff
  set scrolloff=1
endif
if !&sidescrolloff
  set sidescrolloff=5
endif
set display+=lastline

" Tab config
set smartindent
set autoindent
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab

" Make diff split vertically
set diffopt+=vertical

" Use <C-L> to clear the highlighting of :set hlsearch.
if maparg('<C-L>', 'n') ==# ''
  nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>
endif

" Syntax Highlight sync
autocmd BufEnter * :syntax sync fromstart

" Shortcuts
nnoremap tw :%s/\s\+$//<CR>:noh<CR>
nnoremap go :tabnew<CR>

" QuickFixWindow
autocmd QuickFixCmdPost [^l]* copen 15
autocmd QuickFixCmdPost    l* lopen 15
noremap to :copen 25<cr>
noremap tc :cclose<cr>

" netrw configuratoin
nnoremap tf :Explore<CR>
let g:netrw_fastbrowse     = 0
let g:netrw_banner         = 0
let g:netrw_preview        = 1
let g:netrw_winsize        = 25
let g:netrw_altv           = 1
let g:netrw_fastbrowse     = 2
let g:netrw_keepdir        = 0
let g:netrw_liststyle      = 1
let g:netrw_retmap         = 1
let g:netrw_silent         = 1
let g:netrw_special_syntax = 1

" Session manager
set sessionoptions-=blank
map <F2> :mksession! ~/.vim/vim_session <cr>
map <F3> :source ~/.vim/vim_session <cr>

" Turn on omni-completion
set omnifunc=syntaxcomplete#Complete
set completeopt+=longest,menuone,noinsert,noselect
let OmniCpp_GlobalScopeSearch = 1
let OmniCpp_DisplayMode = 1
let OmniCpp_ShowAccess = 1
set shortmess+=c
" Disable to scan inlucdes and tags since it tends to work very slow
set complete-=i
set complete-=t

" Set colorscheme
colorscheme bugi

" MUcomplete
let g:mucomplete#enable_auto_at_startup = 1
let g:mucomplete#chains = {
      \ 'default' : ['path', 'omni', 'keyn', 'keyp', 'c-n', 'c-p', 'uspl', 'tags' ],
      \ 'vim' : [ 'path', 'cmd', 'keyn', 'keyp' ],
      \ 'puppet' : [ 'path', 'omni', 'keyn', 'keyp', 'tags', 'c-n', 'c-p', 'uspl', 'ulti' ],
      \ 'python' : [ 'path', 'omni', 'keyn', 'keyp', 'c-n', 'c-p', 'uspl', 'ulti', 'tags' ],
      \ 'ruby' : [ 'path', 'omni', 'keyn', 'keyp', 'c-n', 'c-p', 'uspl', 'ulti', 'tags' ],
      \ }

" CtrlP
let g:ctrlp_match_window = 'bottom,order:btt,min:1,max:15,results:30'
let g:ctrlp_show_hidden = 1
let g:ctrlp_custom_ignore = {
\ 'dir':  '\.git$\|\.svn$\|\.hg$\|\.yardoc$\|node_modules\|spec\\fixtures\\modules$',
\ }

" vim-puppet
" Enable => autointent
let g:puppet_align_hashes = 1

" Ale checker
" Does not support puppet options yet, so need to setup '--no-140chars-check' in  ~/.puppet-lint.rc
let g:ale_echo_msg_format = '[%linter%][%severity%][%code%] %s'
let g:ale_yaml_yamllint_options = '-d "rules: {line-length: {allow-non-breakable-words: true, max: 300, allow-non-breakable-inline-mappings: true}}"'
let g:ale_python_flake8_options = '--ignore=E501'
let g:ale_eruby_erubylint_options = "-T '-'"
let g:ale_puppet_puppetlint_options='--no-autoloader_layout-check --no-140chars-check'
let g:ale_puppet_puppet_options='--parser=future'
let g:ale_yaml_yamllint_options='-d "{extends: relaxed, rules: {line-length: disable}}"'
let g:ale_warn_about_trailing_whitespace=1
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\ }
if has("win32")
  let g:ale_ruby_rubocop_options = '-c %USERPROFILE%\.rubocop.yaml'
else
  let g:ale_ruby_rubocop_options = '-c ~/.rubocop.yaml'
endif
let g:ale_lint_on_save = 1
let g:ale_lint_on_text_changed = 0
let g:ale_fix_on_save = 1
nmap <silent> tj <Plug>(ale_previous_wrap)
nmap <silent> tk <Plug>(ale_next_wrap)
" Custom Ale Linter
function! LinterStatus() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? 'OK' : printf(
  \   '%dW %dE',
  \   all_non_errors,
  \   all_errors
  \)
endfunction

" Disable folding for .md files
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_conceal = 0


" Yank
let g:yankstack_map_keys = 0
nmap <C-w>p <Plug>yankstack_substitute_older_paste
nmap <C-w>u <Plug>yankstack_substitute_newer_paste

" vim tasks
let g:TasksMarkerBase = '[ ]'
let g:TasksMarkerDone = '+'
let g:TasksMarkerCancelled = '-'
let g:TasksDateFormat = '%Y-%m-%d %H:%M'
let g:TasksAttributeMarker = '@'
let g:TasksArchiveSeparator = '================================'

" GitGutter
let g:gitgutter_grep = ''
nmap t[ <Plug>GitGutterNextHunk
nmap t] <Plug>GitGutterPrevHunk

" Tags
let g:gutentags_cache_dir = '~/.vim/tags'
let g:gutentags_exclude_project_root = ['fixtures']

" Tabular vim
nnoremap tp :Tab/=><CR>

" Vim-rooter
let g:rooter_silent_chdir = 1

" Ruby Mode
au BufNewFile,BufReadPost *.rb set tabstop=2 shiftwidth=2

" Filetype support
au BufNewFile,BufReadPost *.todo setlocal textwidth=1000
au BufNewFile,BufReadPost *Jenkinsfile* setlocal tabstop=4 shiftwidth=4 syntax=groovy filetype=groovy
au BufNewFile,BufReadPost *Vagrantfile* setlocal tabstop=2 shiftwidth=2 syntax=ruby filetype=ruby
au BufNewFile,BufReadPost *.xml setlocal tabstop=4 shiftwidth=4 syntax=xml filetype=xml
au BufNewFile,BufReadPost *.groovy setlocal tabstop=4 shiftwidth=4 syntax=groovy filetype=groovy
au BufNewFile,BufReadPost *.yaml setlocal tabstop=2 shiftwidth=2 syntax=yaml filetype=yaml
au BufNewFile,BufReadPost *.yml setlocal tabstop=2 shiftwidth=2 syntax=yaml filetype=yaml
au BufNewFile,BufReadPost *.bat setlocal tabstop=2 shiftwidth=2 ff=dos
au BufNewFile,BufReadPost *.md setlocal textwidth=80

" Run rspec on Windows 10 with WFL
autocmd Filetype ruby let b:dispatch = "bash.exe --login -c \"echo '%' \| tr -s '\\' '/' \| xargs -i rspec {}\""
autocmd Filetype groovy let b:dispatch = 'gradlew clean test'
nnoremap <F7> :Dispatch<CR>

" Ruby change syntaxt to 2.1
nnoremap <F8> :%s/\(\w*\)[ ]*=>/\1:/gc<CR>

" Set status line
set laststatus=2
set statusline=
set statusline+=%F\ %y[%{&ff}]
set statusline+=[%{strlen(&fenc)?&fenc:&enc}a]
set statusline+=\ %h%m%r%w
set statusline+=\ [Ale(%{LinterStatus()})]
set statusline+=%<\ %{fugitive#statusline()}
"set statusline+=\ [%l,%c/%L]

set splitbelow
set splitright
set mouse=a
set ttymouse=xterm2
"set textwidth=0
set wrapmargin=0

"Editorconfig fixes
let g:EditorConfig_exclude_patterns = ['fugitive://.*']

" Vimdiff
nmap du :wincmd w<cr>:normal u<cr>:wincmd w<cr>

"NerdTree auto open
"autocmd VimEnter * wincmd p
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

"Nerd Tree close vim when NT is the only window
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

"Toggle NerdTree using tf
nnoremap tf :NERDTreeToggle<CR>

let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ "Unknown"   : "?"
    \ }

function! s:DiffWithSaved()
  let filetype=&ft
  diffthis
  vnew | r # | normal! 1Gdd
  diffthis
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype
endfunction
com! DiffSaved call s:DiffWithSaved()
