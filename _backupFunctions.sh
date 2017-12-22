
#!/bin/bash

## Functions to use for backup and synchronization



BACKUPDIR="/abyss/Common/Backups"
## Subdirectory by host:
myHost=`hostname`
[[ -z "$myHost" ]] || BACKUPDIR="$BACKUPDIR/$myHost"
## Make sure target directory exists
[[ -d "$BACKUPDIR" ]] || mkdir -p -m 1777 "$BACKUPDIR"

## Copyright (C) 2017 Charles A. Tilford
##   Where I have used (or been inspired by) public code it will be noted

LICENSE_GPL3="

    This program is free software: you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/

"

## script folder: https://stackoverflow.com/a/246128
my_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$my_dir/_util_functions.sh" # Source in utility functions

function lastModified {
    ## One argument, the file or folder to check. Will return the most
    ## recent modified time, in epoch seconds
    Item=`readlink -f $1`
    if [[ -d "$Item" ]]; then
        ## Newest mod time in a folder @Paulo Scardine :
        ##   https://stackoverflow.com/a/4997339
        ## Using %Y for 'last data modification, seconds since Epoch'
        rv=`find "$Item" -exec stat \{} --printf="%Y\n" \; | sort -n -r | head -n 1`
    else
        ## Single file
        rv=`stat "$Item" --printf="%Y\n"`
    fi
    echo "$rv"
}

function backupSubfolder {
    SRC=`readlink -f $1` # Source folder, de-linked
    SubDir="$2" # Optional intermediate subdirectory
    DirName=`basename "$SRC"`
    rv="$BACKUPDIR"
    if [[ ! -z "$SubDir" ]]; then
        if [[ "$SubDir" =~ ^/ ]]; then
            ## DO NOT QUOTE ^ : https://stackoverflow.com/a/2172367
            ## Absolute path, use as-is
            rv="$SubDir"
        else
            ## Presume this is a subdirectory
            rv="$rv/$SubDir" # subdirectory
        fi
    fi
    rv="$rv/$DirName"
    echo "$rv"
}

function allBackups {
    ## Find all backups currently held
    sf=`backupSubfolder "$1" "$2"`
    ab=`ls -1t "$sf"/????-??-??.tar.gz 2> /dev/null`
    ## Text block to array: https://stackoverflow.com/a/5257398
    IFS=$'\n'
    AllBackups=($ab)
    unset IFS
}

function mostRecentBackup {
    ## What is the most recent backup file for a folder?
    allBackups "$1" "$2"
    echo "${AllBackups[0]}"
}

function archiveFolder {
    ## $1 - The folder or file to archive
    ## $2 - Optional subfolder to put the archive under
    SRC=`readlink -f $1`             # Source folder, de-linked
    [[ -e "$SRC" ]] || return        #   Do nothing if it does not exist
    sf=`backupSubfolder "$1" "$2"`   # Backup folder (Target directory)
    mkdir -p -m 0777 "$sf"
    mrb=`mostRecentBackup "$1" "$2"` # What is the most recent backup?
    if [[ ! -z "$mrb" ]]; then
        ## There is at least one backup. Is it more recent than the folder?
        bDt=`lastModified "$mrb"`
        fDt=`lastModified "$SRC"`
        [[ "$bDt" > "$fDt" ]] && return # Do nothing if archive is fresh
    fi
    tgz=`date +"%Y-%m-%d.tar.gz"`
    ## Set up to avoid full directory path in tar file:
    Pwd=`pwd`
    SrcPar=`dirname "$SRC"`
    SrcName=`basename "$SRC"`
    tgzPath="$sf/$tgz"
    cd "$SrcPar"
    msg "$FgCyan" "Backing up $SrcName to $tgzPath"
    tar -czvf "$tgzPath" "$SrcName"
    cd "$Pwd" # Restore prior working directory
}
