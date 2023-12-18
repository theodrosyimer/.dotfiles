function npmclean() {
  rm -rf node_modules
  npm cache clean --force
  npm install --force
}

function pnpmclean() {
  rm -rf node_modules
  npm cache clean --force
  pnpm install --force
}
