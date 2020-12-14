# Tools to Synchronise Large Disks across Networks

## Sync_Makefile

Makefile to traverse through a directory structure with (large) files,
e.g. Video files for the purpose of:

1. finding duplicates
2. synchronising files with remote files

### Use cases

1. Synchronisation of two large storage systems with large files 
   across a network (storages are connected to separate computers).
2. Finding duplicates of files on large storage systems.

### Restrictions

- Unix filesystems
- Availability of Make
- No file names with colons (':')

### How it works

- Traverses through a directory tree structure and copy Sync_Makefile
  into each visited subdirectory
- Creates md5 sums in a hidden directory for each file using
  the make mechanism (i.e. the md5 sum is updated only if the
  file was updated, i.e. has a newer timestamp than it's md5
  sum file)
- collect all md5 sums recursively from the entire directory tree
- sort these md5 sums with their associated file names
- list duplicates in the sorted list

### Features/Benefits

- updates md5 sums only if a file was changed
- second and later passes are much faster than first pass
  (most md5 sums are calculated and need no update)
- ideal for large files (like Videos) and large storage systems
- the sorted list of md5 sums allows to find duplicates
- the sorted list of md5 sums allows to sync two storage systems
  across a network
- remove md5 sum files for files that were renamed or deleted
- copies Sync_Makefile to a remote destination using scp
  and executes make there. Session can be reconnected.
- list and clean broken links of a directory tree
- list filenames that contain ':' (see Bugs/Note)


### Make targets

all:  cleans empty md5 sum files, removes broken links and traverses
      through all subdirectories to create md5 sum files. Then collects
      all md5 sums into one.

sort: sort the lines by md5 sum and place contents in .md5/md5sums-sorted

duplicates: list all duplicate lines in .md5/md5sums-dubplicates

clean-md5sums: clean all .md5/*.md5 files in the directory tree

clean-md5files: delete only the summary files

clean: clean all generated files

list-broken-links: as said

clean-broken-links: as said

list-colon-files: as said

clean-dangling-md5: find and remove md5 sum files that have no associated
            large file.

remote: all make targets can be used with .remote. This copies Sync_Makefile
            to the remote system and executes the make target there.
	    The remote system must be defined at the toplevel of the Makfile.
	    A screen session is create on the remote. This allows reconnection
	    to the (remote) command.
      

### Bugs/Note

Whether it is a bug or feature: the prerequisites of a Makefile rule
must not contain a ':'. Hence the processed filenames must not contain ':'.


## Handle BUP and IFO Files

Video DVDs have a video_ts folder containing one or more *.bup
and one or more *.ifo files. Two of these files with same name
but different suffix (.ifo and .bup) are often the same. This script
replaces the .ifo file by a link to the .bup file.

This script creates a script to substitute a file (that is a duplication)
by a link to its duplicate.

(uses replaceLink.sh)

## Handle Duplicated

Works through the list of duplicates and asks the user to either
delete one or the other or link one of them to the other.

This script creates a script to substitute a file (that is a duplication)
by a link to its duplicate.

(uses replaceLink.sh)

## Makefile Test Directory

Test directory structure contains:

- directories
- files
- links to directories
- links to files
- a broken link
- files with suffixes
- files without suffixes
- a .syncignore file excluding a file and a directory
- a filename with paranthesis

## TODO

- examine other problematic characters like : and other braces
- a filename with an &