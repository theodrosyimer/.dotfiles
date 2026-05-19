function new_client() {
  CLIENT_NAME="${(C)1[1]}${1[2,-1]}"

  if [[ -z "$CLIENT_NAME" ]]; then
    echo "Usage: new-client <client-name>"
    return 1
  fi

  CLIENT_PATH="$HOME/dev/freelance/clients/$CLIENT_NAME"

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
