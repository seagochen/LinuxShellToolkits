#!/bin/bash

# If the /opt/sak/bin directory does not exist, show an error message and exit
if [ ! -d /opt/sak/bin ]; then
  echo "Error: /opt/sak/bin does not exist."
  exit 1
fi

# List all the scripts in the /opt/sak/bin directory
ls /opt/sak/bin
