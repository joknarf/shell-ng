_path_script="$(\cd "${.sh.file%/*}";pwd)"
. $_path_script/lib/nerdp
. $_path_script/lib/selector
. $_path_script/lib/seedee
PATH="$PATH:$_path_script"
unset _path_script
