# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
#export PATH=$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH
export PATH=$PATH:$HOME/.local/bin:$HOME/bin:/usr/local/bin

# Path to your oh-my-zsh installation.
export ZSH="${HOME}/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    docker
    colorize
    helm
    rvm
    tmux
    dotenv
    colored-man-pages
    dirhistory
    fzf
    fzf-tab
    zsh-autosuggestions
    zsh-sdkman
    zsh-syntax-highlighting
    you-should-use
    k
)

source $ZSH/oh-my-zsh.sh

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

### PYTHON ENV
# alias pyinit="source ~/var/vscode-python-venv/bin/activate"
# eyamldecrypt() {
#     eyaml decrypt --pkcs7-private-key=/etc/puppetlabs/puppet/keys/private_key.pkcs7.pem --pkcs7-public-key=/etc/puppetlabs/puppet/keys/public_key.pkcs7.pem -f $1
# }

### TMUX
ZSH_TMUX_AUTOSTART="true"
ZSH_TMUX_AUTOSTART_ONCE="true"
ZSH_TMUX_AUTOQUIT="true"

### Colorize
ZSH_COLORIZE_TOOL=chroma

### The FUCK
eval $(thefuck --alias)
bindkey -s '\e\e' 'fuck\n'

### Fuzzy Finder

# Setup fzf
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}${HOME}/.fzf/bin"
fi

# Auto-completion
[[ $- == *i* ]] && source "${HOME}/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
source "${HOME}/.fzf/shell/key-bindings.zsh"

# use bat as preview tool
export FZF_PREVIEW_COMMAND='bat --style numbers,changes --color always --line-range :500 {}'
# change default options
export FZF_DEFAULT_OPTS='--height 100% --layout=reverse --border --ansi'

# add alias for finding files with auto-preview ((b)etter find)
alias bfind="fzf --preview '$FZF_PREVIEW_COMMAND' --bind shift-up:preview-page-up,shift-down:preview-page-down"
# add alias for (b)etter tail
btail() {
    tail -f $1 | batcat --paging=never -l log
}

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# browse git branches using fzf
fzf-git-branch() {
    git rev-parse HEAD > /dev/null 2>&1 || return

    git branch --color=always --all --sort=-committerdate |
        grep -v HEAD |
        fzf --height 50% --ansi --no-multi --preview-window right:65% \
            --preview 'git log -n 50 --color=always --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed "s/.* //" <<< {})' |
        sed "s/.* //"
}

# git checkout using fzf
fzf-git-checkout() {
    local branch

    if [[ -n $1 ]]; then
        branch=$1
    else
        git rev-parse HEAD > /dev/null 2>&1 || return
        branch=$(fzf-git-branch)
    fi

    if [[ "$branch" = "" ]]; then
        echo "No branch selected."
        return
    fi

    # If branch name starts with 'remotes/' then it is a remote branch. By
    # using --track and a remote branch name, it is the same as:
    # git checkout -b branchName --track origin/branchName
    if [[ "$branch" = 'remotes/'* ]]; then
        branch_local="${branch#remotes/origin/}"
        echo "$branch_local"
        if [[ ! -z $(git branch | grep -E "[*]?${branch_local}$") ]]; then # we have this branch locally, just checkout
            git checkout $branch_local
        else
            git checkout --track $branch
        fi
    else
        git checkout $branch;
    fi
}

alias gb='fzf-git-branch'
alias gco='fzf-git-checkout' # usage: `gco` for search window or `gco <branch_name>` for particular branch

# Git-fuzzy
export PATH="$HOME/.git-fuzzy/bin:$PATH"
alias glo='git-fuzzy log'
alias gd='git-fuzzy diff'

### Other exports
export EDITOR='vim'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export GEM_SOURCE=http://xxnexus3.gtk.gtech.com/repository/rubygems-all/
export ANSIBLE_TRANSFORM_INVALID_GROUP_CHARS=ignore

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
