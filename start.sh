#!/bin/sh

###############################################################################
#
# USAGE: start.sh [MOUNT-DECLARATIONS]
#
#   MOUNT-DECLARATIONS any number of docker run mount declarations
#
# example:  
#
# ./start.sh -v $(pwd):/project
#
#    mounts the current working directory to directory /project within the
#    container. Note that the UID and GID of user app  will be remapped to
#    match the UID/GUID of the user executing this script.
#
###############################################################################
docker run -ti --rm "$@" $(cat REPO_AND_VERSION) \
       /sbin/my_init -- /sbin/remapuser app $(id -u) $(id -g) bash 
