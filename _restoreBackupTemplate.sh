#!/bin/bash
## Function to restore a tar.gz backup to the location it came from
tgz="$1"
dest="@@DEST@@"
par="$(dirname "$dest")"
here="$(dirname "$0")"
if [[ -z "$tgz" ]]; then
    echo "
Please pass the path to the tar.gz file as the first argument
  Available files are:
"
    ls -1tr "$here" | grep '.tar.gz$'
    exit
fi
if [[ ! -s "$tgz" ]]; then
    ## Did not find the file. Maybe it is a relative path?
    tgz="$here/$tgz"
fi
if [[ ! -s "$tgz" ]]; then
    ## Did not find the file. Maybe it is a relative path?
    tgz="$here/$tgz"
fi
if [[ -d "$dest" ]]; then
    ## If the target directory exists, move it to a renamed location (-BKUP)
    bkd="$dest"-BKUP
    if [[ -d "$bkd" ]]; then
        echo "Backup directory exists - please remove or rename and try again"
        echo "    $bkd"
        exit
    fi
    mv "$dest" "$bkd"
fi
## Create the partent directory if absent
[[ ! -d "$par" ]] && mkdir "$par"

echo "Unpacking:
  $tgz
To:
  $par
"
oldDir="$(pwd)"
cd "$par"
gunzip -c "$tgz" | tar -xvf -
cd "$oldDir"

if [[ -d "$dest" ]]; then
    echo "Restoration apparently succesful. Files now at:
  $dest
"
else
    echo "
?? Failed to unpack?
   Did not detect expected directory
"
fi



