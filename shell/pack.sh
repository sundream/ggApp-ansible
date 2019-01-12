#!/bin/sh
usage="Usage:
	sh shell/pack.sh <path> [packname]\n
	e.g:\n
		sh shell/pack.sh .\n
		sh shell/pack.sh ~/ggApp/gamesrv"

if [ $# -lt 1 ]; then
	echo $usage
	exit 0;
fi

path=$1
dirname=`dirname $path`
appname=`basename $path`
packname=$2
if [ "$packname" = "" ]; then
	time=`date +"%Y%m%d%H%M%S"`
	packname=pack.$appname.$time.tar.gz
fi
if [ "$TAR_FLAGS" = "" ]; then
	TAR_FLAGS="--exclude=.svn --exclude=.git --exclude=*.o --exclude=*.pyc --exclude=log --exclude=logs"
fi
cd $path && tar $TAR_FLAGS -zcvf /tmp/$packname . && echo $packname

