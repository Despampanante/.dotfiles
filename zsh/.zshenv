export XDG_CONFIG_HOME=$HOME/.config
VIM="nvim"

export GIT_EDITOR=$VIM
export DENO_INSTALL="$HOME/.deno"
export DOTFILES=$HOME/.dotfiles

# Where should I put you?
bindkey -s ^f "tmux-sessionizer\n"

catr() {
    tail -n "+$1" $3 | head -n "$(($2 - $1 + 1))"
}
