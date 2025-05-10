_path_script="$(cd "${.sh.file%/*}";pwd)"
. $_path_script/nerpd
. $_path_script/selector
. $_path_script/seedee
unset _path_script
