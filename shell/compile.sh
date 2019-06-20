# !/bin/sh
. ./base.sh

if [ $# -lt 1 ]; then
	echo "usage: sh compile.sh packname"
	exit
fi
packname=$1
if ! [ -f $packname ]; then
	packname=$PACKAGE_PATH/$packname
fi

logfile=$PACKAGE_PATH/pack_publish.log
compiledir=$packname.compile

now=`date +"%Y-%m-%d %H:%M:%S"`
echo date=$now >> $logfile
echo "compile $packname" | tee -a $logfile
oldpwd=`pwd`
mkdir -p $compiledir
tar -zxvf $packname -C $compiledir
sh compiledir.sh $compiledir $compiledir "$LUAC" | tee -a $logfile
tar -zcvf $compiledir.tar.gz -C $compiledir .
if type md5sum >/dev/null 2>&1; then
	md5=$(md5sum $compiledir.tar.gz | cut -d ' ' -f 1)
else
	# macosx has command md5,but not md5sum
	md5=$(md5 $compiledir.tar.gz | cut -d ' ' -f 4)
fi
mv $compiledir.tar.gz $compiledir.$md5.tar.gz
echo "compile: $compiledir.$md5.tar.gz" | tee -a $logfile
echo "compiledir: $compiledir" | tee -a $logfile
cd $oldpwd
