" Basic configuration
set nocompatible
syntax on
set background=dark
set hlsearch
set noerrorbells visualbell t_vb=
autocmd GUIEnter * set visualbell t_vb=
set directory=~/.vim/tmp
set backupdir=~/.vim/backup

" Setup encoding for cygwin mostly
setglobal fileencoding=utf-8
set encoding=utf-8

" Cygwin backspace trick
set bs=2

" Auto line wrapping
set tw=140

" Tab config
set smartindent
set tabstop=2
set shiftwidth=2
set expandtab
"set paste

" Set status line
set laststatus=2
set statusline=
set statusline+=%F
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
Plugin 'run2cmd/ide.vim'                 "Main vimrc configuration
Plugin 'VundleVim/Vundle.vim'             "Plugin manager
Plugin 'scrooloose/nerdtree'              "File manager
Plugin 'rodjek/vim-puppet'                "Puppet support
Plugin 'tpope/vim-fugitive'               "git support
Plugin 'scrooloose/syntastic'             "Syntax check
Plugin 'tpope/vim-surround'               "tab autocomplete
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
Plugin 'jceb/vim-orgmode'                 "Todo list
Plugin 'mikelue/vim-maven-plugin'         "Maven plugin
Plugin 'juneedahamed/svnj.vim'            "SVN plugin 
Plugin 'ctrlpvim/ctrlp.vim'               "Buffer control
if i_have_vundle == 0
  echo "Installing Vundles, please ignore key map error messages"
  echo ""
  :PluginInstall
endif
call vundle#end() 
filetype plugin indent on

" Set colorscheme
colorscheme bugi

" NERDTree configuration
" Always enabled
autocmd vimenter * NERDTree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Synastic configuration
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" Disable folding for .md files
let g:vim_markdown_folding_disabled = 1

" Orgmode
let g:org_heading_highlight_colors = ['Conditional', 'Constant']
let g:org_heading_highlight_levels = len(g:org_heading_highlight_colors)
let g:org_todo_keywords = ['IMPORTAND', '|', 'WORKING', 'PENDING', 'DONE', 'CANCELLED']
let g:org_todo_keyword_faces = [['WORKING', [':foreground black', ':background green']], 
      \ ['PENDING', 'DarkYellow'], 
      \ ['DONE', 'green', ':weight bold'], 
      \ ['CANCELLED', 'DarkGray']]

