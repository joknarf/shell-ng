_path_script="$(\cd "${BASH_SOURCE%/*}";pwd)"
. $_path_script/lib/nerdp
. $_path_script/lib/selector
. $_path_script/lib/redo
. $_path_script/lib/seedee
. $_path_script/lib/complete-ng.bash
. $_path_script/lib/pgtree
PATH="$PATH:$_path_script/bin"
unset _path_script
