srcdir=$1
dstdir=$2
issame=0
if [ "$dstdir" = "" -o "$dstdir" = "$srcdir" ]; then 
	dstdir=$srcdir
	issame=1
fi

if ! [ -d $srcdir ]; then
	echo "need source directory"
	exit
fi

if [ $issame -ne 1 ]; then
	rm -rf $dstdir
	mkdir -p $dstdir
fi

LUAC=$3
if [ "$LUAC" = "" ]; then
	LUAC=luac
fi

compile(){
	local filename=$1
	# ignore config/*
	if [ "${filename#*config/}" != "$filename" ]; then
		return
	fi
	# *.lua
	basename="${filename%.lua}"
	if [ "$basename" != "$filename" ]; then
		if [ "$LUAC" = "luajit" ]; then
			echo "$LUAC -b $filename $dstdir/$filename"
			$LUAC -b $filename $dstdir/$filename
		else
			echo "$LUAC -o $dstdir/$filename $filename"
			$LUAC -o $dstdir/$filename $filename
		fi
	fi
}

walkdir(){
	local path=$1
	local fullpath=$srcdir/$path
	if [ -d $fullpath ]; then
		if [ $issame -ne 1 ]; then
			echo "mkdir -p $dstdir/$path"
			mkdir -p $dstdir/$path
		fi
		for filename in $(ls -a $fullpath); do
			if [ "$filename" != "." ] && [ "$filename" != ".." ]; then
				walkdir "$path/$filename"
			fi
		done
	elif [ -f $fullpath ]; then
		# just compile src/**/*.lua
		#if [ `expr $fullpath : "^.*/src/.*\.lua$"` -gt 0 ]
		if [ `expr $fullpath : "^.*\.lua$"` -gt 0 ]; then
			compile $path
		else
			if [ $issame -ne 1 ]; then
				echo "cp -p $fullpath $dstdir/$path"
				cp -p $fullpath $dstdir/$path
			fi
		fi
	fi
}

oldpwd=`pwd`
cd $srcdir
echo "compiling $srcdir ===> $dstdir..."
for path in $(ls -a $srcdir); do
	if [ $path != "." ] && [ $path != ".." ]; then
		walkdir $path
	fi
done
cd $oldpwd
echo "compile end"
