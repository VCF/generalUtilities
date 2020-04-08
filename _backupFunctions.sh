
#!/bin/bash

## Functions to use for backup and synchronization

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
myBFdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$myBFdir/_util_functions.sh" # Source in utility functions

if [[ -z "$BACKUPDIR" ]]; then
    BACKUPDIR="$HOME/FileBackups"
    msg "$FgMagenta" "
BACKUPDIR was not defined, using: $BACKUPDIR
  (you may want to set that variable to something else)
"
fi

function lastModified {
    ## One argument, the file or folder to check. Will return the most
    ## recent modified time, in epoch seconds
    Item=$(readlink -f "$1")
    if [[ -d "$Item" ]]; then
        ## Newest mod time in a folder @Paulo Scardine :
        ##   https://stackoverflow.com/a/4997339
        ## Using %Y for 'last data modification, seconds since Epoch'
        rv=$(find "$Item" -exec stat \{} --printf="%Y\n" \; | sort -n -r | head -n 1)
    else
        ## Single file
        rv=$(stat "$Item" --printf="%Y\n")
    fi
    echo "$rv"
}

function backupSubfolder {
    BKUPSRC=$(readlink -f "$1") # Source folder, de-linked
    SubDir="$2" # Optional intermediate subdirectory
    DirName=$(basename "$BKUPSRC")
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
    sf=$(backupSubfolder "$1" "$2")
    ab=$(ls -1t "$sf"/????-??-??.tar.gz 2> /dev/null)
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
    DATASRC=$(readlink -f "$1")             # Source folder, de-linked
    if [[ ! -e "$DATASRC" ]]; then
        ## Do nothing if it does not exist
        msg "$FgYellow" "  Source not found: $DATASRC"
        return
    fi
    sf=$(backupSubfolder "$1" "$2")   # Backup folder (Target directory)
    mkdir -p -m 0777 "$sf"
    resScript="$sf/restoreBackup.sh"
    if [[ ! -s "$resScript" ]]; then
        ## Put a little script in the folder that will restore a
        ## backup to the proper location
        template="$myBFdir/_restoreBackupTemplate.sh"
        if [[ -s "$template" ]]; then
            cat "$template" | sed "s#@@DEST@@#${DATASRC}#" > "$resScript"
            chmod 0775 "$resScript"
        else
            msg "$FgYellow" "Failed to find restoreBackup.sh template file:
  $template
"
        fi
    fi
    mrb=$(mostRecentBackup "$1" "$2") # What is the most recent backup?
    if [[ ! -z "$mrb" ]]; then
        ## There is at least one backup. Is it more recent than the folder?
        bDt=$(lastModified "$mrb")
        fDt=$(lastModified "$DATASRC")
        [[ "$bDt" > "$fDt" ]] && return # Do nothing if archive is fresh
    fi
    tgz=$(date +"%Y-%m-%d.tar.gz")
    ## Set up to avoid full directory path in tar file:
    Pwd=$(pwd)
    SrcPar=$(dirname "$DATASRC")
    SrcName=$(basename "$DATASRC")
    tgzPath="$sf/$tgz"
    cd "$SrcPar"
    msg "$FgCyan" "Backing up $SrcName"
    tar -czvf "$tgzPath" "$SrcName"
    ## Size of file: https://unix.stackexchange.com/a/16644
    sz=$(stat --printf="%s" "$tgzPath")
    sz=$(expr "$sz" / 1024)
    msg "$FgBlue" "  Backup complete - ${sz}kb\n    $tgzPath"
    cd "$Pwd" # Restore prior working directory
}

function rsyncFolder {
    ## $1 - The folder or file to archive
    ## $2 - Optional subfolder to put the archive under

    ## rsync reminders
    ##   -r, --recursive : recurse into directories
    ##   -l, --links : copy symlinks as symlinks
    ##   -p, --perms : preserve permissions
    ##   -t, --times : preserve modification times
    ##   -g, --group : preserve group
    ##   -o, --owner : preserve owner (super-user only)
    ##   --devices : preserve device files (super-user only)
    ##   --specials : preserve special files
    ##   -D : same as --devices --specials
    ##   -a : same as -rlptgoD (all the above)
    ##   -C, --cvs-exclude : auto-ignore files in the same way CVS does
    ##   -z, --compress : compress file data during the transfer

    
    RSYNCSRC=$(readlink -f "$1")      # Source folder, de-linked
    [[ -e "$RSYNCSRC" ]] || return    #   Do nothing if it does not exist
    sf=$(backupSubfolder "$1" "$2")   # Backup folder (Target directory)
    SrcName=`basename "$RSYNCSRC"`

    ## Assure that target directory exists:
    mkdir -p "$sf"
    
    msg "$FgCyan" "Synchronizing (rsync) $SrcName"
    rsync -av "$RSYNCSRC/" "$sf"
    msg "$FgBlue" "  ... synchronization complete. Backup directory:
  $sf
"
}
