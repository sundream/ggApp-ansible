#!/bin/sh
usage="Usage:
	sh shell/packpatch.sh <path> <revision range> [packname]\n
	e.g:\n
		# default consider repository is git\n
		sh shell/packpatch.sh ~/ggApp/gamesrv HEAD~2..HEAD\n
		# -s means svn\n
		sh shell/packpatch.sh -s ~/ggApp/gamesrv 530:532"

is_git=1
while getopts s opt; do
	case "$opt" in
	s)
		is_git=0;;
	[?])
		echo $usage
		exit 0;;
	esac
done
shift $((OPTIND-1))
if [ $# -lt 2 ]; then
	echo $usage
	exit 0;
fi

path=$1
dirname=`dirname $path`
appname=`basename $path`
revision_range=$2
packname=$3
if [ "$packname" = "" ]; then
	time=`date +"%Y%m%d%H%M%S"`
	packname=patch.$appname.$time.tar.gz
fi
if [ "$TAR_FLAGS" = "" ]; then
	TAR_FLAGS="--exclude=.svn --exclude=.git --exclude=*.o --exclude=*.pyc --exclude=log --exclude=logs"
fi
if [ $is_git -eq 1 ]; then
	cd $dirname && git diff $revision_range --name-only $appname | xargs tar --transform='s|'$appname'/||' --ignore-failed-read $TAR_FLAGS -zcvf /tmp/$packname && echo $packname
else
	cd $path && svn diff --summarize -r$revision_range . | awk '{print $2}' | xargs tar --ignore-failed-read $TAR_FLAGS -zcvf /tmp/$packname && echo $packname
fi

