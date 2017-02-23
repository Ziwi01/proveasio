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
set tw=140

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

" Set status line
set laststatus=2
set statusline=
set statusline+=%F\ %y[%{&ff}]
set statusline+=%10{strlen(&fenc)?&fenc:&enc}a
set statusline+=%<\ %h%m%r%{fugitive#statusline()}%=%-14.(%l,%c%V%)\ %P
set statusline+=%=
set statusline+=%-10((%l,%c)%)
set statusline+=%L(%P)

" Syntax Highlight sync
autocmd BufEnter * :syntax sync fromstart

" Shortcuts
nnoremap fd diwi
nnoremap tb :CtrlPBuffer<CR>
nnoremap tn <C-W>w
nnoremap tp <C-W>W
nnoremap tf :NERDTreeToggle<CR>
nnoremap tw :%s/\s\+$//<CR>:noh<CR>
nnoremap ,o :tabnew<CR>
nnoremap ,n :tabnext<CR>
nnoremap ,p :tabprev<CR>
nnoremap tt :TagbarToggle<CR>

" Session manager
set sessionoptions-=blank
map <F2> :mksession! ~/.vim/vim_session <cr>
map <F3> :source ~/.vim/vim_session <cr>

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
Plugin 'scrooloose/syntastic'             "Syntax check
Plugin 'tpope/vim-surround'               "Easy surround changes
Plugin 'MarcWeber/vim-addon-mw-utils'     "some usefould vim utils for other plugins
Plugin 'tomtom/tlib_vim'                  "not sure - dependency for other plugins
Plugin 'honza/vim-snippets'               "snippets profiles
Plugin 'garbas/vim-snipmate'              "snippets engine
Plugin 'godlygeek/tabular'                "auto tab
Plugin 'thoughtbot/vim-rspec'             "help with rspec files
Plugin 'vim-ruby/vim-ruby'                "edition and compliation for ruby
Plugin 'scrooloose/nerdcommenter'         "comment support in visual mode
Plugin 'terryma/vim-multiple-cursors'     "Multiple cursors
Plugin 'plasticboy/vim-markdown'          "Support for markdown docs
Plugin 'Yggdroot/indentLine'              "Indent line
Plugin 'tpope/vim-speeddating'            "Manage date and time
Plugin 'mikelue/vim-maven-plugin'         "Maven plugin
Plugin 'juneedahamed/svnj.vim'            "SVN plugin 
Plugin 'ctrlpvim/ctrlp.vim'               "Buffer control
Plugin 'chaquotay/ftl-vim-syntax'         "FTL syntax
Plugin 'irrationalistic/vim-tasks'        "Todo list
Plugin 'othree/xml.vim'                   "Xml edit
Plugin 'airblade/vim-gitgutter'           "Enable gitgutter
Plugin 'tfnico/vim-gradle'                "Gradle support
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
au BufReadPost Jenkinsfile set syntax=groovy
au BufReadPost Jenkinsfile set filetype=groovy

" NERDTree configuration
" IF you want to run NERDTree on each vim start uncomment below line
" autocmd vimenter * NERDTree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
let g:NERDTreeDirArrows=0

" Synastic configuration
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
let g:syntastic_yaml_checkers = ['yamllint']
let g:syntastic_yaml_yamllint_args = '-d "rules: {line-length: {allow-non-breakable-words: true, max: 120, allow-non-breakable-inline-mappings: true}}"'

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

" Maven setup
autocmd BufNewFile,BufReadPost *.* call s:SetupMavenMap()
function! <SID>SetupMavenMap()
  doautocmd MavenAutoDetect BufNewFile,BufReadPost
  if !maven#isBufferUnderMavenProject(bufnr("%"))
    return
  endif
endfunction

" GitGutter
let g:gitgutter_realtime = 0
let g:gitgutter_eager = 0
nmap hv <Plug>GitGutterPreviewHunk
nmap ha <Plug>GitGutterStageHunk
nmap hu <Plug>GitGutterUndoHunk
