#!/bin/sh
# This script checks if there are remote changes from git, if so aggregate.sh will executed.

CONFLICT_MAIL=matthias.streulens@geomajas.org

git remote update

LOCAL=$(git rev-parse @{0})
REMOTE=$(git rev-parse @{u})
BASE=$(git merge-base @{0} @{u})

if [ $LOCAL = $REMOTE ]; then
    echo "Up-to-date"
elif [ $LOCAL = $BASE ]; then
    echo "Need to pull"
    bash geomajas-dep/aggregate.sh
elif [ $REMOTE = $BASE ]; then
    echo "Need to push, should not happen"
    echo "" | mail -s "Documentation script needs attention, needs to push changes <EOM>" $CONFLICT_MAIL
else
    echo "Diverged, should not happen"
    echo "" | mail -s "Documentation script needs attention, diverged changes <EOM>" $CONFLICT_MAIL
fi
~                                                                                                                                                                                                                                                                      
~                                                                                                        
