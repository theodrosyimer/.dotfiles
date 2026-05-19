function new_client() {
  local CLIENT_NAME="${(C)1[1]}${1[2,-1]}"

  if [[ -z "$CLIENT_NAME" ]]; then
    echo "Usage: new-client <client-name>"
    return 1
  fi

  local CLIENT_PATH="$HOME/dev/freelance/clients/$CLIENT_NAME"

  mkdir -p \
    "$CLIENT_PATH/01-contrats" \
    "$CLIENT_PATH/02-devis" \
    "$CLIENT_PATH/03-factures" \
    "$CLIENT_PATH/04-admin" \
    "$CLIENT_PATH/05-notes/"{appels,backlog,bugs,decisions,documentation,releases,roadmap,suivi} \
    "$CLIENT_PATH/06-livrables" \
    "$CLIENT_PATH/99-archive"

  echo "Client structure created at:"
  echo "$CLIENT_PATH"
}

function new_call_note() {
  local CLIENT_NAME="${(C)1[1]}${1[2,-1]}"
  local TITLE="${2:-appel}"
  local DATE="$(date +%Y-%m-%d)"

  if [[ -z "$CLIENT_NAME" ]]; then
    echo "Usage: new_call_note <client-name> [title]"
    return 1
  fi

  local CLIENT_PATH="$HOME/dev/freelance/clients/$CLIENT_NAME"
  local FILE="$CLIENT_PATH/05-notes/appels/$DATE-$TITLE.md"

  cp "$HOME/dev/freelance/templates/notes/compte-rendu-appel.md" "$FILE"
  echo "Call note created:"
  echo "$FILE"
}

function new_release_note() {
  local CLIENT_NAME="${(C)1[1]}${1[2,-1]}"
  local TITLE="${2:-release}"
  local DATE="$(date +%Y-%m-%d)"

  if [[ -z "$CLIENT_NAME" ]]; then
    echo "Usage: new_release_note <client-name> [title]"
    return 1
  fi

  local CLIENT_PATH="$HOME/dev/freelance/clients/$CLIENT_NAME"
  local FILE="$CLIENT_PATH/05-notes/releases/$DATE-$TITLE.md"

  cp "$HOME/dev/freelance/templates/notes/checklist-release.md" "$FILE"
  echo "Release checklist created:"
  echo "$FILE"
}
