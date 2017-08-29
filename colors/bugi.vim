" Name:                 Bugi VIM colorscheme
" Scriptname:           bugi.vim
" Original Author:      Piotr Bugała <piotr.bugala@gmail.com> <https://github.com/run2cmd/bugi.vim.git>
" For GVim:             Only support for Terminal
" License:              The Vim License (this command will show it: ':help copyright')
" Last Change:          v0.0.3: July 21, 2017

hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "bugi"

" Set background
set background=dark

" Default Highliting
" Mostly for Ruby, Bash, Python
hi Normal		    ctermfg=LightGray     guifg=Gray80 guibg=Black
hi Comment	    ctermfg=DarkGray      guifg=Gray40 
hi Constant	    ctermfg=DarkYellow    guifg=DarkYellow
hi String       ctermfg=LightRed      guifg=LightRed
hi Special	    ctermfg=DarkYellow    guifg=DarkYellow
hi Delimiter    ctermfg=LightGray     guifg=Gray80
hi Identifier	  ctermfg=Cyan          cterm=NONE   guifg=Cyan gui=NONE
hi Statement    ctermfg=Yellow        guifg=Yellow
hi PreProc      ctermfg=LightBlue     guifg=LightBlue
hi Define       ctermfg=Blue          cterm=bold guifg=CornflowerBlue gui=bold
hi Include      ctermfg=Blue          guifg=CornflowerBlue
hi Keyword      ctermfg=Yellow        guifg=Yellow
hi Type         ctermfg=DarkGreen     guifg=Green
hi Function	    ctermfg=LightGreen    guifg=LightGreen
hi Repeat	      ctermfg=DarkYellow    guifg=DarkYellow
hi Conditional  ctermfg=Yellow        guifg=Yellow
hi Operator     ctermfg=Red           guifg=Red
hi Ignore	      ctermfg=DarkRed       guifg=DarkRed
hi Error        ctermfg=White         cterm=reverse   ctermbg=Red  guifg=White gui=reverse guibg=Red
hi Todo	        ctermfg=Black         ctermbg=Yellow  guifg=Black guibg=Yellow
hi Visual       ctermfg=Black         ctermbg=LightGray guifg=Black guibg=LightGray
hi Search       ctermfg=Black         ctermbg=Red guifg=Black guibg=Red
hi Linenr       ctermfg=DarkGray      guifg=Gray40 
hi CursorLineNr ctermfg=Yellow        guifg=Yellow
hi CursorLine                         cterm=none gui=none guibg=NONE

" Puppet specific
hi puppetDefType ctermfg=Blue cterm=bold gui=bold guifg=CornflowerBlue
hi puppetTypeName ctermfg=Yellow      guifg=Yellow
hi puppetTypeDefault ctermfg=DarkGreen guifg=ForestGreen
hi puppetClass  ctermfg=LightYellow   guifg=LightYellow
hi puppetParamName ctermfg=Cyan       guifg=Cyan
hi puppetVariable ctermfg=LightGray   guifg=Gray80

" Tasks specific
hi tAttribute ctermfg=Red guifg=Red

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
hi StatusLine   ctermfg=DarkGreen     cterm=bold  ctermbg=DarkGray    guifg=Green guibg=Gray40 gui=bold
hi WarningMsg   ctermfg=DarkRed       guifg=DarkRed
hi TabLineFill  ctermfg=DarkGray      guifg=Gray80
hi TabLine      ctermfg=DarkGreen     cterm=bold  ctermbg=DarkGray    guifg=DarkGreen guibg=Gray40 gui=bold
hi TabLineSel   ctermfg=Black                     ctermbg=DarkCyan    guifg=Black  guibg=DarkCyan

" Vimdiff
hi DiffAdd    cterm=bold ctermfg=LightGray ctermbg=Blue               guifg=Gray80  guibg=Blue
hi DiffDelete cterm=bold ctermfg=DarkGray ctermbg=Blue                guifg=Gray40  guibg=Blue
hi DiffChange cterm=bold ctermfg=LightGray ctermbg=DarkYellow         guifg=Gray80  guibg=DarkYellow
hi DiffText   cterm=bold ctermfg=Red ctermbg=Yellow                   guifg=Red     guibg=Yellow

" Orgmode
hi Folded ctermbg=NONE
hi FoldColumn ctermbg=NONE
