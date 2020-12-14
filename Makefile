# potential errors to be fixed:
#
# - make clean and then make all sort works but
# - make all sort after having it done before duplicates the entries in the
#   top .md5/md5sums-sorted
# - md5sums is created in mdfiles target!! not anywhere else (surprising!)
# - create rule for sed that it only adds subdir's md5sums if those are older than
#   the one from pwd
# - md5 files remain in FS even if parent file was deleted, linked up etc.
#   critical cases: file foo deleted => .md5/foo.md5 must be deleted.
# - Makefile.md5 are created

# NOGO:
#
# filenames with : not be in the processed FS

# FIXME: md5sums should not contain links!!!
#        

REMOTE := markus@zotac
REMOTESTARTDIR := /media/markus/Video/Video

TOPTARGETS := all 

# allowing to hide the makefiles
MKFILENAME :=Makefile
# directory to collect the md5 sums for each file
MD5DIR     :=.md5
MD5SUFFIX  :=md5
# name of the files with all md5 sums of files in the directories below
MD5SUMS    :=md5sums

# if .syncignore file exists and 
IGNORE := $(shell test ! -e .syncignore || cat .syncignore)

# list of files in current directory
#FILELIST    := $(wildcard *)
FILELIST     := $(shell find . -mindepth 1 -maxdepth 1 -type f)
FILELIST     := $(filter-out ./$(MKFILENAME), $(FILELIST))
FILELIST     := $(filter-out $(IGNORE), $(FILELIST))
FILELIST     := $(FILELIST:=.$(MD5SUFFIX))
# parenthesis must not be in filenames. Replace them following
# https://ftp.gnu.org/old-gnu/Manuals/make-3.79.1/html_chapter/make_8.html.
# NOTE: No space before (, ) and \:
openPar      :=(
openParEsc   :=\(
# no space before $(openParEsc)!
FILELIST     := $(subst $(openPar),$(openParEsc), $(FILELIST))
closePar     :=)
closeParEsc  :=\)
FILELIST     := $(subst $(closePar),$(closeParEsc), $(FILELIST))
ampersand    :=&
ampersandEsc :=\&
FILELIST     := $(subst $(ampersand),$(ampersandEsc), $(FILELIST))
# FIXME: broken links must be taken out of the list or target
# %.$(MD5SUFFIX): ../% will fail


# \pre $(MD5DIR) must exist
$(MD5DIR)/$(MD5SUMS): $(wildcard $(MD5DIR)/*.$(MD5SUFFIX))
	@test -e $@ || echo "Creating md5sums in target .md5/md5sums"
	@# FIXME: cat must not use "..." but ( and ) make problems
	@#        needs same approach as FILELIST
	@echo "Collecting md5 sums in `pwd`/$@"
	@# if $@ exists do not touch it, otherwise create it
	test -e $@ || touch $@
	@# test for changed files $? but cat (update) all into $@
	@# NOTE: cat $^ could be used to list all dependencies.
	@#       The wildcard works well for the make mechanism
	@#       itself but fails on shell level because
	@#       '(' and ')' are not properly escaped. Hence 
	@#       the wildcard regexp is repeated in the cat
	@#       command to make it work.
	@# NOTE: cat may fail if there are no md5 sum files in $(MD5DIR)
	-test -z "$?" || \
	cat $(MD5DIR)/*.$(MD5SUFFIX) >> $@


# NOTE: an empty filelist would cause to run the first target
#       i.e. instead of "make -f ../Makefile file1.a.md5 file2.a.md5 ..."
#       it would call "make -f ../Makefile " invoking the first target and fail.
#       So you need to test FILELIST is empty.
md5files: $(MD5DIR)
	@test -e $@ || echo "Creating md5sums in target md5files"
	@# use || for test to make the line fail only if make fails
	@# needs - because make fails if any of the files in FILELIST does
	@# not exist, e.g. is a broken link
	@# $(FILELIST// ) removes whitespaces
	test -z "$(strip $(FILELIST))" || \
	( cd $(MD5DIR) && $(MAKE) -f ../$(MKFILENAME) $(FILELIST) )
	@# Must not execute parallel
	$(MAKE) -f $(MKFILENAME) -j 1 $(MD5DIR)/$(MD5SUMS)


# this substitution rule must start with %. Prepending a directory
# will cause it never to be called.
# \pre must be executed from inside MD5DIR
%.$(MD5SUFFIX): ../%
	@echo "Making $@ from $<"
	@# use quotes around filenames to cope with odd characters in
	@# filenames like (, ) etc
	test -L "$<" || md5sum "$<" > "$@"


# list of all directories except .md5
#SUBDIRS := $(wildcard */.)
# List all immediate subdirectories but no linked directories:
# FIXME: $(wildcard */.) lists the immediate directories and
#        linked directories as dir1/. dir2/. etc
#        with trailing /. while the following find lists only
#        immediate directories as dir1 dir2 dir3 etc.
# NOTE: the trailing of /. makes quite some difference when
#       using the target as $(@D) rather than a simple $@)
# list immediate directories except linked directories
SUBDIRS := $(shell find . -mindepth 1 -maxdepth 1 -type d)
# remove leading ./ 
SUBDIRS := $(subst ./,, $(SUBDIRS))
# remove .md5 dir from list
SUBDIRS := $(filter-out $(MD5DIR), $(SUBDIRS))
# remove ignored directories from list
SUBDIRS := $(filter-out $(IGNORE), $(SUBDIRS))

$(MD5DIR):
	@# use -p option to make it succeed always
	mkdir -p $@

# first process all subdirs (concurrently) then do current directory
$(TOPTARGETS): clean-zero-md5 clean-broken-links $(SUBDIRS)
	$(MAKE) -f $(MKFILENAME) md5files

$(MD5SUMS)-sorted: $(MD5SUMS)
	@#sort $< | sed '$$!N; s/^\(.*\)\n\1$$/\1/; t; D' > $@
	sort $< > $@ 

sort $(MD5DIR)/$(MD5SUMS)-sorted:
	make -C $(MD5DIR) -f ../$(MKFILENAME) $(MD5SUMS)-sorted

$(SUBDIRS): $(MD5DIR)
	@echo "Making $@"
	@# use || to make next line succeed
	test -f $@/$(MKFILENAME) || ln $(MKFILENAME) $@
	@# do not process linked directories
	$(MAKE) -C $@  -f $(MKFILENAME) $(MAKECMDGOALS)
	@test -e $@ || echo "Creating md5sums in target subdirs"
	sed -e 's,  ../,  ../$@/,' $@/$(MD5DIR)/$(MD5SUMS) >> $(MD5DIR)/$(MD5SUMS)


# Create $(SUBDIRS) and $(FILELIST) unconditionally
.PHONY: $(TOPTARGETS) $(SUBDIRS) $(FILELIST) clean sort clean-md5 clean-makefiles clean-md5sums clean-broken-links clean-zero-md5 clean-linked-md5 rm-dangling-md5 clean-dangling-md5


###################################################################
#              Cleaning steps
###################################################################
clean-md5sums:
	-find . -type f -wholename "*/$(MD5DIR)/$(MD5SUMS)" -delete

clean-md5files:
	-find . -type f -wholename "*/$(MD5DIR)/.$(MD5SUFFIX)" -delete

clean-md5:
	-find . -type d -name $(MD5DIR) -exec rm -rf {} \;

clean-makefiles:
	-find . -type f -name Makefile -delete

clean: 	clean-md5 clean-makefiles

list-broken-links:
	find . -xtype l -print

clean-broken-links:
	find . -xtype l -print -delete

# file and directory names with colons cannot be processed
list-colon-files:
	find . -name "*:*" -print

# power cut can cause md5 file to be empty
clean-zero-md5:
	-find . -type f -size 0 -wholename "*/$(MD5DIR)/*" -print -delete

# to be executed inside any .md5 dir: list all .md5 files (e.g. foo.md5)
# if associated file ../foo does not exist, then delete foo.md5
rm-dangling-md5:
	for file in *.md5; do \
	   test -f ../$${file%.md5} || rm $$file; \
	done

# to be executed inside any .md5 dir: list all .md5 files (e.g. foo.md5)
# if associated file ../foo does not exist, then delete foo.md5
rm-md5-from-links:
	for file in *.md5; do \
	   test -L ../$${file%.md5} && rm $$file; \
	done

clean-dangling-md5:
	find -P . -type d -name ".md5" \
	-exec $(MAKE) -C {} -f ../$(MKFILENAME) rm-dangling-md5 \;

clean-linked-md5:
	find -P . -type d -name ".md5" \
	-exec $(MAKE) -C {} -f ../$(MKFILENAME) rm-md5-from-links \;

###################################################################
#              Analyze
###################################################################

#We read the next line from input with the N command which appends the next line to pattern space separated by "\n" character.
#$! prevents it from doing on the last line.
#The substitution replaces two repeating strings with one.
#The t command takes the script to the end where the current pattern space gets printed automatically.
#If the substitution was not successful, D executes, deleting the non-repeated string.
#The cycle continues and this way only the duplicate lines get printed once.
duplicates $(MD5DIR)/$(MD5SUMS)-duplicates: $(MD5DIR)/$(MD5SUMS)-sorted
	cut -d' ' -f1 $(MD5DIR)/$(MD5SUMS)-sorted | uniq -d > $(MD5DIR)/$(MD5SUMS)-dtmp
	while IFS= read -r line; do \
	    grep "$$line" $(MD5DIR)/$(MD5SUMS)-sorted; \
	done <  $(MD5DIR)/$(MD5SUMS)-dtmp > $@


###################################################################
#              Remote invokations
###################################################################
# NOTE: all targets foo can be used remote by calling
#       make foo.remote

#all-remote:
#	scp Sync_Makefile $(REMOTE):$(REMOTESTARTDIR)/$(MKFILENAME)
#	ssh $(REMOTE) screen -d -m -S synchronize \
#	$(MAKE) -C $(REMOTESTARTDIR) -f $(MKFILENAME) all sort

# run target on remote computer, e.g. make all.remote
# copies the Makefile to the remote and calls target all
# on the remote using a screen session. The screen session
# allows to reconnect to that session using ssh.
#%.remote: %

%.remote:
	make copy-make-remote
	ssh $(REMOTE) screen -d -m -S synchronize \
	$(MAKE) -C $(REMOTESTARTDIR) -f $(MKFILENAME) $(@:.remote=)

copy-make-remote:
	scp Makefile $(REMOTE):$(REMOTESTARTDIR)/$(MKFILENAME)
