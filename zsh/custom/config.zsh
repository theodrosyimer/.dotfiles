#!/usr/bin/env zsh

function config() {
  if [ ! -f "$HOME/Library/KeyBindings" ]; then
    mkdir -p $HOME/Library/KeyBindings
    ln -s "$HOME/.dotfiles/keybindings/DefaultKeyBinding.dict" "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
  fi

  $EDITOR -gn "$HOME/.dotfiles/karabiner" "$HOME/.dotfiles/karabiner/karabiner.edn" "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
}

function ebin() {
  $EDITOR -gn "$HOME/bin"
}

function ejs() {
  $EDITOR -g "$HOME/.js"
}

function ekenv() {
  $EDITOR -gn "$HOME/.kenv"
}

function erefs() {
  $EDITOR -gn "$HOME/Code/refs/$1"
}

function ezfunc() {
  $EDITOR -gn "$HOME/.dotfiles/zsh/custom"
}

function ezsh() {
  $EDITOR -gn "$HOME/.oh-my-zsh" "$HOME/.zprofile" "$HOME/.zshrc"
}
