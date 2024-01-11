function pinit() {
	pnpm init && npm pkg set name="${1:-"${PWD:t}"}" type='module' version='0.0.0'
}
