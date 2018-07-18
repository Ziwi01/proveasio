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
  silent !git clone https://github.com/VundleVim/Vundle.vim .vim/bundle/Vundle.vim
  let i_have_vundle=0
endif

" Automatic plugin installation
filetype off
set rtp+=$HOME/.vim/bundle/Vundle.vim
call vundle#begin('$HOME/.vim/bundle/')
Plugin 'VundleVim/Vundle.vim'             "Plugin manager
Plugin 'run2cmd/ide.vim'                  "Main vimrc configuration
Plugin 'ctrlpvim/ctrlp.vim'               "Buffer control
Plugin 'w0rp/ale'                         "Syntax Checker
Plugin 'rodjek/vim-puppet'                "Puppet syntax support
Plugin 'tpope/vim-fugitive'               "git support
Plugin 'tpope/vim-unimpaired'             "Quick switch over mappings
Plugin 'tpope/vim-surround'               "Easy surround changes
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
Plugin 'skywind3000/asyncrun.vim'         "Run command asynchronuosly
Plugin 'airblade/vim-rooter'              "Change root to .git directory
"Plugin 'reedes/vim-pencil'                "Easy edit
"Plugin 'tpope/vim-repeat'                 "Repeat entire map
"dpelle/vim-LanguageTool                   "Language check
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
set history=1000

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
set guioptions-=T

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
set ruler

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
set tabstop=2
set shiftwidth=2
set expandtab
set smarttab

" Lets go PRO. No Arrows movements.
nnoremap <Up>    <C-W><C-K>
nnoremap <Down>  <C-W><C-J>
nnoremap <Left>  <C-W><C-H>
nnoremap <Right> <C-W><C-L>

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
autocmd QuickFixCmdPost [^l]* copen 25
autocmd QuickFixCmdPost    l* lopen 25
noremap to :copen 25<cr>
noremap tc :cclose<cr>

" netrw configuratoin
nnoremap tf :Explore<CR>
let g:netrw_home = "~/.vim/"
let g:netrw_banner = 0
let g:netrw_preview = 1
let g:netrw_winsize = 25
let g:netrw_cursor = 3

" Session manager
set sessionoptions-=blank
map <F2> :mksession! ~/.vim/vim_session <cr>
map <F3> :source ~/.vim/vim_session <cr>

" Turn on omni-completion
set omnifunc=syntaxcomplete#Complete
set completeopt+=menuone,noinsert,noselect
let OmniCpp_GlobalScopeSearch = 1
let OmniCpp_DisplayMode = 1
let OmniCpp_ShowAccess = 1
set shortmess+=c
" Disable inlucdes since it tends to work very slow
set complete-=i

" Set colorscheme
colorscheme bugi
"colorscheme torte

" CtrlP
let g:ctrlp_match_window = 'bottom,order:btt,min:1,max:15,results:30'
let g:ctrlp_show_hidden = 1
let g:ctrlp_custom_ignore = {
\ 'dir':  '\.git$\|\.svn$\|\.hg$\|\.yardoc$\|node_modules\|spec\\fixtures\\modules$',
\ }

" vim-puppet
" Disable => autointent
let g:puppet_align_hashes = 0

" Ale checker
" Does not support puppet options yet, so need to setup '--no-140chars-check' in  ~/.puppet-lint.rc
let g:ale_echo_msg_format = '[%linter%][%severity%] %s'
let g:ale_yaml_yamllint_options = '-d "rules: {line-length: {allow-non-breakable-words: true, max: 300, allow-non-breakable-inline-mappings: true}}"'
let g:ale_python_pycodestyle_options = '--ignore=E501'
let g:ale_eruby_erubylint_options = "-T '-'"
if has("win32")
  let g:ale_ruby_rubocop_options = '-c %USERPROFILE%\.rubocop.yaml'
else
  let g:ale_ruby_rubocop_options = '-c ~/.rubocop.yaml'
endif
let g:ale_lint_on_save = 1
let g:ale_lint_on_text_changed = 0
let g:ale_linters = {
\ 'python': ['pycodestyle'],
\}
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

" MUcomplete
let g:mucomplete#enable_auto_at_startup = 1
let g:mucomplete#chains = { 'default' : ['path', 'omni', 'keyn', 'keyp', 'c-n', 'c-p', 'dict', 'uspl', 'ulti', 'tags' ] }
let g:mucomplete#chains.vim = [ 'path', 'cmd', 'keyn' ]

" Python Mode
let g:pymode = 1
let g:pymode_trim_whitespaces = 1
let g:pymode_options_max_line_length = 300
let g:pymode_options_colorcolumn = 0
let g:pymode_indent = 1
let g:pymode_lint_cwindow = 0
let g:pymode_folding = 0
let g:pymode_lint = 1
let g:pymode_lint_on_write = 1
" Use ALE linters
let g:pymode_lint_checkers = [ '' ]

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

" Set status line
set laststatus=2
set statusline=
set statusline+=%F\ %y[%{&ff}]
set statusline+=[%{strlen(&fenc)?&fenc:&enc}a]
set statusline+=\ %h%m%r%w
set statusline+=\ [Ale(%{LinterStatus()})]
set statusline+=%<\ %{fugitive#statusline()}

