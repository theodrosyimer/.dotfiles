# fnm: every zsh shell, interactive or not, uses the Node version from the nearest .nvmrc
# (searched up to the repo root), or fnm's default version when there is none.
# Sourced from .zshenv (every shell) and again at the end of .zprofile (its first line resets PATH).
# The cd hook calls `fnm` by name, so it must be on PATH even in shells that skip .zprofile.
(( $+commands[fnm] )) || path+=(/opt/homebrew/bin)
eval "$(fnm env --use-on-cd --version-file-strategy=recursive --log-level quiet --shell zsh)"
