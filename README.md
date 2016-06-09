# bugi.vim

VIM configuration to bring IDE experiance for VIM 7.4 and above.
Works with Vundle Plugin Manager only. For other plugin managers 
you need to tweak vimrc file


## Requirements 
You need to create basic directory structure. To enable Vundle support do below:
```
mkdir -p ~/.vim/bundle ~/.vim/backup ~/.vim/tmp
```

Also source vimrc. To do for Vundle put below into your ~/.vimrc
```
let custom_config_file = expand('%:p:h') . '/.vim/bundle/bugi.vim/vimrc'
exe 'source' custom_config_file
```

## Installation
Download project into your plugin manager source path
```
cd ~/.vim/bundle
git clone https://github.com/run2cmd/bugi.vim.git
vim ~/.vimrc
```

## Author
Piotr Bugała <piotr.bugala@gmail.com>
