function fgcol(num) {
  return ESC num "m"
}
function fglcol(num) {
  return ESC num+60 "m"
}
function unescape(s) {
  if (s ~ /\\\\/) {
    gsub(/\\\\/, "\034", s)
    gsub(/\\/, "", s)
    gsub(/\034/, "\\", s)
  } else gsub(/\\/,"",s)
  return s
}
function wildtore(p) {
    re = p
    gsub(/\+/, "\\+", re)    # escape literal dots
    gsub(/\./, "\\.", re)    # escape literal dots
    gsub(/\*/, "[^/]*", re)
    gsub(/\?/, "[^/]", re)
    return "(^|/)"re"$"
}

function init_theme() {
  ESC="\033["
  split(GROUPS, user_groups)
  for(i in user_groups) user_groups[user_groups[i]]=1
  split(FLAGS, f)
  for(i in f) flags[f[i]]=1
  flag_i=("i" in flags)
  flag_s=("s" in flags)
  flag_Z=("Z" in flags)
  flag_l=("l" in flags)
  flag_g=("g" in flags)
  flag_G=("G" in flags)
  flag_1=("1" in flags)
  flag_P=("P" in flags)
  flag_F=("F" in flags) #find
  if(flag_P) repat=wildtore(PATTERN)
  while ((getline < iconfile) > 0)
    for(i=2;i<=NF;i++) I_EXT[$i]=$1
  close(iconfile)
  while ((getline < colorfile) > 0)
    for(i=2;i<=NF;i++) C_EXT[$i]=$1
  close(colorfile)
  # basic colors
  split("black,red,green,yellow,blue,magenta,cyan,white", colors, ",")
  for(i=1;i<=8;i++) {
    colors[colors[i]]=fgcol(i+29)
    colors["l"colors[i]]=fglcol(i+29)
  }
  # theme colors
  while ((getline < themefile) > 0)
    if (NF==2) {
      colors[$1]=ESC "38;2;" $2 "m"
      colors[$1"_bg"]=ESC "48;2;" $2 "m" ESC"38;2;235;235;235m" ESC"5m" # blink for mising
    }
  RESET=ESC "0m"
  c_date=colors[C_EXT["date"]]
  c_size=colors[C_EXT["size"]]
  c_context=colors[C_EXT["context"]]
  c_inum=colors[C_EXT["inum"]]
  c_user=colors[C_EXT["user"]]
  lc_user=colors["l" C_EXT["user"]]
  c_tree=colors[C_EXT["tree"]]
  C_TYPE["-"]=C_EXT["file"]
  C_TYPE["d"]=C_EXT["folder"]
  C_TYPE["p"]=C_EXT["pipe"]
  C_TYPE["s"]=C_EXT["socket"]
  C_TYPE["l"]=C_EXT["symlink"]
  C_TYPE["b"]=C_EXT["blockdev"]
  C_TYPE["c"]=C_EXT["chardev"]
  I_TYPE["-"]=I_EXT["file"]
  I_TYPE["d"]=I_EXT["folder"]
  I_TYPE["l"]=I_EXT["symlink"]
  I_TYPE["p"]=I_EXT["pipe"]
  I_TYPE["s"]=I_EXT["socket"]
  I_TYPE["b"]=I_EXT["blockdev"]
  I_TYPE["c"]=I_EXT["chardev"]
  I_TYPE["*"]=I_EXT["exec"]
  C_IND["|"]=C_EXT["pipe"]
  C_IND["="]=C_EXT["socket"]
  C_IND["*"]=C_EXT["exec"]
  C_IND["/"]=C_EXT["folder"]
  C_IND[">"]=C_EXT["door"]
  C_IND["?"]=C_EXT["missing"] # not implemented in ls
}
