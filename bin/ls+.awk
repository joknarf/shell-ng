# ls+.awk
# Author: joknarf

function print_multic() {
# multicolumn output
  if (!n) return
  pad=2; width=TERMW
  # Max nb columns
  if (flag_1) Cmax=1
  else {
      Cmax=int((width-maxw-pad)/(minw+pad))
      if(Cmax>n) Cmax=n
      else if (Cmax<1) Cmax=1
  }
  # Try possible column counts
  for (C=Cmax;C>1;C--) {
    R=int((n+C-1)/C) # nb rows
    delete colw
    # per-column width
    total=C*pad
    for (i=1;i<=n;i++) {
      c=int((i-1)/R)
      if (vlen_a[i] > colw[c]) {
        total+=vlen_a[i]-colw[c]
        if(total>width) break
        colw[c]=vlen_a[i]
      }
    }
    if (total<=width) break
  }
  # 1 col trivial print
  if (C==1) {
    for (i=1;i<=n;i++) print name_a[i]
    return
  }
  # print rows
  for (r=1;r<=R;r++) {
    for (c=0;c<C;c++) {
      i=c*R+r
      if (i>n) break
      printf("%s%*s", name_a[i], colw[c]-vlen_a[i]+pad, "")
    }
    printf("\n")
  }
}
function print_long() {
  if (total_line) print total_line
  total_line=""
  for (i=1;i<=n;i++) {
    if (flag_i) printf("%s%*s ", c_inum, max_inums, inums_a[i])
    if (flag_s) printf("%s%*s ", c_size, max_size, sizeb_a[i])
    col=colors[cols_a[i]]
    lcol=colors["l" cols_a[i]]
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
    if (flag_Z) printf(" %s%-*s", c_context, max_context, context_a[i])
    printf(" %s%*s %s %s\n", c_size, max_size, size_a[i], c_date date_a[i], name_a[i])
  }
}
function print_ls() {
  if (flag_l) print_long()
  else print_multic()
  n=0; max_links=0; max_owner=0; max_group=0; max_size=0; max_inums=0; maxw=0;
}
BEGIN {
  init_theme()
}
# handle ls error messages
/^(ls|gls|gnuls):/ { print_ls();print colors["lred"] $0 RESET >"/dev/stderr"; next }
/^"/{ gsub(/^"|\\|":$/,""); print $0":"; next }
$0=="" { print_ls(); print ""; next }
/^total / { total_line=$0; next }
{
  if (/\x1b\[0?1m/) missing=1; else missing=0
  gsub(/^ +|\x1b\[0?1?[mK]/, "") # leading spaces/ANSI codes
}
{
  c=1
  if (flag_i) inum=$(c++)
  if (flag_s) sizeb=$(c++)
  perms=$(c++); links=$(c++); owner=$(c++); group=$(c++);
  if (flag_Z) context=$(c++)
  type=substr(perms,1,1)
  if (type=="c" || type=="b") size=$(c++)" "$(c++)
  else size=$(c++)
  date=$(c++) " " $c
  file_i=substr($0, index($0, "\""))
  indicator=substr(file_i,length(file_i))
  if (indicator!="\"") file_i=substr(file_i, 1, length(file_i)-1)
  if (type=="l") {
    c_link=C_TYPE["-"]
    match(file_i, /^"(([^"\\]|\\.)*)"/)
    fname=substr(file_i, RSTART + 1, RLENGTH - 2)
    b=length(fname)+8 # "fname" -> " 
    if (flag_l) {
        if (substr(file_i,b,1)=="\"") b++ # rust regression
        target=unescape(substr(file_i,b,length(file_i)-b))
    }
    if (missing) c_link=C_IND["?"] "_bg"
    else if (indicator in C_IND) c_link="l" C_IND[indicator]
    else c_link="l" C_TYPE["-"]
  } else {
    fname=substr(file_i,2,length(file_i)-2)
    target=""
  }
  fname=unescape(fname)
  if(flag_P && fname !~ repat) next
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
  vlen=length(fname)+2
  if (fname ~ /^\./) c_fname = colors[col]
  else c_fname=colors["l"col]
  if (vlen>maxw) maxw=vlen
  if (n==1 || vlen < minw) minw=vlen
  display_name=fname
  if (flag_l) {
    if (target) display_name=display_name " -> " ESC"?7l" colors[c_link] target ESC"?7h"
    if (length(inum)>max_inums) max_inums=length(inum)
    #if (length(links)>max_links) max_links=length(links)
    if (length(owner)>max_owner) max_owner=length(owner)
    if (length(group)>max_group) max_group=length(group)
    if (length(size)>max_size) max_size=length(size)
    if (length(sizeb)>max_size) max_size=length(sizeb)
    if (length(context)>max_context) max_context=length(context)
    inums_a[n]=inum; perms_a[n]=perms;  owner_a[n]=owner; group_a[n]=group; size_a[n]=size;
    date_a[n]=date; context_a[n]=context; sizeb_a[n]=sizeb; #links_a[n]=links;
  } else
    if (missing) c_fname=colors[C_IND["?"] "_bg"]
  fname=c_fname icon " " display_name RESET
  name_a[n]=fname; vlen_a[n]=vlen; cols_a[n]=col
}
END {
  if (flag_l) print_long()
  else print_multic()
}
