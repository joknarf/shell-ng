_path_script="$(\cd "${0%/*}";pwd)"
. $_path_script/lib/nerdp
. $_path_script/lib/selector
. $_path_script/lib/redo
. $_path_script/lib/seedee
. $_path_script/lib/complete-ng.zsh
PATH="$PATH:$_path_script"
unset _path_script
