#!/bin/bash - 
set -o nounset                              # Treat unset variables as an error

declare -r DIR=$(cd "$(dirname "$0")" && pwd)
source $DIR/lib_log4sh.sh

# change the default message level from ERROR to INFO
#logger_setLevel INFO

# say hello to the world
logger_info "Hello, world!"
