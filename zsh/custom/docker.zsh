function docker_mysql_get_password() {
	docker container logs "${1:-"mysql"}" &> /dev/null | grep -o 'GENERATED ROOT PASSWORD.*$' | awk '{print $4}'
}

alias dkmspwd='docker_mysql_get_password'
alias dko='open --background -a docker'
