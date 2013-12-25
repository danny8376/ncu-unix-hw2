#! /bin/csh -f
# backup script
# By dannyAAM
#
##

set increment=0
set inc_dir=0

# == check argument ==
# wrong number of arguments
if ($#argv < 2 || $#argv > 4) then
  goto echo_help
endif
# use options - check it
if ($#argv == 3 || $#argv == 4) then
  if ($#argv == 3) then
    set options=$1
    set list_file=$2
    set bak_path=$3
  else
    set options="$1 $2"
    set list_file=$3
    set bak_path=$4
  endif
  foreach opt ($options)
    switch ($opt)
    case "-d":
      set inc_dir=1
      breaksw
    case "-i":
      set increment=1
      breaksw
    case "-di":
    case "-id":
      set increment=1
      set inc_dir=1
      breaksw
    default:
      goto echo_help
      breaksw
    endsw
  end
else
  set list_file=$1
  set bak_path=$2
endif


# == main program ==
# check list file
if (! -e $list_file) then
  echo "$list_file is not exist."
  echo "Please provide the list."
  exit 1
endif
# check target dir
if (! -e $bak_path) then
  # make it if not exist
  mkdir $bak_path
  # then disable increment since it requires full backup
  set increment=0
else if (! -d $bak_path) then
  echo "$bak_path is not a directory"
  exit 1
endif
# backup
foreach file (`cat $list_file`)
  # increment mode
  if ($increment == 1) then
    # not exist - copy it
    if (! -e "$bak_path/$file") then
      if (-d $file) then
	if ($inc_dir == 1) then
	  cp -r $file $bak_path
	else
	  echo "$file skipped(is a directory)"
	endif
      else
	cp $file $bak_path
      endif
    else
      # dir
      if (-d $file) then
	if ($inc_dir == 1) then
	  # modified files
	  set fdiff=`diff -r $file $bak_path/$file | grep "^diff -r" | cut -c 9-`
	  set i=1
	  while ($i <= $#fdiff)
	    @ i2 = $i + 1
	    cp $fdiff[$i] $fdiff[$i2]
	    @ i = $i + 2
	  end
	  # new files
	  set newf=`diff -r $file $bak_path/$file | grep "^Only in .*: "  | sed "s/^Only in \(.*\): \(.*\)/\1\/\2/g" | grep -v "^$bak_path/"`
	  set i=1
	  while ($i <= $#newf)
            cp -r $newf[$i] $bak_path/$newf[$i]
            @ i = $i + 1
          end
	else
	  echo "$file skipped(is a directory)"
	endif
      # file
      else
        if (`diff $file $bak_path/$file` != "") then
          cp $file $bak_path
	endif
      endif
    endif
  # normal mode
  else
    if (-d $file) then
      if ($inc_dir == 1) then
        cp -r $file $bak_path
      else
        echo "$file skipped(is a directory)"
      endif
    else
      cp $file $bak_path
    endif
  endif
end

exit 0
# end of main program

echo_help:
cat << EOF
A Script to backup files

Usage: $0 [-d] [-i] LIST BAK_PATH

Arguments:
  LIST		A file list for files to backup (separate by space)
  BAK_PATH	Path to storge backup

Options:
  -d		Include directories
  -i		Incremental backup
EOF

exit 1

