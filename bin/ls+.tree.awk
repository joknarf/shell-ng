# tree+.awk
# Author: joknarf

function print_tree() {
  if (total_line) print total_line
  total_line=""
  for (i=1;i<=n;i++) {
    if (flag_i) printf("%s%*s ", c_inum, max_inums, inums_a[i])
    col=colors[cols_a[i]]
    lcol=colors["l" cols_a[i]]
    if (flag_l) {
      perms=perms_a[i]
      perms_type=substr(perms,1,1)
      perms_owner=substr(perms,2,3)
      perms_group=substr(perms,5,3)
      perms_other=substr(perms,8,3)
      perms_acl=substr(perms,11,1)
      if (perms_acl=="") perms_acl=" "
      if (USER==owner_a[i]) { c_perms_owner=lcol; c_owner=lc_user }
      else { c_perms_owner=col; c_owner=c_user }
      if (group_a[i] in user_groups) { c_perms_group=lcol; c_group=lc_user }
      else { c_perms_group=col; c_group=c_user }
      printf("%s ", lcol perms_type RESET c_perms_owner perms_owner c_perms_group perms_group lcol perms_other perms_acl)
      if (!(flag_g)) printf("%s%-*s ", c_owner, max_owner, owner_a[i])
      if (!(flag_G)) printf("%s%-*s ", c_group, max_group, group_a[i])
      printf(" %s%*s %s %s\n", c_size, max_size, size_a[i], c_date date_a[i], name_a[i])
    } else printf("%s\n", name_a[i])
  }
}
BEGIN {
  init_theme()
}
$0=="" { next }
/^ *[0-9]+.* used in/{ sum=$0; next}
# old tree not computing params dir
!/\[.*\] / {
  i=(flag_i)?". ":""
  if (/"/)
    $0="["i"d......... . . . ........ .....] " $0;
  else
    $0="["i"d......... . . . ........ .....] \"" $0 "\"";
}
{
  if (/\x1b\[1m/) missing=1; else missing=0
  gsub(/\x1b\[[10]+?[mK]/, "") # leading spaces/ANSI codes
}
{
  c=1
  if (match($0, /\[[^]]*\] /)) {
    prefix = substr($0, 1, RSTART - 1)
    file_i = substr($0, RSTART + RLENGTH)
    $0     = substr($0, RSTART + 1, RLENGTH - 3)
  }
  if (flag_i) inum=$(c++)
  perms=$(c++); owner=$(c++); group=$(c++);
  type=substr(perms,1,1)
  if (type=="c" || type=="b") size=$(c++)" "$(c++)
  else size=$(c++)
  date=$(c++) " " $c
  suffix=""
  if (match(file_i, / +\[error opening.*\]$/)) {
    suffix = colors["lred"] substr(file_i,RSTART,RLENGTH)
    file_i = substr(file_i,1, RSTART-1)
  }
  indicator=substr(file_i,length(file_i))
  if (indicator!="\"") file_i=substr(file_i, 1, length(file_i)-1)
  file_i=substr(file_i,index(file_i,"\""))
  if (type=="l") {
    c_link=C_TYPE["-"]
    if (match(file_i, /^"([^"\\]|\\.)*"/))
      fname = substr(file_i,RSTART+1,RLENGTH-2)
    b=length(fname)+8 # "fname" -> " 
    target=unescape(substr(file_i,b,length(file_i)-b))
    if (missing) c_link=C_IND["?"] "_bg"
    else if (indicator in C_IND) c_link="l" C_IND[indicator]
    else c_link="l" C_TYPE["-"]
  } else {
    fname=substr(file_i,2,length(file_i)-2)
    target=""
  }
  fname=unescape(fname)
  if(flag_F && fname !~ repat) next
  ext=""
  if (match(fname, /\.[^.]+$/)) ext=substr(fname,RSTART,RLENGTH)
  col=C_TYPE[type]
  icon=I_TYPE[type]
  if (type=="-") {
    if (indicator=="*") {
      col=C_IND["*"]
      icon=I_TYPE["*"]
    } else if (ext in C_EXT) col=C_EXT[ext]
    if (ext in I_EXT) icon=I_EXT[ext]
  }
  ++n
  if (fname ~ /^\./) c_fname=colors[col]
  else c_fname=colors["l"col]
  display_name=fname
  if (target) display_name=display_name " -> " ESC"?7l" colors[c_link] target ESC"?7h"
  fname=c_tree prefix c_fname icon " " display_name suffix RESET
  if (length(inum)>max_inums) max_inums=length(inum)
  #if (length(links)>max_links) max_links=length(links)
  if (length(owner)>max_owner) max_owner=length(owner)
  if (length(group)>max_group) max_group=length(group)
  if (length(size)>max_size) max_size=length(size)
  inums_a[n]=inum; perms_a[n]=perms;  owner_a[n]=owner; group_a[n]=group; size_a[n]=size;
  date_a[n]=date; name_a[n]=fname; cols_a[n]=col
}
END {
  print_tree()
  if(sum) printf("\n%s\n", sum)
}
