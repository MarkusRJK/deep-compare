#!/bin/bash

# .ifo and .bup files of DVDs appear to have the same contents.
# Replace the .bup file by a link to the .ifo file.

cat <<EOF
#!/bin/bash

# Generated file. Modifications may get lost.

trash=./trash
mkdir -p \$trash

# \param file to be moved into trash while replacing / in full path
#        by -
moveToTrash()
{
    mv \$1 \$trash/\$(readlink -f \$1 | sed 's|/|-|g')
}

# \param bup filename
# \param ifo filename
replaceByLink()
{
    # avoid circles
    if [ "\$(readlink -f \$2)" != "\$(readlink -f \$1)" ]; then
       moveToTrash \$1 && \\
       ln -s \$(basename \$2) \$1
    fi
}

EOF
