#!/usr/bin/env zsh

# source: https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-cht.sh

selected="$(cat $DOTFILES/tmux/.tmux-cht-languages $DOTFILES/tmux/.tmux-cht-command | fzf)"
if [[ -z $selected ]]; then
    exit 0
fi

read -pr "Enter Query: " query

if grep -qs "$selected" $DOTFILES/.tmux-cht-languages; then
    query=$(echo "$query" | tr ' ' '+')
    tmux neww bash -c "echo \"curl cht.sh/$selected/$query/\" & curl cht.sh/$selected/$query & while [ : ]; do sleep 1; done"
else
    tmux neww bash -c "curl -s cht.sh/$selected~$query | less"
fi
