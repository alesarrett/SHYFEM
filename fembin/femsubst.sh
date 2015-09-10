#!/bin/sh

mkdir -p tmp.tmp.$$

files=`grep "^FEMDIR *=" * | grep '=$HOME' | sed -e 's/:.*//'`

for file in $files
do
  echo $file
  femsubst.pl $file > tmp.tmp/$file
done

echo "new files are in directory tmp.tmp.$$"

