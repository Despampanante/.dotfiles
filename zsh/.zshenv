export XDG_CONFIG_HOME=$HOME/.config
VIM="nvim"


export GIT_EDITOR=$VIM
export DENO_INSTALL="$HOME/.deno"
export DOTFILES=$HOME/.dotfiles
export STOW_FOLDERS="bash, i3, nvim, qutebrowser, tmux, zsh"
export PATH=$DOTFILES/scripts:$PATH

# export LC_ALL=en_IN.UTF-8
# export LANG=en_IN.UTF-8

# Where should I put you?
bindkey -s ^f "tmux-sessionizer\n"

catr() {
    tail -n "+$1" $3 | head -n "$(($2 - $1 + 1))"
}

session_name="santiago"

# 1. First you check if a tmux session exists with a given name.
tmux has-session -t=$session_name 2> /dev/null

# 2. Create the session if it doesn't exists.
if [[ $? -ne 0 ]]; then
  TMUX='' tmux new-session -d -s "$session_name"
fi

# 3. Attach if outside of tmux, switch if you're in tmux.
if [[ -z "$TMUX" ]]; then
  tmux attach -t "$session_name"
fi
