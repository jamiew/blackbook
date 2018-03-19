#!/bin/sh

dir="./data"
mkdir $dir

# i=59
i=54000
while [ 1 ]; do

  i=$((i + 1))
  echo $i

  outfile="$dir/$i.gml"

  if [ -f "$outfile" ]; then
    echo "Already here, skipping"
    continue
  fi

  wget "http://000000book.com/data/$i.gml" -O "$outfile"
  # wget "http://000000book.com/data/$i.json" -O "$outfile"

  if [ ! -s "$outfile" ] ; then
    echo "$outfile is empty, deleting..."
    rm "$outfile"
    # exit 0
  fi

  sleep 0.5

done
