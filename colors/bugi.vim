" Name:                 Bugi VIM colorscheme
" Scriptname:           bugi.vim
" Original Author:      Piotr Bugała <piotr.bugala@gmail.com> <https://github.com/run2cmd/bugi.vim.git>
" For GVim:             Only support for Terminal
" License:              The Vim License (this command will show it: ':help copyright')
" Last Change:          v0.0.2: December 4, 2015

hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "bugi"

" Set background
set background=dark

" Default Highliting
" Mostly for Ruby, Bash, Python
hi Normal		    ctermfg=LightGray     guifg=LightGray    guibg=black
hi Comment	    ctermfg=DarkGray      guifg=DarkGray
hi Constant	    ctermfg=DarkYellow    guifg=DarkYellow
hi String       ctermfg=Red           guifg=Red
hi Special	    ctermfg=DarkYellow    guifg=DarkYellow
hi Delimiter    ctermfg=LightGray     guifg=LightGray
hi Identifier	  ctermfg=Cyan     guifg=Cyan         cterm=NONE
hi Statement    ctermfg=Yellow 
hi PreProc      ctermfg=LightBlue
hi Define       ctermfg=Blue          cterm=bold
hi Include      ctermfg=Blue
hi Keyword      ctermfg=Yellow
hi Type         ctermfg=DarkGreen
hi Function	    ctermfg=LightGreen
hi Repeat	      ctermfg=DarkYellow
hi Conditional  ctermfg=Yellow
hi Operator     ctermfg=Red
hi Ignore	      ctermfg=DarkRed
hi Error        ctermfg=White         cterm=reverse   ctermbg=Red
hi Todo	        ctermfg=Black                         ctermbg=Yellow
hi Visual       ctermfg=Black                         ctermbg=LightGray
hi Search       ctermfg=Black                         ctermbg=Red
hi Linenr       ctermfg=DarkGray

" Puppet specific
hi puppetDefType ctermfg=Blue cterm=bold
hi puppetTypeName ctermfg=Yellow
hi puppetTypeDefault ctermfg=DarkGreen
hi puppetClass  ctermfg=LightYellow
hi puppetParamName ctermfg=Cyan
hi puppetVariable ctermfg=LightGray

" Links for common types
hi link Character	        Constant
hi link Number	          Constant
hi link Boolean	          Constant
hi link Float		          Number
hi link Label		          Statement
hi link Exception	        Statement
hi link Macro		          PreProc
hi link PreCondit	        PreProc
hi link StorageClass	    Type
hi link Structure	        Type
hi link Typedef	          Type
hi link Tag		            Special
hi link SpecialChar	      Special
hi link SpecialComment    Special
hi link Debug		          Special

" Tabs and statusline Warnings
hi StatusLine   ctermfg=DarkGreen     cterm=bold  ctermbg=DarkGray
hi WarningMsg   ctermfg=DarkRed
hi TabLineFill  ctermfg=DarkGray
hi TabLine      ctermfg=DarkGreen     cterm=bold  ctermbg=DarkGray
hi TabLineSel   ctermfg=Black                     ctermbg=DarkCyan

" Vimdiff
hi DiffAdd    cterm=bold ctermfg=LightGray ctermbg=Blue
hi DiffDelete cterm=bold ctermfg=DarkGray ctermbg=Blue
hi DiffChange cterm=bold ctermfg=LightGray ctermbg=DarkYellow
hi DiffText   cterm=bold ctermfg=Red ctermbg=Yellow

" Orgmode
hi Folded ctermbg=NONE
hi FoldColumn ctermbg=NONE
