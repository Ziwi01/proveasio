" Basic configuration
set nocompatible
syntax on
set background=dark
set noerrorbells visualbell t_vb=
autocmd GUIEnter * set visualbell t_vb=
set directory=~/.vim/tmp
set backupdir=~/.vim/backup
set autoread
set history=1000
set confirm

" Search options
set hlsearch
set incsearch

" Setup encoding for cygwin mostly
setglobal fileencoding=utf-8
set encoding=utf-8
set fileencodings=utf-8
set termencoding=utf-8
set ff=unix

" Cygwin backspace trick
set bs=2

" Set update to get faster results with plugins (default i 14400 = 4sec)
set updatetime=250

" Better toggle through VIM options
set wildmenu

" Auto line wrapping
set tw=220

" Yank to Windows clipboard
set clipboard=unnamed

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
set tabstop=2
set shiftwidth=2
set expandtab

" Use <C-L> to clear the highlighting of :set hlsearch.
if maparg('<C-L>', 'n') ==# ''
  nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>
endif


" Syntax Highlight sync
autocmd BufEnter * :syntax sync fromstart

" Shortcuts
nnoremap fd diwi
nnoremap tn <C-W>w
nnoremap tp <C-W>W
nnoremap tw :%s/\s\+$//<CR>:noh<CR>
nnoremap ,o :tabnew<CR>
nnoremap ,n :tabnext<CR>
nnoremap ,p :tabprev<CR>

" Session manager
set sessionoptions-=blank
map <F2> :mksession! ~/.vim/vim_session <cr>
map <F3> :source ~/.vim/vim_session <cr>

" Turn on omni-completion
"set tags=~/.vim/tags
set omnifunc=syntaxcomplete#Complete
set completeopt=menuone,menu,longest
let OmniCpp_GlobalScopeSearch = 1
let OmniCpp_DisplayMode = 1
let OmniCpp_ShowAccess = 1

" Vundle for plugin management
" Install if not present
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
Plugin 'scrooloose/nerdtree'              "File manager
Plugin 'rodjek/vim-puppet'                "Puppet syntax support
Plugin 'tpope/vim-fugitive'               "git support
Plugin 'w0rp/ale'                         "Syntax Checker
Plugin 'xolox/vim-misc'                   "Required for Easy Tags
Plugin 'xolox/vim-easytags'               "Easy tags
Plugin 'tpope/vim-surround'               "Easy surround changes
Plugin 'honza/vim-snippets'               "snippets profiles
Plugin 'SirVer/ultisnips'                 "snippets engine
Plugin 'godlygeek/tabular'                "auto tab
Plugin 'thoughtbot/vim-rspec'             "help with rspec files
Plugin 'vim-ruby/vim-ruby'                "edition and compliation for ruby
Plugin 'terryma/vim-multiple-cursors'     "Multiple cursors
Plugin 'plasticboy/vim-markdown'          "Support for markdown docs
Plugin 'Yggdroot/indentLine'              "Indent line
Plugin 'tpope/vim-speeddating'            "Manage date and time
Plugin 'ctrlpvim/ctrlp.vim'               "Buffer control
Plugin 'chaquotay/ftl-vim-syntax'         "FTL syntax
Plugin 'irrationalistic/vim-tasks'        "Todo list
Plugin 'othree/xml.vim'                   "Xml edit
Plugin 'airblade/vim-gitgutter'           "Enable gitgutter
Plugin 'majutsushi/tagbar'                "Class, methods index
if i_have_vundle == 0
  echo "Installing Vundles, please ignore key map error messages"
  echo ""
  :PluginInstall
endif
call vundle#end() 
filetype plugin indent on

" Set colorscheme
colorscheme bugi

" Disable wrapping for vim-tasks
autocmd BufReadPost *.todo set tw=1000

" Support for Jenkinsfile
au BufReadPost *Jenkinsfile* set syntax=groovy
au BufReadPost *Jenkinsfile* set filetype=groovy

" Support for Vagrantfile
au BufReadPost *Vagrantfile* set syntax=ruby
au BufReadPost *Vagrantfile* set filetype=ruby

" NERDTree configuration
" IF you want to run NERDTree on each vim start uncomment below line
" autocmd vimenter * NERDTree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
let g:NERDTreeDirArrows=0
let g:NERDTreeWinSize=50
nnoremap tf :NERDTreeToggle<CR>

" CtrlP
nnoremap tb :CtrlPBuffer<CR>

" Tagbar
nnoremap tt :TagbarToggle<CR>

" vim-puppet
" Disable => autointent
let g:puppet_align_hashes = 0

" Ale checker
" Does not support puppet options yet, so need to setup '--no-140chars-check' in  ~/.puppet-lint.rc
let g:ale_statusline_format = [' Err %d ', ' Warn %d ', ' OK ']
let g:ale_echo_msg_format = '[%linter%][%severity%] %s'
let g:ale_yaml_yamllint_options = '-d "rules: {line-length: {allow-non-breakable-words: true, max: 300, allow-non-breakable-inline-mappings: true}}"'
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
nmap hv <Plug>GitGutterPreviewHunk
nmap ha <Plug>GitGutterStageHunk
nmap hu <Plug>GitGutterUndoHunk

" Tags
let g:easytags_auto_highlight = 0
let g:easytags_file = '~/.vim/tags/global'
let g:easytags_by_filetype = '~/.vim/tags/'

" Snippets
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" Set status line
set laststatus=2
set statusline=
set statusline+=%F\ %y[%{&ff}]
set statusline+=[%{strlen(&fenc)?&fenc:&enc}a]
set statusline+=\ %h%m%r%w\ [Ale(%{ALEGetStatusLine()})]
set statusline+=%<\ %{fugitive#statusline()}
set statusline+=%=%-14.(%V%)\ %P
set statusline+=%=
set statusline+=%-10((%l,%c)%)
set statusline+=%L(%P)
