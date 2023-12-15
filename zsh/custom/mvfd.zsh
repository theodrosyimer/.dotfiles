function mvfd() {
	local paths=("$(get_paths_from_finder_selection)")
  local dirname=${paths[1]%%.*}

  mkdir -p $dirname
  mv $paths $dirname
}
