#!/bin/bash

# Get the current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create links to the scripts
ln -s $DIR/bin/aux_check_so.sh ./bin/chckso
ln -s $DIR/bin/aux_cleanup.sh ./bin/cleanup
ln -s $DIR/bin/aux_disk_usage.sh ./bin/diskusage
ln -s $DIR/bin/aux_grant_permissions.sh ./bin/grantperm
ln -s $DIR/bin/aux_lin2win.sh ./bin/lin2win
ln -s $DIR/bin/aux_list_all.sh ./bin/lsall
ln -s $DIR/bin/aux_reset_permissions.sh ./bin/resetperm
ln -s $DIR/bin/aux_win2lin.sh ./bin/win2lin