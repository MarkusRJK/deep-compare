#!/bin/bash

# .ifo and .bup files of DVDs appear to have the same contents.
# Replace the .bup file by a link to the .ifo file.

$(dirname $0)/replaceLink.sh > link-doubles.sh

# TODO use moving to trash rather than rm
#      secure against double execution

# do not follow links, when searching through non-link and non-directory
# filenames:
findCmd="find -P . ! -type l ! -type d -name "

# search for bup files that are not a link and replace
# them by a link to the ifo file (if the same):
for bup in $($findCmd "*.BUP"); do
    ifo="$(echo $bup | sed 's/.BUP/.IFO/')"
    if cmp $ifo $bup; then
	echo "replaceByLink $ifo $bup" >> link-doubles.sh
    fi
done

for bup in $($findCmd "*.bup"); do
    ifo="$(echo $bup | sed 's/.bup/.ifo/')"
    if cmp $ifo $bup; then
	echo "replaceByLink $ifo $bup" >> link-doubles.sh
    fi
done

chmod a+x link-doubles.sh
