" Disable compatible mode
set nocompatible

" Apply defaults everyone wants
source $VIMRUNTIME/vimrc_example.vim

" Vundle for plugin management
" Install if not present
" IMPORTANT: works in CLI version only.
let i_have_vundle=1
let vundle_readme=expand('~/.vim/bundle/vundle/README.md')
if !filereadable(vundle_readme)
  echo "Installing Vundle.."
  echo ""
  silent !mkdir -p ~/.vim/bundle
  silent !git clone https://github.com/VundleVim/Vundle.vim ~/.vim/bundle/vundle
  let i_have_vundle=0
endif
filetype off
set rtp+=~/.vim/bundle/vundle

" Automatic plugin installation
call vundle#begin()
Plugin 'run2cmd/ide.vim'                  "Main vimrc configuration
Plugin 'VundleVim/Vundle.vim'             "Plugin manager
Plugin 'ctrlpvim/ctrlp.vim'               "Buffer control
Plugin 'w0rp/ale'                         "Syntax Checker
Plugin 'rodjek/vim-puppet'                "Puppet syntax support
Plugin 'tpope/vim-fugitive'               "git support
Plugin 'tpope/vim-unimpaired'             "Quick switch over mappings
Plugin 'tpope/vim-surround'               "Easy surround changes
Plugin 'majutsushi/tagbar'                "Tag Browser
Plugin 'ludovicchabant/vim-gutentags'     "Generate c-tags
Plugin 'irrationalistic/vim-tasks'        "Todo list
Plugin 'airblade/vim-gitgutter'           "Enable gitgutter
Plugin 'lifepillar/vim-mucomplete'        "Completeion Engine
Plugin 'godlygeek/tabular'                "auto tab
Plugin 'plasticboy/vim-markdown'          "Support for markdown docs
Plugin 'Yggdroot/indentLine'              "Indent line
Plugin 'SirVer/ultisnips'                 "Autocompletion snippets
Plugin 'honza/vim-snippets'               "Snippet engine
Plugin 'gilsondev/searchtasks.vim'        "Search tasks: TODO, FIXME, etc.
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

" Set font for Gvim
set guifont=Consolas

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
set ff=unix

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
nnoremap <Up>    :resize +2<CR>
nnoremap <Down>  :resize -2<CR>
nnoremap <Left>  :vertical resize +2<CR>
nnoremap <Right> :vertical resize -2<CR>

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
let g:ctrlp_match_window = 'bottom,order:btt,min:1,max:30,results:30'
let g:ctrlp_show_hidden = 1
let g:ctrlp_custom_ignore = {
\ 'dir':  '\.git$\|\.svn$\|\.hg$\|\.yardoc$\|node_modules\|spec\\fixtures\\modules$',
\ }

" vim-puppet
" Disable => autointent
let g:puppet_align_hashes = 0

" Ale checker
" Does not support puppet options yet, so need to setup '--no-140chars-check' in  ~/.puppet-lint.rc
let g:ale_statusline_format = [' Err %d ', ' Warn %d ', ' OK ']
let g:ale_echo_msg_format = '[%linter%][%severity%] %s'
let g:ale_yaml_yamllint_options = '-d "rules: {line-length: {allow-non-breakable-words: true, max: 300, allow-non-breakable-inline-mappings: true}}"'
let g:ale_python_pylint_options = '-d C0301'
let g:ale_eruby_erubylint_options = "-T '-'"
let g:ale_lint_on_save = 1
let g:ale_lint_on_text_changed = 0
nmap <silent> tj <Plug>(ale_previous_wrap)
nmap <silent> tk <Plug>(ale_next_wrap)

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
let g:gitgutter_realtime = 0
let g:gitgutter_eager = 0
nmap ]h <Plug>GitGutterNextHunk
nmap [h <Plug>GitGutterPrevHunk

" Tags
let g:gutentags_cache_dir = '~/.vim/tags'
let g:gutentags_exclude_project_root = ['fixtures']

" Tabular vim
nnoremap tp :Tab/=><CR>

" MUcomplete
let g:mucomplete#enable_auto_at_startup = 1
let g:mucomplete#chains = { 'default' : ['path', 'omni', 'keyn', 'keyp', 'c-n', 'c-p', 'dict', 'uspl', 'ulti', 'tags' ] }
let g:mucomplete#chains.vim = [ 'path', 'cmd', 'keyn' ]

" Ultisnips
let g:UltiSnipsExpandTrigger="<c-c>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-n>"

" Tagbar
nnoremap tt :TagbarToggle<CR>

" Filetype support
augroup vimrc_autocmd
  au BufReadPost *.todo set tw=1000
  au BufReadPost *Jenkinsfile* set tabstop=4 shiftwidth=4 syntax=groovy filetype=groovy
  au BufReadPost *Vagrantfile* set tabstop=2 shiftwidth=2 syntax=ruby filetype=ruby
  au BufReadPost *.xml set tabstop=4 shiftwidth=4 syntax=xml filetype=xml
  au BufReadPost *.groovy* set tabstop=4 shiftwidth=4 syntax=groovy filetype=groovy
  au BufReadPost *.yaml* set tabstop=2 shiftwidth=2 syntax=yaml filetype=yaml
  au BufReadPost *.yml* set tabstop=2 shiftwidth=2 syntax=yaml filetype=yaml
augroup END

" Set status line
set laststatus=2
set statusline=
set statusline+=%F\ %y[%{&ff}]
set statusline+=[%{strlen(&fenc)?&fenc:&enc}a]
set statusline+=\ %h%m%r%w
set statusline+=\ [Ale(%{ALEGetStatusLine()})]
set statusline+=%<\ %{fugitive#statusline()}

" Run shell comand and output in QuickFixWindow
function! RunCmdInQuickFixWindow(mycmd)
  cexpr system(a:mycmd)
endfunction
command! -nargs=* -complete=file Runcmd call RunCmdInQuickFixWindow(<q-args>)

" Enter code directory
cd c:\code
