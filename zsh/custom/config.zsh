#!/usr/bin/env zsh

function config() {
  code -gn "$HOME/.dotfiles/karabiner" "$HOME/.dotfiles/karabiner/karabiner.edn" "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
}

function ebin() {
  code -gn "$HOME/bin"
}

function ejs() {
  code -g "$HOME/.js"
}

function ekenv() {
  code -gn "$HOME/.kenv"
}

function erefs() {
  code -gn "$HOME/Code/refs/$1"
}

function ezfunc() {
  code -gn "$HOME/.dotfiles/zsh/custom"
}

function ezsh() {
  code -gn "$HOME/.oh-my-zsh" "$HOME/.zprofile" "$HOME/.zshrc"
}
