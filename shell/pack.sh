#!/bin/sh

. ./base.sh
usage="Usage:\n
	sh pack.sh <path> [packname]\n
	e.g:\n
		sh pack.sh .\n
		sh pack.sh ~/ggApp/gameserver \n
		sh pack.sh ~/ggApp/loginserver \n
		sh pack.sh ~/ggApp/robot \n
		sh pack.sh ~/ggApp/client"

if [ $# -lt 1 ]; then
	echo -e $usage
	exit 0;
fi

path=$1
packname=$2
dirname=`dirname $path`
appname=`basename $path`
if [ "$packname" = "" ]; then
	time=`date +"%Y%m%d%H%M%S"`
	packname=pack.$appname.$time.tar.gz
fi
if [ "$TAR_FLAGS" = "" ]; then
	TAR_FLAGS="--exclude=.svn --exclude=.git --exclude=*.o --exclude=*.pyc --exclude=log --exclude=logs"
fi
cd $dirname && tar $TAR_FLAGS -h -zcvf $PACKAGE_PATH/$packname $appname
echo "detail see: tar -itf $PACKAGE_PATH/$packname"
echo $packname
