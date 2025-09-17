#!/bin/sh

export ARCHIVE="git-archive-all-1.23.1"
wget https://github.com/Kentzo/git-archive-all/releases/download/1.23.1/$ARCHIVE.tar.gz -nv
tar xf $ARCHIVE.tar.gz

python ../$ARCHIVE/git_archive_all.py --include .cache --include GIT-RELEASE --include GIT-COMMIT --include GIT-TAG --include GIT-REFSPEC --force-submodules source.tar

zstd -10 source.tar
rm source.tar
