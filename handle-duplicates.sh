#!/bin/bash

usage()
{
    cat <<EOF
Usage:

handle-duplicates.sh <md5sum sorted uniqued> <name of execution file>

default name of execution file is todo.sh.

Call execution file after handle-duplicates.sh to execute changes.
EOF
}

if [ "$#" -lt 1 ]; then
    usage
fi

# TODO: check for 1-2 params
# TODO: use mv trash instead of rm

# use $2
execution=todo.sh

# trash folder
#trash=trash

# rather than deleting the file it is moved to trash
#delete()
#{
#    echo "mv $1 $trash/$(readlink -f $1 | sed 's|/|-|g')" >> $execution
#}


choose()
{
    while true; do
	read -p "Please select? " selection
	case $selection in
            [1]* ) echo "moveToTrash $file1" >> $execution; break;;
            [2]* ) echo "moveToTrash $file2" >> $execution; break;;
            [3]* ) echo "replaceByLink $file1 $file2" >> $execution; break;;
            [4]* ) echo "replaceByLink $file2 $file1" >> $execution; break;;
            [5]* ) exit;;
            * ) echo "Please choose from 1-5.";;
	esac
    done
}


$(dirname $0)/replaceLink.sh > $execution


while read -u 10 md5sum1 file1; do
    read -u 10 md5sum2 file2
    if [ "$md5sum1" = "$md5sum2" ]; then
    	if cmp $file1 $file2; then
    	    # use dirname and basename to:
	    echo; echo
	    echo "$(dirname $file1)"
    	    ls $(dirname $file1)
    	    echo "====================================================="
	    echo "$(dirname $file2)"
    	    ls $(dirname $file2)
	    echo
    	    echo "$file1 and $file2 are equal."
	    echo "What do you want to do?"
    	    echo
    	    echo "1) delete $file1"
    	    echo "2) delete $file2"
    	    echo "3) link $file1 -> $file2"
    	    echo "4) link $file2 -> $file1"
    	    echo
    	    choose
    	fi
    fi
done 10<$1

chmod a+x $execution
