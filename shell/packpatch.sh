#!/bin/sh
. ./base.sh
usage="Usage:\n
	sh packpatch.sh <revision range> <path> [packname]\n
	e.g:\n
		# if repository is git\n
		sh packpatch.sh HEAD~2..HEAD ~/ggApp/gameserver\n
		# if repository is svn\n
		sh packpatch.sh 530:532 ~/ggApp/gameserver"

if [ $# -lt 2 ]; then
	echo -e $usage
	exit 0;
fi


revision_range=$1
path=$2
packname=$3
svn info $path 1>/dev/null 2>&1
is_svn=$?
dirname=`dirname $path`
appname=`basename $path`
if [ "$packname" = "" ]; then
	time=`date +"%Y%m%d%H%M%S"`
	packname=patch.$appname.$time.tar.gz
fi
if [ "$TAR_FLAGS" = "" ]; then
	TAR_FLAGS="--exclude=.svn --exclude=.git --exclude=*.o --exclude=*.pyc --exclude=log --exclude=logs"
fi
if [ $is_svn -eq 0 ]; then
	cd $dirname && svn diff --summarize -r$revision_range $appname | awk '{print $2}' | xargs tar --ignore-failed-read $TAR_FLAGS -zcvf $PACKAGE_PATH/$packname
else
	cd $dirname && git diff $revision_range --name-only $appname | xargs tar --ignore-failed-read $TAR_FLAGS -zcvf $PACKAGE_PATH/$packname
fi

# exist link src/gg?
if [ -d $path/src/gg ]; then
	gg_packname="patch.gg.$time.tar.gz"
	gg_appname="gg"
	if [ $is_svn -eq 0 ]; then
		cd $dirname && svn diff --summarize -r$revision_range $gg_appname | awk '{print $2}' | xargs -I {} echo $appname/src/{} | xargs tar --ignore-failed-read $TAR_FLAGS -zcvf $PACKAGE_PATH/$gg_packname
	else
		cd $dirname && git diff $revision_range --name-only $gg_appname | xargs -I {} echo $appname/src/{} | xargs tar --ignore-failed-read $TAR_FLAGS -zcvf $PACKAGE_PATH/$gg_packname
	fi
	# merge tar package
	if [ -f $PACKAGE_PATH/$gg_packname ]; then
		cat $PACKAGE_PATH/$gg_packname >> $PACKAGE_PATH/$packname
		rm -rf $PACKAGE_PATH/$gg_packname
	fi
fi

if [ -f $PACKAGE_PATH/$packname ]; then
	echo "detail see: tar -itf $PACKAGE_PATH/$packname"
	echo $packname
else
	echo "patch is empty"
fi
