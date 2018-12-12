#! /bin/sh
# $Id: regenerate_cmd_tests.sh 7747 2017-04-23 10:52:50Z gavin $
# Use information from test driving files to regenerate test scripts
# that run only one test, and file lists to be used in Makefiles.
#
# Copyright 2013, 2014, 2016 Free Software Foundation, Inc.
#
# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY, to the extent permitted by law; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Originally written by Patrice Dumas.

# This script is run from "tp/tests/Makefile.am" to regenerate
# "tp/tests/Makefile.onetst".

#set -x

test_file='tests-parser.txt'
test_scripts_dir='test_scripts'

test -d $test_scripts_dir || mkdir $test_scripts_dir

dir=`echo $0 | sed 's,/[^/]*$,,'`
outfile=$1
shift
destdir=$1
shift

while test z"$1" = 'z-base' -o z"$1" = 'z-tex_html'; do
  if test z"$1" = 'z-base'; then
    base_test_dirs=$2
  elif test z"$1" = 'z-tex_html'; then
    tex_html_test_dirs=$2
  else
    echo "$0: Bad args" 1>&2
    exit 1
  fi
  shift
  shift
done


(
cd "$dir/../tests/$destdir" || exit 1

test_driving_files='# List of files that describe tests.  See tp/tests/README.
test_driving_files_generated_list ='
one_test_files='# List of test scripts that only run one test
one_test_files_generated_list = '

gather_tests() {
type=$1
shift
test_dirs=$1
for test_dir in $test_dirs; do
  driving_file=$test_dir/tests-parser.txt
  if test -f $driving_file; then
    test_driving_files="$test_driving_files $driving_file"
    while read line
    do
    if echo $line | grep '^ *#' >/dev/null; then continue; fi
# there are better ways
    name=`echo $line | awk '{print $1}'`
    arg=$name
    file=`echo $line | awk '{print $2}'`
    remaining=`echo $line | sed 's/[a-zA-Z0-9_./-]*  *[a-zA-Z0-9_./-]* *//'`
    test "z$name" = 'z' -o "$zfile" = 'z' && continue
    basename=`basename $file .texi`
    if test "z$name" = 'ztexi' ; then
      name="texi_${basename}"
      arg="texi ${basename}.texi"
    fi
    if test "z${test_dir}" = 'z.'; then
      name_prepended=${destdir}_
      relative_command_dir='/..'
    else
      name_prepended=${test_dir}_
      relative_command_dir=
    fi
    one_test_file="$test_scripts_dir/${name_prepended}$name.sh"
    one_test_files="$one_test_files \\
     $one_test_file"
    echo '#! /bin/sh
# This file generated by maintain/regenerate_cmd_tests.sh

if test z"$srcdir" = "z"; then
  srcdir=.
fi

command=run_parser_all.sh
one_test_logs_dir=test_log
diffs_dir=diffs

' > $one_test_file

    if test $type = 'tex_html'; then
      echo '
if test "z$TEX_HTML_TESTS" != z"yes"; then
  echo "Skipping HTML TeX tests that are not easily reproducible"
  exit 77
fi
' >> $one_test_file
    fi
    echo "dir=$test_dir
arg='$arg'
name='$name'
"'[ -d "$dir" ] || mkdir $dir

srcdir_test=$dir; export srcdir_test;
"$srcdir"'"$relative_command_dir"'/"$command" -dir $dir $arg
exit_status=$?
cat $dir/$one_test_logs_dir/$name.log
if test -f $dir/$diffs_dir/$name.diff; then
  echo 
  cat $dir/$diffs_dir/$name.diff
fi
exit $exit_status
' >> $one_test_file
    chmod 0755 $one_test_file
    done < $driving_file
  else
    echo "$0: Missing file $driving_file" 1>&2
    exit 1
  fi
done
}

basefile=`basename $outfile`
cat >$outfile <<END_HEADER
# $basefile generated by $0.
#
# Copyright 2016 Free Software Foundation, Inc.
#
# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY, to the extent permitted by law; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

END_HEADER

gather_tests base "$base_test_dirs"
gather_tests tex_html "$tex_html_test_dirs"

echo "$test_driving_files
" >> $outfile

echo "$one_test_files
" >>$outfile

)
