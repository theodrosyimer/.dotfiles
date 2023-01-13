# "cds ~/Documents" goes there and lists the files
function cds() {
  cd $1 && ls -la
}
