#!/bin/bash
LOCALDIR="$(cd $(dirname $0); pwd)"
binner=$LOCALDIR/bin
source $binner/settings
tempdir=$LOCALDIR/TEMP
tiklog=$LOCALDIR/TIK3_`date "+%y%m%d"`.log
AIK="$binner/AIK"
MBK="$binner/MBK"
platform=$(uname -m)
ostype=$(uname -o)
getprop() { grep "$1" "${SYSTEM_DIR}/build.prop" | cut -d "=" -f 2; } #读取机型配置
export LD_LIBRARY_PATH=$ebinner/lib64
PIP_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple/
# Add for cygwin by affggh
if [ "$ostype" = "Cygwin" ]; then
  source $binner/log.sh
  [ "${platform}" = "x86_64" ] || ( LOGE "Platform not support if cygwin32 !" && exit 1 )
  LOGI "检测到Cygwin64 运行环境..."
  ebinner="$binner/Cygwin/$platform"
  export PATH=$ebinner:$binner/Cygwin/jdk-18.0.1.1:$PATH
  export ostype
  sudo() {
	# Hack : cygwin dose not have sudo
	# you can use cygstart --action=runas
    LOGW "Cygwin 没有sudo命令，因此直接执行"
	$@
  }
  sleep $sleeptime
else
  ebinner="$binner/Linux/$platform"
fi
dtc="$ebinner/dtc"
mkdtimg_tool="$binner/mkdtboimg.py"
yecho(){ echo -e "\033[36m[$(date '+%H:%M:%S')]${1}\033[0m" ; }	#显示打印
rmdire(){ if [ -d "$1" ];then sudo rm -rf $1 ;fi ; }	#显示打印
ywarn(){ echo -e "\033[31m${1}\033[0m" ; }	#显示打印
ysuc(){ echo -e "\033[32m[$(date '+%H:%M:%S')]${1}\033[0m" ; }	#显示打印
getinfo(){ export info=$($ebinner/gettype -i $1) ; }
getsize(){ export filesize=$(stat -c "%s" "$1") ; }
cleantemp(){ sudo rm -rf $tempdir/* ; }

# 项目菜单
function promenu(){
clear && cd $LOCALDIR
content=$(curl -s https://v1.jinrishici.com/all.json)
shiju=$(echo $content| cut -d \" -f 4 )
from=$(echo $content| cut -d \" -f 8)
author=$(echo $content| cut -d \" -f 12)
echo -e "\033[31m $(cat $binner/banners/$banner) \033[0m"
echo 

printf "\e[5;16H\e[92;44m Beta Edition \e[0m"
printf "\e[8;0H"

echo -ne "\033[36m “$shiju”"
echo -e "\033[36m---$author《$from》\033[0m"
echo -e " \n"

echo -e " >\033[33m 项目列表 \033[0m\n"
echo -e "\033[31m   [00]  删除项目\033[0m\n"
echo -e "   [0]  新建项目\n"
pro=0 && del=0 && chooPro=0
if ls TI_* >/dev/null 2>&1;then
	for pros in $(ls -d TI_*/| sed 's/\///g')
	do 
		if [ -d "$pros" ];then
			pro=$((pro+1))
			echo -e "   [$pro]  $pros\n"
			eval "pro$pro=$pros" 
		fi
	done
fi
echo -e "  --------------------------------------"
echo -e "\033[33m  [55] 解压  [66] 退出  [77] 设置  [88] TIK实验室\033[0m"
echo -e ""
echo -e " \n"
read -p "  请输入序号：" op_pro
if [ "$op_pro" == "55" ]; then
	unpackrom
elif [ "$op_pro" == "88" ]; then
	echo ""
	echo "维护中..."
	echo ""
	sleep $sleeptime
	return 0
	#miuiupdate
elif [ "$op_pro" == "00" ]; then
	read -p "  请输入你要删除的项目序号：" op_pro
    del=1 && Project
elif [ "$op_pro" == "0" ]; then
	read -p "请输入项目名称(非中文)：TI_" projec
	if test -z "$projec";then
		ywarn "Input error！"
		sleep $sleeptime
		promenu
	else  
		project=TI_$projec
		if [[ -d "$project" ]]; then
			project="$project"-`date "+%m%d%H%M%S"`
			ywarn "项目已存在！自动命名为：$project"
			sleep $sleeptime
		fi
		mkdir $project $project/config
		menu
	fi
elif [ "$op_pro" == "66" ]; then
	clear
	exit
elif [ "$op_pro" == "77" ]; then
	settings
elif [[ $op_pro =~ ^-?[1-9][0-9]*$ ]]; then
	chooPro=1 && Project
else
	ywarn "  Input error!"
	sleep $sleeptime
fi
	promenu
}

# 主菜单
function menu(){
PROJECT_DIR0=$LOCALDIR/$project
# Fix cygwin path issue
if [ "$ostype" = "Cygwin" ]; then
	PROJECT_DIR=`cygpath -w "$PROJECT_DIR0"`
else
	PROJECT_DIR=$PROJECT_DIR0
fi
clear && cd $PROJECT_DIR

if [[ ! -d "config" ]]; then
	ywarn "项目已损坏！"
	menu
fi
if [[ ! -d "${PROJECT_DIR}/TI_out" ]]; then
	mkdir ${PROJECT_DIR}/TI_out
fi
echo -e "\n"
echo -e " \033[31m>ROM菜单 \033[0m\n"
echo -e "  项目：$project"
if [[ -f $PROJECT_DIR/system/system/build.prop ]]; then
	SYSTEM_DIR0="$PROJECT_DIR0/system/system"
if [ "$ostype" = "Cygwin" ]; then
	SYSTEM_DIR=`cygpath -w "$SYSTEM_DIR0"`
else
	SYSTEM_DIR=$SYSTEM_DIR0
fi
elif [[ -f $PROJECT_DIR/system/build.prop ]]; then
	SYSTEM_DIR0="$PROJECT_DIR0/system"
if [ "$ostype" = "Cygwin" ]; then
	SYSTEM_DIR=`cygpath -w "$SYSTEM_DIR0"`
else
	SYSTEM_DIR=$SYSTEM_DIR0
fi
else
	SYSTEM_DIR=0
	ywarn "  非完整ROM项目"
fi

echo  
echo -e "\033[33m    1> 项目主页     2> 解包菜单\033[0m\n" 
echo -e "\033[36m    3> 打包菜单     4> 插件菜单\033[0m\n" 
echo -e "\033[32m    5> 一键封装\033[0m\n" 
echo  
read -p "    请输入编号: " op_menu
case $op_menu in
		1)
        promenu
        ;;
		2)
        unpackChoo
        ;;
		3)
        packChoo
        ;;
		4)
        subbed
        ;;
		5)
		# packzip
		echo "维护中..."
		echo ""
		sleep $sleeptime
		;;
        *)
        ywarn "   Input error!"
		sleep $sleeptime
esac
menu
}

function Project(){
eval "project=\$pro$op_pro"
if [[ $project == "" ]];then
	ywarn "  Input error!"
	sleep $sleeptime
	promenu
else
    if [[ "$del" == "1" ]]; then
        read -p "  确认删除？[1/0]" delr
        if [ "$delr" == "1" ];then
		eval "pro$pro="
		rm -fr $project && ysuc "  删除成功！" && sleep $sleeptime
        fi
        promenu
    elif [[ "$chooPro" == "1" ]]; then
        cd $project
        menu
	fi
fi
}

#解包
function unpackChoo(){
clear && cd $PROJECT_DIR
echo -e " \033[31m >分解 \033[0m\n"
filen=0
ywarn " 请将文件放于$project根目录下！"
echo  
echo -e " [0]- 分解所有文件\n"
if ls -d *.br >/dev/null 2>&1;then
echo -e "\033[33m [Br]文件\033[0m\n"
	for br0 in $(ls *.br)
	do 
	if [ -f "$br0" ] ; then
		filen=$((filen+1))
		echo -e "   [$filen]- $br0\n"
		eval "file$filen=$br0" 
		eval "info$filen=br"
	fi
	done
fi

if ls -d *.new.dat >/dev/null 2>&1;then
echo -e "\033[33m [Dat]文件\033[0m\n"
	for dat0 in $(ls *.new.dat)
	do 
	if [ -f "$dat0" ] ; then
		filen=$((filen+1))
		echo -e "   [$filen]- $dat0\n"
		eval "file$filen=$dat0" 
		eval "info$filen=dat"
	fi
	done
fi

if ls -d *.new.dat.1 >/dev/null 2>&1;then
	for dat10 in $(ls *.dat.1)
	do 
	if [ -f "$dat10" ] ; then
		filen=$((filen+1))
		echo -e "   [$filen]- $dat10 <分段DAT>\n"
		eval "file$filen=$dat10" 
		eval "info$filen=dat.1"
	fi
	done
fi

if ls -d *.img >/dev/null 2>&1;then
echo -e "\033[33m [Img]文件\033[0m\n"
	for img0 in $(ls *.img)
	do 
	if [ -f "$img0" ] ; then
		info=$($ebinner/gettype -i $img0)
		filen=$((filen+1))
		if [ "$info" == "ext" ]; then
			echo -e "   [$filen]- $img0 <EXT4>\n"
		elif [ "$info" == "erofs" ]; then
			echo -e "   [$filen]- $img0 <EROFS>\n"
		elif [ "$info" == "sparse" ]; then
			echo -e "   [$filen]- $img0 <Sparse>\n"
		elif [ "$info" == "dtbo" ]; then
			echo -e "   [$filen]- $img0 <DTBO>\n"
		elif [ "$info" == "boot" ]; then
			echo -e "   [$filen]- $img0 <BOOT>\n"
		elif [ "$info" == "vendor_boot" ]; then
			echo -e "   [$filen]- $img0 <VENDOR_BOOT>\n"
		elif [ "$info" == "super" ] || [ $(echo "$img0" | grep "super") ]; then
			echo -e "   [$filen]- $img0 <SUPER>\n"
		else
			ywarn "   [$filen]- $img0 <UNKNOWN>\n"
		fi
		eval "file$filen=$img0" 
		eval "info$filen=img"
		if [ "$info" == "sparse" ]; then eval "info$filen=sparse" ;fi
	fi
	done
fi

if ls -d *.bin >/dev/null 2>&1;then
	for bin0 in $(ls *.bin)
	do 
	if [ -f "$bin0" ] ; then
		info=$($ebinner/gettype -i $bin0)
		if [ "$info" == "payload" ]; then
			filen=$((filen+1))
			echo -e "   [$filen]- $bin0 <BIN>\n"
			eval "file$filen=$bin0" 
			eval "info$filen=payload"
		fi
	fi
	done
fi

if ls -d *.ozip >/dev/null 2>&1;then
echo -e "\033[33m [Ozip]文件\033[0m\n"
	for ozip0 in $(ls *.ozip)
	do 
	if [ -f "$ozip0" ] ; then
		info=$($ebinner/gettype -i $ozip0)
		if [ "$info" == "ozip" ]; then
			filen=$((filen+1))
			echo -e "   [$filen]- $ozip0\n"
			eval "file$filen=$ozip0" 
			eval "info$filen=ozip"
		fi
	fi
	done
fi

if ls -d *.ofp >/dev/null 2>&1;then
echo -e "\033[33m [Ofp]文件\033[0m\n"
	for ofp0 in $(ls *.ofp)
	do 
	if [ -f "$ofp0" ] ; then
		info=$($ebinner/gettype -i $ofp0)
		filen=$((filen+1))
		echo -e "   [$filen]- $ofp0\n"
		eval "file$filen=$ofp0" 
		eval "info$filen=ofp"
	fi
	done
fi

if ls -d *.ops >/dev/null 2>&1;then
echo -e "\033[33m [Ops]文件\033[0m\n"
	for ops0 in $(ls *.ops)
	do 
	if [ -f "$ops0" ] ; then
		filen=$((filen+1))
		echo -e "   [$filen]- $ops0\n"
		eval "file$filen=$ops0" 
		eval "info$filen=ops"
	fi
	done
fi

if ls -d *.win >/dev/null 2>&1;then
echo -e "\033[33m [Win]文件\033[0m\n"
	for win0 in $(ls *.win)
	do 
	if [ -f "$win0" ] ; then
		filen=$((filen+1))
		echo -e "   [$filen]- $win0 <WIN> \n"
		eval "file$filen=$win0" 
		eval "info$filen=win"
	fi
	done
fi

if ls -d *.win000 >/dev/null 2>&1;then
	for win0000 in $(ls *.win000)
	do 
	if [ -f "$win0000" ] ; then
		filen=$((filen+1))
		echo -e "   [$filen]- $win0000 <分段WIN> \n"
		eval "file$filen=$win0000" 
		eval "info$filen=win000"
	fi
	done
fi
if ls -d *dtb >/dev/null 2>&1;then
echo -e "\033[33m [Dtb]文件\033[0m\n"
	for dtb0 in $(ls)
	do 
	if [ -f "$dtb0" ] ; then
		info=$($ebinner/gettype -i $dtb0)
		if [ "$info" == "dtb" ]; then
			filen=$((filen+1))
			echo -e "   [$filen]- $dtb0\n"
			eval "file$filen=$dtb0" 
			infile=$PROJECT_DIR/$infile
			eval "info$filen=dtb"
		fi
	fi
	done
fi

echo -e ""
echo -e "\033[33m  [77] 菜单  [88] 循环解包  [99] 占位\033[0m"
echo -e "  --------------------------------------"
read -p "  请输入对应序号：" filed

if [[ "$filed" = "0" ]]; then
	echo  
	for ((filed = 1; filed <= $filen; filed++))
	do
		eval "infile=\$file$filed"
		infile=`realpath $infile`
		sf=`basename $infile`
		eval "info=\$info$filed"
		unpack $infile
	done
	unpackChoo
elif [[ "$filed" = "88" ]]; then
	echo  
	read -p "  是否解包所有文件？ [1/0]	" upacall
	for ((filed = 1; filed <= $filen; filed++))
	do
		eval "infile=\$file$filed"
		infile=`realpath $infile`
		sf=`basename $infile`
		eval "info=\$info$filed"
		if [ "$upacall" != "1" ];then
			read -p "  是否解包$sf?[1/0]	" imgcheck </dev/tty
		fi
		if [[ "$upacall" == "1" ]] || [ "$imgcheck" != "0" ];then
			unpack $infile
		fi
	done
	unpackChoo
elif [[ "$filed" = "77" ]]; then
	menu
elif [[ "$filed" = "99" ]]; then
	echo   && menu
elif [[ $filed =~ ^-?[1-9][0-9]*$ ]]; then
	if [ $filed -gt $filen ];then
		ywarn "Input error!"
		sleep $sleeptime && menu
	else
		eval "infile=\$file$filed"
		infile=`realpath $infile`
		eval "info=\$info$filed"
		unpack $infile
	fi
	unpackChoo
else
	ywarn "Input error!" && menu
	sleep $sleeptime
fi
}

function packChoo(){
clear && cd $PROJECT_DIR
echo -e " \033[31m >打包 \033[0m\n"
partn=0
if ls -d config/*_fs_config >/dev/null 2>&1;then
echo -e "   [0]- 打包所有镜像\n"
	for packs in $(ls config/*_fs_config)
	do
	sf=$(basename $packs | sed 's/_fs_config//g')
	if [ -f "$packs" ] ; then
		partn=$((partn+1))
		eval "part$partn=$sf" 
		typeo=$(cat config/${sf}_type.txt)
		eval "type$partn=$typeo"
		echo -e "   [$partn]- $sf <$typeo>\n"
	fi
	done
fi

if ls -d config/*.info >/dev/null 2>&1;then
	for packs in $(ls config/*.info)
	do
	sf=$(basename $packs | sed 's/.info//g')
	if [ -f "$packs" ] ; then
		partn=$((partn+1))
		echo -e "   [$partn]- $sf <bootimg>\n"
		toolo=$(cat config/${sf}_tool.txt)
		eval "tool$partn=$toolo"
		eval "part$partn=$sf" 
		eval "type$partn=bootimg"
	fi
	done
fi

if ls -d config/dtbinfo_* >/dev/null 2>&1;then
	for packs in $(ls config/dtbinfo_*)
	do
	sf=$(basename $packs | sed 's/dtbinfo_//g')
	if [ -f "$packs" ] ; then
		partn=$((partn+1))
		echo -e "   [$partn]- $sf <dtb>\n"
		eval "part$partn=$sf" 
		eval "type$partn=dtb"
	fi
	done
fi

if ls -d config/dtboinfo_* >/dev/null 2>&1;then
	for packs in $(ls config/dtboinfo_*)
	do
	sf=$(basename $packs | sed 's/dtboinfo_//g')
	if [ -f "$packs" ] ; then
		partn=$((partn+1))
		echo -e "   [$partn]- $sf <dtbo>\n"
		eval "part$partn=$sf" 
		eval "type$partn=dtbo"
	fi
	done
fi

echo -e ""
echo -e "\033[33m [55] 循环打包 [66] 打包Super [77] 打包Payload [88]菜单\033[0m"
echo -e "  --------------------------------------"
read -p "  请输入对应序号：" filed

if [[ "$filed" = "0" ]]; then
	read -p "  输出文件格式[1]br [2]dat [3]img:" op_menu
	case $op_menu in
		1)
		isbr=1 && isdat=1
		;;
		2)
		isbr=0 && isdat=1
		;;		
		*)
		isbr=0 && isdat=0
	esac
	if [[ "$diyimgtype" == "1" ]];then
		echo "手动打包所有分区格式为：[1]ext4 [2]erofs" syscheck
		case $syscheck in
			2)
			imgtype="erofs"
			;;
			*)
			imgtype="ext4"
		esac
	fi
	for ((filed = 1; filed <= $partn; filed++))
	do
		eval "partname=\$part$filed"
		eval "imgtype=\$type$filed"
		eval "boottool=\$tool$filed"
		yecho "打包$partname..."
		if [[ "$imgtype" == "bootimg" ]];then
			bootpac $partname | tee $tiklog
		elif [[ "$imgtype" == "dtb" ]];then
			makedtb $partname | tee $tiklog
		elif [[ "$imgtype" == "dtbo" ]];then
			makedtbo $partname | tee $tiklog
		else
			inpacker $partname | tee $tiklog
		fi
	done
elif [[ "$filed" = "55" ]]; then
	echo  
	read -p "  是否打包所有镜像？ [1/0]	" pacall
	read -p "  输出所有文件格式[1]br [2]dat [3]img:" op_menu
	case $op_menu in
		1)
		isbr=1 && isdat=1
		;;
		2)
		isbr=0 && isdat=1
		;;		
		*)
		isbr=0 && isdat=0
	esac
	
	if [[ "$diyimgtype" == "1" ]];then
		read -p "您要手动打包所有分区格式为：[1]ext4 [2]erofs" syscheck
		case $syscheck in
			2)
			imgtype="erofs"
			;;
			*)
			imgtype="ext4"
		esac
	fi

	for ((filed = 1; filed <= $partn; filed++))
	do
		eval "partname=\$part$filed"
		eval "imgtype=\$type$filed"
		eval "boottool=\$tool$filed"
		if [ "$pacall" != "1" ];then
			read -p "  是否打包$partname?[1/0]	" imgcheck </dev/tty
		fi
		if [[ "$pacall" == "1" ]] || [ "$imgcheck" != "0" ];then
			yecho "打包$partname..."
			if [[ "$imgtype" == "bootimg" ]];then
				bootpac $partname | tee $tiklog
			elif [[ "$imgtype" == "dtb" ]];then
				makedtb $partname | tee $tiklog
			elif [[ "$imgtype" == "dtbo" ]];then
				makedtbo $partname | tee $tiklog
				else
			inpacker $partname | tee $tiklog
			fi
		fi
	done
elif [[ "$filed" = "66" ]]; then
	packsuper
elif [[ "$filed" = "77" ]]; then
	packpayload
elif [[ "$filed" = "88" ]]; then
	menu
elif [[ $filed =~ ^-?[1-9][0-9]*$ ]]; then
	if [ $filed -gt $partn ];then
		ywarn "Input error!"
		sleep $sleeptime && menu
	else
		eval "partname=\$part$filed"
		eval "imgtype=\$type$filed"
		eval "boottool=\$tool$filed"
		if [[ ! "$diyimgtype" == "1" ]] && [[ ! "$imgtype" == "bootimg" ]] && [[ ! "$imgtype" == "dtb" ]] && [[ ! "$imgtype" == "dtbo" ]];then
		read -p "  输出文件格式[1]br [2]dat [3]img:" op_menu
		case $op_menu in
			1)
			isbr=1 && isdat=1
			;;
			2)
			isbr=0 && isdat=1
			;;		
			*)
			isbr=0 && isdat=0
		esac
		fi
		if [[ "$diyimgtype" == "1" ]] && [[ ! "$imgtype" == "bootimg" ]] && [[ ! "$imgtype" == "dtb" ]] && [[ ! "$imgtype" == "dtbo" ]];then
			read -p "您要手动打包分区格式为：[1]ext4 [2]erofs" syscheck
			case $syscheck in
				2)
				imgtype="erofs"
				;;
				*)
				imgtype="ext4"
			esac
		fi
		yecho "打包$partname..."
		if [[ "$imgtype" == "bootimg" ]];then
			bootpac $partname | tee $tiklog
		elif [[ "$imgtype" == "dtb" ]];then
			makedtb $partname | tee $tiklog
		elif [[ "$imgtype" == "dtbo" ]];then
			makedtbo $partname | tee $tiklog
		else
			inpacker $partname | tee $tiklog
		fi
	fi
else
	ywarn "Input error!" && menu
	sleep $sleeptime
fi
packChoo
}

#镜像打包
inpacker(){
source $binner/settings && cleantemp
name=${1}
mount_path="/$name"
file_contexts="${PROJECT_DIR}/config/${name}_file_contexts"
fs_config="${PROJECT_DIR}/config/${name}_fs_config"
if [[ "$utcstamp" == "" ]];then
	UTC=$(date -u +%s)
fi
out_img="$tempdir/${name}.img"
in_files="${PROJECT_DIR}/${name}"

img_size0=$(cat $PROJECT_DIR/config/${name}_size.txt)
img_size1=`du -sb $name | awk {'print $1'}`
if [[ "$diysize" == "1" ]] && [ "$img_size0" -lt "$img_size1" ] ;then
	ywarn "您设置的size过小,将动态调整size!"
	img_size0=`echo "$img_size1 + 41943040" |bc`  
elif [[ "$diysize" == "1" ]] ;then
	img_size0=$img_size0
else
	img_size0=`echo "$img_size1 + 41943040" |bc` 
fi
img_size=`echo $img_size0 | sed 's/\..*//g'`
size=`echo "$img_size0 / $BLOCKSIZE" |bc`
if [[ "$auto_fsconfig" == "1" ]] ;then
python3 $binner/fspatch.py $in_files $fs_config
fi

echo $img_size >$PROJECT_DIR/config/${name}_size.txt
if [[ -f "dynamic_partitions_op_list" ]]; then
sed -i "s/resize ${name}\s.*/resize ${name} $img_size/" $PROJECT_DIR/dynamic_partitions_op_list
fi
# weird path issue on cygwin
if [ $ostype = 'Cygwin' ]; then
	out_img=`cygpath -w "$out_img"`
	fs_config=`cygpath -w "$fs_config"`
	file_contexts=`cygpath -w "$file_contexts"`
	in_files=`cygpath -w "$in_files"`
fi
if [[ "$imgtype" == "erofs" ]];then
	${su} $ebinner/mkfs.erofs $erofslim --mount-point $mount_path --fs-config-file $fs_config --file-contexts $file_contexts $out_img $in_files
else
	if [ "$pack_e2" = "0" ];then
		sed -i "/+found/d" $file_contexts
		$ebinner/make_ext4fs -J -T $UTC -S $file_contexts -l $img_size -C $fs_config -L $name -a $name $out_img $in_files
	else
		$ebinner/mke2fs -O ^has_journal -L $name -I 256 -i $inodesize -M $mount_path -m 0 -t ext4 -b $BLOCKSIZE $out_img $size
		${su} $ebinner/e2fsdroid -e -T $UTC $extrw -C $fs_config -S $file_contexts $rw -f $in_files -a $mount_path $out_img
	fi
fi
if [[ "$diysize" == "" ]] ;then
yecho "压缩img中..."
if [[ "$imgtype" == "erofs" ]];then
	echo "Erofs镜像，跳过压缩..."
else
	resize2fs -f -M $out_img
fi
fi
if [ "$pack_sparse" = "1" ] || [ "$isdat" = "1" ];then
	img2simg $out_img $tempdir/${name}.s.img
	rm -rf $tempdir/${name}.img && mv -f $tempdir/${name}.s.img $tempdir/${name}.img
fi

if [ "$isbr" = "1" ];then
	rm -fr TI_out/${sf}.new.dat.br TI_out/${sf}.patch.dat TI_out/${sf}.transfer.list
elif [ "$isdat" = "1" ];then
	rm -fr TI_out/${sf}.new.dat TI_out/${sf}.patch.dat TI_out/${sf}.transfer.list
else
	mv -f $tempdir/${name}.img $PROJECT_DIR/TI_out/${name}.img
fi

if [ "$isdat" = "1" ];then
	rm -fr TI_out/${sf}.new.* TI_out/${sf}.patch.dat TI_out/${sf}.transfer.list
	python3 $binner/img2sdat/img2sdat.py $out_img -o $tempdir/ -v 4 -p ${name}
	rm -rf $out_img
fi
if [ "$isbr" = "1" ];then
	brotli -q $brcom $tempdir/${name}.new.dat -o $PROJECT_DIR/TI_out/${name}.new.dat.br
	mv $tempdir/${name}.transfer.list $tempdir/${name}.patch.dat $PROJECT_DIR/TI_out
elif [ "$isdat" = "1" ];then
	mv $tempdir/${name}.transfer.list $tempdir/${name}.new.dat $tempdir/${name}.patch.dat $PROJECT_DIR/TI_out
fi
cleantemp
}

#boot打包—AIK&MBK
bootpac(){
if [ "$boottool" = "AIK" ];then
	sf=${1}
	cp -afrv $PROJECT_DIR/$sf/* $AIK > /dev/null
	$AIK/repackimg.sh --forceelf | tee $tiklog
	if [ -e $AIK/unpadded-new.img ];then
		mv $AIK/unpadded-new.img $PROJECT_DIR/exaid/
	fi
	mv -f $AIK/image-new.img $PROJECT_DIR/TI_out/$sf.img
	$AIK/cleanup.sh
elif [ "$boottool" = "MBK" ];then
	sf=${1}
	sudo $MBK/repackimg.sh $PROJECT_DIR/config/$sf.img $PROJECT_DIR/$sf | tee $tiklog
	mv -f $PROJECT_DIR/$sf/new-boot.img $PROJECT_DIR/TI_out/$sf.img
fi
sleep $sleeptime
}

function undtb(){
dtbdir="$PROJECT_DIR/`basename $infile`_dtbs"
rm -rf $dtbdir && mkdir -p $dtbdir/dtb_files $dtbdir/dts_files
extract-dtb $infile -o $dtbdir/dtb_files
yecho "正在反编译dtb..."
for i in `ls $dtbdir/dtb_files/*.dtb`;do
	sf=$(basename $i | rev |cut -d'.' -f1 --complement | rev)
	$dtc -@ -I dtb -O dts "$dtbdir/dtb_files/$sf.dtb" -o "$dtbdir/dts_files/$sf.dts" > $PROJECT_DIR/config/dtbinfo_`basename $infile`
done
ysuc "反编译完成!"
sleep $sleeptime
if [[ $userid = "root" ]]; then
	chmod 777 -R $dtbdir
fi
}

function makedtb(){
sf=$1
dtbdir="$PROJECT_DIR/${sf}_dtbs"
rm -rf $dtbdir/new_dtb_files && mkdir $dtbdir/new_dtb_files
for dts_files in $(ls $dtbdir/dts_files) ;do
	new_dtb_files=$(echo "$dts_files" | rev |cut -d'.' -f1 --complement | rev)
	yecho "正在回编译$dts_files为$new_dtb_files.dtb"
	$dtc -@ -I "dts" -O "dtb" "$dtbdir/dts_files/$dts_files" -o "$dtbdir/new_dtb_files/$new_dtb_files.dtb"
	[ $? != 0 ] && ywarn "回编译dtb失败"
done
find $dtbdir/new_dtb_files -name "*.dtb" -exec cat {} > $PROJECT_DIR/TI_out/${sf} \;
ysuc "回编译完成！"
sleep $sleeptime
if [[ $userid = "root" ]]; then
	chmod 777 -R $dtbdir
fi
}

function undtbo(){
dtbodir="${sf}_dtbo"
rm -rf $dtbodir
mkdir -p $dtbodir/dtbo_files $dtbodir/dts_files
yecho "正在解压dtbo.img"
python3 $mkdtimg_tool dump "$infile" -b "$dtbodir/dtbo_files/dtbo" > $PROJECT_DIR/config/dtboinfo_$sf

for dtbo_files in $(ls $dtbodir/dtbo_files) ;do
	dts_files=$(echo "$dtbo_files" | sed 's/dtbo/dts/g')
	yecho "正在反编译$dtbo_files为$dts_files"
	$dtc -@ -I "dtb" -O "dts" "$dtbodir/dtbo_files/$dtbo_files" -o "$dtbodir/dts_files/$dts_files" > /dev/null 2>&1
	[ $? != 0 ] && ywarn "反编译$dtbo_files失败"
done
ysuc "解压完成!"
if [[ $userid = "root" ]]; then
	chmod 777 -R $dtbodir
fi
}

function makedtbo(){
sf=$1
dtbodir="$PROJECT_DIR/${sf}_dtbo"
rm -rf $dtbodir/new_dtbo_files $PROJECT_DIR/TI_out/${sf}.img && mkdir -p $dtbodir/new_dtbo_files

dts_files_name=$(ls $dtbodir/dts_files)

for dts_files in $dts_files_name ;do
	new_dtbo_files=$(echo "$dts_files" | sed 's/dts/dtbo/g')
	yecho "正在回编译$dts_files为$new_dtbo_files"
	$dtc -@ -I "dts" -O "dtb" "$dtbodir/dts_files/$dts_files" -o "$dtbodir/new_dtbo_files/$new_dtbo_files" > /dev/null 2>&1
done

#file_number=$(ls -l $dtbodir/new_dtbo_files | grep "^-" | wc -l)
yecho "正在生成dtbo.img..."
python3 $mkdtimg_tool create "$PROJECT_DIR/TI_out/${sf}.img" --page_size="4096" $dtbodir/new_dtbo_files/*
if [ $? = 0 ];then
	ysuc "${sf}.img生成完毕!"
	if [[ $userid = "root" ]]; then
		chmod 777 -R $dtbodir
	fi
else
	ywarn "${sf}.img生成失败!"
fi
sleep $sleeptime
}

#文件解包
function unpack(){
sf=$(basename $infile | sed 's/.new.dat//g'| rev |cut -d'.' -f1 --complement | rev )
if [[ ! -d "$PROJECT_DIR/config" ]]; then
    mkdir $PROJECT_DIR/config
fi
cleantemp
rmdire ${sf} ${sf}_dtbs ${sf}_dtbo | tee $tiklog
rm -rf config/${sf}_file_contexts config/${sf}_fs_config config/${sf}_size.txt config/${sf}_type.txt config/${sf}.info
yecho "解包$sf中..."
if [ "$info" = "sparse" ];then
	yecho "sparseimg转换为rawimg中..."
	simg2img $infile $tempdir/$sf.img | tee $tiklog
	yecho "解压rawimg中..."
	infile=$tempdir/${sf}.img && getinfo $infile && imgextra
elif [ "$info" = "dtbo" ];then
	undtbo
elif [ "$info" = "br" ];then
	${su} brotli -d $infile -o $tempdir/$sf.new.dat > /dev/null
	python3 $binner/sdat2img.py $sf.transfer.list $tempdir/$sf.new.dat $tempdir/$sf.img >/dev/null 2>&1
	infile=$tempdir/${sf}.img && getinfo $infile && imgextra
elif [ "$info" = "dtb" ];then
	undtb
elif [ "$info" = "dat" ];then
	python3 $binner/sdat2img.py $sf.transfer.list $sf.new.dat $tempdir/$sf.img >/dev/null 2>&1
	infile=$tempdir/${sf}.img && getinfo $infile && imgextra
elif [ "$info" = "img" ];then
	getinfo $infile && imgextra
elif [ "$info" = "ofp" ];then
	read -p " ROM机型处理器为？[1]高通 [2]MTK	" ofpm
	if [ "$ofpm" = "1" ]; then
		python3 $binner/oppo_decrypt/ofp_qc_decrypt.py $infile $PROJECT_DIR/$sf | tee $tiklog
	elif [ "$ofpm" = "2" ];then
		python3 $binner/oppo_decrypt/ofp_mtk_decrypt.py $infile $PROJECT_DIR/$sf | tee $tiklog
	fi
elif [ "$info" = "ozip" ];then
	python3 $binner/oppo_decrypt/ozipdecrypt.py $infile | tee $tiklog
elif [ "$info" = "ops" ];then
	python3 $binner/oppo_decrypt/opscrypto.py decrypt $infile | tee $tiklog
elif [ "$info" = "payload" ];then
	yecho "$sf所含分区列表："
if [ "$ostype" = "Cygwin" ]; then
	infile=`cygpath -w "$PROJECT_DIR/payload.bin"` && payloadout=`cygpath -w "$PROJECT_DIR/payload"`
fi
	$ebinner/payload-dumper-go -l $infile
	read -p "请输入需要解压的分区名(空格隔开)/all[全部]	" extp </dev/tty
	if [ "$extp" = "all" ];then 
		$ebinner/payload-dumper-go $infile -o $payloadout
	else
		if [[ ! -d "payload" ]]; then
			mkdir $PROJECT_DIR/payload
		fi
		for d in $extp
		do
			$ebinner/payload-dumper-go -p $d $infile -o $payloadout
		done
	fi
elif [ "$info" = "win000" ];then
	${su} simg2img *${sf}.win* $PROJECT_DIR/${sf}.win | tee $tiklog
	sudo python3 $binner/imgextractor.py $PROJECT_DIR/${sf}.win $PROJECT_DIR | tee $tiklog
elif [ "$info" = "win" ];then
	sudo python3 $binner/imgextractor.py $infile $PROJECT_DIR | tee $tiklog
elif [ "$info" = "dat.1" ];then
	${su} cat ${sf}.new.dat.{1..999} >> $tempdir/${sf}.new.dat
	python3 $binner/sdat2img.py $sf.transfer.list $tempdir/${sf}.new.dat $tempdir/$sf.img >/dev/null 2>&1
	infile=$tempdir/${sf}.img && getinfo $infile && imgextra
else
	ywarn "未知格式！"
fi
if [[ $userid = "root" ]]; then
	${su} chmod 777 -R $sf > /dev/null 2>&1
fi
cleantemp
}

#Img解包
function imgextra(){
if [ "$info" = "ext" ]; then
	sudo python3 $binner/imgextractor.py $infile $PROJECT_DIR | tee $tiklog
	echo "ext4" >>$PROJECT_DIR/config/${sf}_type.txt
	if [ ! $? = "0" ];then
		ywarn "解压失败"
	fi
elif [ "$info" = "erofs" ];then
	$ebinner/erofsUnpackRust $infile $PROJECT_DIR | tee $tiklog
	echo "erofs" >>$PROJECT_DIR/config/${sf}_type.txt
	if [ ! $? = "0" ];then
		ywarn "解压失败"
	fi
elif [ "$info" = "dtbo" ];then
	undtbo
elif [ "$info" = "super" ]|| [ $(echo "$sf" | grep "super") ];then
	yecho "获取Super信息中..."
	$ebinner/lpdump $infile >>$tempdir/super_dyn.info && rm -rf $PROJECT_DIR/config/super.info
	echo header_flags=`grep "Header flags" "$tempdir/super_dyn.info" | cut -d " " -f 3` >> $PROJECT_DIR/config/super.info
	echo metadata_version=`grep "Metadata version" "$tempdir/super_dyn.info" | cut -d " " -f 3` >> $PROJECT_DIR/config/super.info
	echo metadata_size=`grep "Metadata max size" "$tempdir/super_dyn.info" | cut -d " " -f 4` >> $PROJECT_DIR/config/super.info
	echo slot_num=`grep "Metadata slot count" "$tempdir/super_dyn.info" | cut -d " " -f 4` >> $PROJECT_DIR/config/super.info
	grep -A 6 "Block device table:" "$tempdir/super_dyn.info" >> $tempdir/super_pd.info
	echo super_name=`grep "Partition name" "$tempdir/super_pd.info" | cut -d " " -f 5` >> $PROJECT_DIR/config/super.info
	echo supersize=`grep "Size:" "$tempdir/super_pd.info" | cut -d " " -f 4` >> $PROJECT_DIR/config/super.info
	echo super_groupn=`grep -n "Name:" "$tempdir/super_dyn.info" | cut -d " " -f 4 | tail -1 | sed 's/_b$//g'` >> $PROJECT_DIR/config/super.info
	echo super_part_list=\""`grep -n "Name:" "$tempdir/super_dyn.info" | cut -d " " -f 4 | sed '/default/,+3d'| sed 's/_a//g'| sed 's/_b//g'| uniq | sed ':label;N;s/\n/ /;b label'`"\" >> $PROJECT_DIR/config/super.info
	source $PROJECT_DIR/config/super.info
	yecho "
	[Header_Flags] $header_flags
	[Metadata version] $metadata_version
	[Metadata max size] $metadata_size
	[Metadata slot count] $slot_num
	[Partition name] $super_name
	[Super Size] $supersize
	[Super Group Name] $super_groupn
	[Super Partition List] $super_part_list"
	yecho "解压${sf}.img中..."
	mkdir super
	$ebinner/lpunpack $infile $PROJECT_DIR/super
	if [ ! $? = "0" ];then
		ywarn "解压失败"
	else
		ysuc "super解包完成!"
        if [[ $userid = "root" ]]; then
            chmod 777 -R $TARGETDIR
        fi
	fi
elif [ "$info" = "boot" ] || [ "$sf" == "boot" ] || [ "$sf" == "vendor_boot" ] || [ "$sf" == "recovery" ] ; then
	bootextra
    if [[ $userid = "root" ]]; then
        ${su} chmod 777 -R $sf
    fi
else
	ywarn "未知格式！请附带文件提交issue!"
fi
}

function bootextra(){
if [ "$default_boot_tool" = "AIK" ];then
	${su} mkdir $sf
	${su} $AIK/unpackimg.sh $infile $PROJECT_DIR | tee $PROJECT_DIR/config/$sf.info
	echo "AIK" >> $PROJECT_DIR/config/${sf}_tool.txt
	${su} mv $AIK/ramdisk $AIK/split_img $PROJECT_DIR/$sf
elif [ "$default_boot_tool" = "MBK" ];then
	${su} mkdir $sf && cd $sf
	sudo bash $MBK/unpackimg.sh $infile | tee $PROJECT_DIR/config/$sf.info
	sudo cp -f $infile $PROJECT_DIR/config
	echo "MBK" > $PROJECT_DIR/config/${sf}_tool.txt
	cd $PROJECT_DIR
fi
}

#手动打包Super
function packsuper(){
clear && rm -f $PROJECT_DIR/super/super.img
if [[ ! -d "super" ]]; then
	mkdir $PROJECT_DIR/super
fi
ywarn "请将需要打包的分区镜像放置于$PROJECT_DIR/super中！"
read -p "请输入打包模式：[1]A_only [2]AB [3]V-AB	" supertype
if [ "$supertype" = "3" ];then
	supertype=VAB
elif [ "$supertype" = "2" ];then
	supertype=AB
else
	supertype=A_only
fi
read -p "是否打包为sparse镜像？[1/0]	" ifsparse
if [[ -f $PROJECT_DIR/config/super_size.txt ]]; then
supersize=$(cat $PROJECT_DIR/config/super_size.txt)
read -p "检测到分解super大小为$supersize,是否按此大小继续打包？[1/0]" iforsize
fi
if [ ! "$iforsize" == "1" ];then
	read -p "请设置构建Super.img大小:[1]9126805504 [2]10200547328 [3]16106127360 [4]压缩到最小 [5]自定义" checkssize
	if [ "$checkssize" = "1" ];then
		supersize=9126805504
	elif [ "$checkssize" = "2" ];then
		supersize=10200547328
	elif [ "$checkssize" = "3" ];then
		supersize=16106127360
	elif [ "$checkssize" = "4" ];then
		minssize=1 && supersize=0
		ywarn "您已设置压缩镜像至最小,对齐不规范的镜像将造成打包失败；Size超出物理分区大小会造成刷入失败！"
		sleep 4
	else
		read -p "请输入super分区大小（字节数）	" supersize
	fi
fi
yecho "打包到super/super.img..."
insuper $PROJECT_DIR/super $PROJECT_DIR/super/super.img
packmenu
}

#手动打包Payload
function packpayload(){
clear && rm -f $PROJECT_DIR/super/super.img
if [[ ! -d "super" ]]; then
	mkdir $PROJECT_DIR/super
fi
ywarn "请将所有分区镜像放置于$PROJECT_DIR/payload中（非super）！"
ywarn "很耗时、很费CPU、很费内存，由于无官方签名故意义不大，请考虑后使用"
if [[ -f $PROJECT_DIR/config/super_size.txt ]]; then
supersize=$(cat $PROJECT_DIR/config/super_size.txt)
read -p "检测到分解super大小为$supersize,是否按此大小继续打包？[1/0]" iforsize
fi
if [ ! "$iforsize" == "1" ];then
	read -p "请设置构建Super.img大小:[1]9126805504 [2]10200547328 [3]16106127360 [4]压缩到最小 [5]自定义" supersize
	if [ "$supersize" = "1" ];then
		supersize=9126805504
	elif [ "$supersize" = "2" ];then
		supersize=10200547328
	elif [ "$supersize" = "3" ];then
		supersize=16106127360
	elif [ "$supersize" = "4" ];then
		minssize=1 && supersize=0
		ywarn "您已设置压缩镜像至最小,对齐不规范的镜像将造成打包失败；Size超出物理分区大小会造成刷入失败！"
		sleep 4
	else
		read -p "请输入super分区大小（字节数）	" supersize
	fi
fi
yecho "打包到$PROJECT_DIR/TI_out/payload..."
inpayload $supersize
packmenu
}

#打包Super
function insuper(){
Imgdir=$1
outputimg=$2
group_size_a=0 && group_size_b=0
if [[ $userid = "root" ]]; then
	${su} chmod -R 777 $Imgdir
fi
find $Imgdir -name "*" -type f -size 0c | xargs -n 1 rm -f
superpa="--metadata-size $metadatasize --super-name $supername "
if [ "$ifsparse" = "1" ];then
	superpa+="--sparse "
fi

if [ "$supertype" = "VAB" ];then
	superpa+="--virtual-ab "
fi
superpa+="-block-size=$SBLOCKSIZE "
for imag in $(ls $Imgdir/*.img);do
	image=$(echo "$imag" | rev | cut -d"/" -f1 | rev  | sed 's/_a.img//g' | sed 's/_b.img//g'| sed 's/.img//g')
	if ! echo $superpa | grep "partition "$image":readonly" > /dev/null && ! echo $superpa | grep "partition "$image"_a:readonly" > /dev/null  ;then
		if [ "$supertype" = "VAB" ] || [ "$supertype" = "AB" ];then
			if [[ -f $Imgdir/${image}_a.img ]] && [[ -f $Imgdir/${image}_b.img ]];then
				groupaab=1
				img_sizea=$(wc -c <$Imgdir/${image}_a.img) && img_sizeb=$(wc -c <$Imgdir/${image}_b.img)
			    group_size_a=`expr ${img_sizea} + ${group_size_a}`
			    group_size_b=`expr ${img_sizeb} + ${group_size_b}`
				superpa+="--partition "$image"_a:readonly:$img_sizea:${super_group}_a --image "$image"_a=$Imgdir/${image}_a.img --partition "$image"_b:readonly:$img_sizeb:${super_group}_b --image "$image"_b=$Imgdir/${image}_b.img "
			else
				mv $imag $Imgdir/$image.img > /dev/null 2>&1
				img_size=$(wc -c <$Imgdir/$image.img)
				group_size_a=`expr ${img_size} + ${group_size_a}`
				group_size_b=`expr ${img_size} + ${group_size_b}`
				superpa+="--partition "$image"_a:readonly:$img_size:${super_group}_a --image "$image"_a=$Imgdir/$image.img --partition "$image"_b:readonly:0:${super_group}_b "
			fi
		else
			img_size=$(wc -c <$Imgdir/$image.img)
			superpa+="--partition "$image":readonly:$img_size:${super_group} --image "$image"=$Imgdir/$image.img "
			group_size_a=`expr ${img_size} + ${group_size}`
		fi
	fi
done

if [ "$groupaab" == "" ];then
supermsize=`expr ${group_size_a} + ${SBLOCKSIZE} \* 1000`
elif [ "$groupaab" == "1" ];then
supermsize=`expr ${group_size_a} + ${group_size_b} + ${SBLOCKSIZE} \* 1000`
fi
if [ "$minssize" == "1" ];then
 supersize=$supermsize
elif [ $supermsize -gt $supersize ];then
 ywarn "设置SuperSize过小！已自动扩大！"
 supersize=$supermsize
fi

superpa+="--device super:$supersize "
if [ "$supertype" = "VAB" ] || [ "$supertype" = "AB" ];then
    superpa+="--metadata-slots 3 "
    superpa+=" --group ${super_group}_a:$supersize "
    superpa+=" --group ${super_group}_b:$supersize "
else
    superpa+="--metadata-slots 2 "
    superpa+=" --group ${super_group}:$supersize "
fi
superpa+="$fullsuper $autoslotsuffixing --output $outputimg"
if ( $ebinner/lpmake $superpa | tee $tiklog );then
    ysuc "成功创建super.img!"
else
    ywarn "创建super.img失败！"
fi
minssize="0" && groupaab=""
exit
sleep $sleeptime
}

#打包Payload
function inpayload(){
supersize=$1
rm -rf $PROJECT_DIR/TI_out/payload $PROJECT_DIR/payload/dynamic_partitions_info.txt && mkdir $PROJECT_DIR/TI_out/payload
yecho "将打包至：TI_out/payload，payload.bin & payload_properties.txt"
for sf in $(ls $PROJECT_DIR/payload/*.img);do
sf=$(basename $sf | sed 's/.img//g')
partname="${partname}${sf}:"
pimages="${pimages}$PROJECT_DIR/payload/${sf}.img:"
yecho "预打包$sf.img"
done
inparts="--partition_names=${partname%?} --new_partitions=${pimages%?}"
yecho "当前Super逻辑分区表：$superpart_list，可在<设置>中调整."
echo "super_partition_groups=${super_group}" >> $PROJECT_DIR/payload/dynamic_partitions_info.txt
echo "qti_dynamic_partitions_size=${supersize}" >> $PROJECT_DIR/payload/dynamic_partitions_info.txt
echo "qti_dynamic_partitions_partition_list=${superpart_list}" >> $PROJECT_DIR/payload/dynamic_partitions_info.txt

$ebinner/delta_generator --out_file=$PROJECT_DIR/TI_out/payload/payload.bin $inparts --dynamic_partition_info_file=$PROJECT_DIR/payload/dynamic_partitions_info.txt

if ( $ebinner/delta_generator --in_file=$PROJECT_DIR/TI_out/payload/payload.bin --properties_file=$PROJECT_DIR/TI_out/payload/payload_properties.txt );then
    ysuc "成功创建payload!"
else
    ywarn "创建payload失败！"
fi
sleep $sleeptime
}

function make_dyop_list(){
rm -rf dynamic_partitions_op_list && touch dynamic_partitions_op_list

# Remove all existing dynamic partitions and groups before applying full OTA
#remove_all_groups

if [[ -f $PROJECT_DIR/config/super_size.txt ]]; then
supersize=$(cat $PROJECT_DIR/config/super_size.txt)
read -p "检测到分解super大小为$supersize,是否按此大小继续打包？[1/0]" iforsize
fi

}

#解压制作
function unpackrom(){
clear && cd $Sourcedir &&zipn=0
echo -e " \033[31m >ROM列表 \033[0m\n"
ywarn "   请将ROM置于$Sourcedir下！"
if ls -d $Sourcedir/*.zip >/dev/null 2>&1;then
	for zip0 in $(ls $Sourcedir/*.zip)
	do 
	if [ -f "$zip0" ]; then
		getsize $zip0 >/dev/null 2>&1
		if [ "$filesize" -gt "$plugromlit" ];then
			zip=$(basename "$zip0" )
			zipn=$((zipn+1))
			echo -e "   [$zipn]- $zip\n"
			eval "zip$zipn=$zip0" 
		fi
	fi
	done
else
	ywarn "	没有ROM文件！"
fi
echo -e "--------------------------------------------------\n"
echo -e ""
read -p "请输入对应序列号：" zipd
eval "tzip=\$zip$zipd"
if [[ "$tzip" == "" ]];then
	ywarn "Input error!" && sleep $sleeptime && promenu
else
	zs=$(basename "$tzip" | sed 's/.zip//g')
	read -p "请输入项目名称(可留空)：" projec
	if test -z "$projec";then
		project=TI_$zs
	else  
		project=TI_$projec
	fi
	if [[ -d "$project" ]]; then
		project="$project"-`date "+%m%d%H%M%S"`
		ywarn "项目已存在！自动命名为：$project"
	fi
	PROJECT_DIR=$LOCALDIR/$project && mkdir $PROJECT_DIR
	echo 创建项目:$project 成功！
	yecho "解压刷机包中..."
	7z x "$tzip" -o"$LOCALDIR/$project/" > /dev/null
	sleep $sleeptime
	autounpack
	sleep $sleeptime
fi
}

#插件相关
function subche(){
eval "sub=\$mysubs$op_pro"
if [[ $sub == "" ]];then
	ywarn "  Input error!"
	sleep $sleeptime
else
    if [[ "$runsub" == "0" ]]; then
        read -p "确认删除？[1/0]" delr
        if [ "$delr" == "1" ];then
		eval "mysubs$subn="
		rm -fr $sub && ysuc "  删除成功！" && sleep $sleeptime
        fi
    else
		cd $PROJECT_DIR && bash $binner/subs/$sub/run.sh $PROJECT_DIR $SYSTEM_DIR
	fi
fi
subbed
}

#插件菜单
function subbed(){
if [[ ! -d $binner/subs ]]; then
	mkdir $binner/subs
fi
cd $binner/subs && clear
echo -e " >\033[31m插件列表 \033[0m\n"
subn=0 && mysubs=()
for sub in $(ls)
do 
	if [ -d "$sub" ];then
	subn=$((subn+1))
	echo -e "   [$subn]- $sub\n"
	eval "mysubs$subn=$sub" 
	fi
done
echo -e "----------------------------------------------\n"
echo -e "\033[33m> [66]-安装 [77]-删除 [88]-在线Plug仓库 [99]-项目菜单\033[0m"
echo -e ""
read -p "请输入序号：" op_pro
if [ "$op_pro" == "66" ]; then
	subber
elif [ "$op_pro" == "77" ]; then
	runsub=0
	read -p "请输入你要删除的插件序号：" op_pro
	subche
elif [ "$op_pro" == "88" ]; then
	getplug
elif [ "$op_pro" == "99" ]; then
	menu
elif [[ $op_pro =~ ^-?[0-9][0-9]*$ ]]; then
	runsub=1 && subche
else
	ywarn "  Input error!" && sleep $sleeptime && subbed
fi
}

#插件仓库
function getplug(){
clear && cd $LOCALDIR  
echo -e " >\033[33m 插件列表 \033[0m\n"
plug=0
for pls in $(curl -s https://gitee.com/yeliqin666/TIK_plug/raw/master/x86_64)
do 
	plug=$((plug+1))
	pls+="/raw/master/README.md"
	$(curl -s $pls)
	echo -e "\033[36m   [$plug]  $plugname\033[0m\n"
	echo -e "    作者：$plugauthor"
	echo -e "    介绍：$plugdiscri"
	echo -e "    开源地址：$plugsite\n"
	eval "plug$plug=$plugname" 
	eval "plugsite$plug=$pls" 
	echo -e "  ------------------------------------------------------------"
done
echo -e " \n"
ywarn "模块构建中，以上仅用于展示，不保证稳定、安全、可用，请关注TIK群内插件更新!"
read -p "   " ooooo
subbed
}

#安装插件
function subber(){
clear
cd $LOCALDIR
echo -e " \033[31m >插件列表 \033[0m\n"
zipn=0
ywarn "   请将插件置于$Sourcedir下！"
if ls -d $Sourcedir/*.zip >/dev/null 2>&1;then
	cd $Sourcedir
	for zip0 in $(ls $Sourcedir/*.zip)
	do 
	if [ -f "$zip0" ]; then
		getsize $zip0 >/dev/null 2>&1
		if [ "$filesize" -lt "$plugromlit" ];then
			zip=$(basename "$zip0" )
			zipn=$((zipn+1))
			echo -e "   [$zipn]- $zip\n"
			eval "zip$zipn=$zip0" 
		fi
	fi
	done
cd $LOCALDIR
else
ywarn "	没有插件文件！"
fi
echo -e "-------------------------------------------------------\n"
echo -e ""
read -p "请输入对应序列号：" zipd
eval "tzip=\$zip$zipd"
if [[ "$tzip" == "" ]];then
	ywarn "Input error!" && sleep $sleeptime
else
	zs=$(basename "$tzip" | rev | cut -d'.' -f1 --complement | rev)
	if [[ -d $binner/subs/$zs ]]; then
		${su} rm -fr $binner/subs/$zs
	fi
	mkdir $binner/subs/$zs
	yecho "安装插件[$zs]中..."
	7z x "$tzip" -o"$binner/subs/$zs" > /dev/null
	sudo chmod -R 777 $binner/subs/$zs
	ysuc "安装完成"
	sleep $sleeptime
fi
subbed
}

#获取MIUI地址
function miuiupdate(){
echo 
echo "[1]国内版 [2]印尼版 [3]俄版 [4]国际版 [5]欧版 [6]土耳其版  [7]台湾版 [8]日本版 [9]新加坡版"
read -p "请选择地区：" op_menu
case $op_menu in
        1)
        region=CN
        ;;
		2)
        region=ID
        ;;
		3)
        region=RU
        ;;
		4)
        region=Global
        ;;
		5)
        region=EEA
        ;;
		6)
		region=TR
		;;
		7)
        region=TW
        ;;
		8)
        region=GP
        ;;
		9)
        region=SG
        ;;
        *)
        region=CN
		ywarn "默认选择国内版！"
		sleep $sleeptime
esac
echo 
echo "[1]内测版 [2]稳定版"
read -p "请选择类型：" typr
	case $typr in
        1)
        type=beta
        ;;
		2)
        type=stable
        ;;
        *)
        type=beta
		ywarn "默认选择内测！"
		sleep $sleeptime
	esac
read -p "请输入机型代号：" mod
link="" && link=$(python3 $binner/get_miui.py $mod $region $type recovery)
if echo $link | grep "http" > /dev/null 2>&1 ; then
	echo $link
	read -p "是否开始下载？[1/0]：" ver
	case "$ver" in
		1)
		zip=$(basename $link)
		yecho "开始下载${zip}..."
		sleep $sleeptime
		aria2c -s 9 -x 2 $link -d $Sourcedir
		ysuc "下载完成！"
		;;
		*)
		echo  
	esac
fi
promenu
}

#解压ZIP
function autounpack(){
cd $PROJECT_DIR && mkdir config && cleantemp
if [[ -f $PROJECT_DIR/dynamic_partitions_op_list ]];then
    if grep "add_group" "dynamic_partitions_op_list" | grep "_a " > /dev/null ;then
		echo "super_type=VAB" >> $PROJECT_DIR/config/super.info
		super_groupn=`grep "add_group" "dynamic_partitions_op_list" | grep "_a "|cut -d " " -f 2 | sed 's/_a$//g'`
		yecho "读取动态分区簇名: $super_groupn"
		echo "super_group=$super_groupn" >> $PROJECT_DIR/config/super.info
		yecho "读取机型为:动态VAB设备"
		supergroupa=`grep "add_group" "dynamic_partitions_op_list" | grep "_a "|cut -d " " -f 3`
		echo "group_a_size=$supergroupa" >> $PROJECT_DIR/config/super.info
		supergroupb=`grep "add_group" "dynamic_partitions_op_list" | grep "_b "|cut -d " " -f 3`
		echo "group_b_size=$supergroupb" >> $PROJECT_DIR/config/super.info
		echo "header_flags=virtual_ab_device" >> $PROJECT_DIR/config/super.info
		yecho "已读取Super_Group_A:$supergroupa"
		yecho "已读取Super_Group_B:$supergroupb"
		if [ "$supergroupa" == "$supergroupb" ];then
			supersize=$supergroupa
			yecho "已读取Super分区大小:$supersize"
		fi
	else
	echo "header_flags=none" >> $PROJECT_DIR/config/super.info
	yecho "读取机型为:动态A-only设备"
	super_groupn=`grep "add_group" "dynamic_partitions_op_list" | cut -d " " -f 2`
	yecho "读取动态分区簇名: $super_groupn"
	echo "super_group=$super_groupn" >> $PROJECT_DIR/config/super.info
	supersize=`grep "add_group " "dynamic_partitions_op_list" | cut -d " " -f 3`
	yecho "已读取Super分区大小:$supersize"
	fi
fi
yecho "自动解包开始！"
#VAB自动解包
if [ -f "payload.bin" ]; then
	echo "header_flags=virtual_ab_device" >> $PROJECT_DIR/config/super.info
	yecho "读取机型为:动态VAB设备"
	yecho "解包 payload.bin..."
if [ "$ostype" = "Cygwin" ]; then
	payloadfile=`cygpath -w "$PROJECT_DIR/payload.bin"` && payloadout=`cygpath -w "$PROJECT_DIR/payload"`
fi
	$ebinner/payload-dumper-go $payloadfile -o $payloadout
	yecho "payload.bin解包完成！"
	rm -rf payload.bin && rm -rf care_map.pb && rm -rf apex_info.pb&& mv -f payload_properties.txt $PROJECT_DIR/config && cp -afrv $PROJECT_DIR/META-INF/com/android/metadata $PROJECT_DIR/config
	for infile in $(ls $PROJECT_DIR/payload/*.img)
	do
		sf=$(basename $infile | sed 's/.img//g')
		getinfo $infile
		if [[ $info = "Unknow" ]] || [[ $info = "dtbo" ]] || [[ $sf = "dsp" ]] || [[ $info = "vbmeta" ]];then
			ywarn "跳过解包$sf！"
		else
		    yecho "解包$sf...  "
			mv $infile $PROJECT_DIR && infile=$PROJECT_DIR/$sf.img
			imgextra
			ysuc "成功." && rm -f $sf.img
		fi
	done
	
else

# 解压br文件
if ls *.new.dat.br >/dev/null 2>&1;then
	ls *.new.dat.br | while read infile; do
		sf=$(basename $infile | sed 's/.new.dat//g'| rev |cut -d'.' -f1 --complement | rev )
		yecho "解包$sf..."
		${su} brotli -d $PROJECT_DIR/$infile -o $tempdir/$sf.new.dat > /dev/null
		python3 $binner/sdat2img.py $sf.transfer.list $tempdir/$sf.new.dat $tempdir/$sf.img >/dev/null 2>&1
		infile=$tempdir/${sf}.img && getinfo $infile && imgextra
		rm -rf ${sf}.new.dat.br ${sf}.patch.dat ${sf}.transfer.list > /dev/null 2>&1
	done
fi

# 合并分段dat
if ls *.dat.1 >/dev/null 2>&1;then
	ls *.new.dat.1 | while read infile; do
		th=$(basename $infile | cut -d"/" -f3| cut -d"." -f1)
		yecho "合并$th.new.dat..."
		${su} cat $PROJECT_DIR/${th}.new.dat.{1..999} >> $PROJECT_DIR/${th}.new.dat
		rm -rf $PROJECT_DIR/${th}.new.dat.{1..999}
	done
fi

# 解压dat
if ls *.dat >/dev/null 2>&1;then
	ls *.new.dat | while read infile; do
		sf=$(basename $infile | sed 's/.new.dat//g')
		yecho "解包$sf..."
		${su} python3 $binner/sdat2img.py ${sf}.transfer.list ${sf}.new.dat $tempdir/$sf.img >/dev/null 2>&1
		infile=$tempdir/${sf}.img && getinfo $infile && imgextra
		rm -rf $PROJECT_DIR/${sf}.new.dat && rm -rf $PROJECT_DIR/${sf}.patch.dat && rm -rf $PROJECT_DIR/${sf}.transfer.list > /dev/null 2>&1
	done
fi

# 解压img
if ls *.img >/dev/null 2>&1;then
	ls *.img | while read infile; do
		infile=$(realpath $infile)
		getinfo $infile
		sf=$(basename $infile | rev |cut -d'.' -f1 --complement | rev )
		yecho "解包$sf..."
		if [[ $info = "Unknow" ]] || [[ $info = "dtbo" ]] || [[ $info = "vbmeta" ]];then
			ywarn "不支持自动解包！"
		else
			imgextra
			ysuc "成功." && rm -f $infile
		fi
	done
fi

fi
if [[ $userid = "root" ]]; then
${su} chmod 777 -R *
fi
cleantemp
menu
}

# 启动检查、配置环境
function checkpath(){
clear && cd $LOCALDIR
if [ "$platform" = "aarch64" ];then
	command+=" -b /sdcard"
    su="sudo "
fi
  # Cygwin Hack
  if [ "$(uname -o)" = "Cygwin" ] && [ ! -f "$binner/depment" ]; then
	echo -e "\033[33m $(cat $binner/banners/1) \033[0m"
	packages="python3,curl,bc,cpio,aria2,p7zip,libnss3-tools,gcc-core,gcc-g++,libiconv,zlib,wget"
	# AIK for cygwin extra packages
	packages+=",file,lzop,xz,gzip,bzip2,libintl8,liblzo2_2"
	if [ ! -f "$binner/Cygwin/setup-x86_64.exe" ]; then
	  LOGE "安装程序丢失，怎么肥四捏..." && exit 1
	fi
	LOGI "安装Cygwin必要依赖... 请耐心等待程序运行结束..."
	$binner/Cygwin/setup-x86_64.exe -q -P "${packages}"
	# wait until install done
	while(ps -W | grep "setup-x86_64.exe">/dev/null);do sleep 3; done

    LOGI "安装python依赖"
    python3 -m pip install --upgrade pip -i $PIP_MIRROR
    pip3 install extract-dtb pycryptodome docopt requests beautifulsoup4 -i $PIP_MIRROR
    pip3 install --ignore-installed pyyaml -i $PIP_MIRROR

    touch "$binner/depment"
  fi
  # Hack
  if [ "$(uname -o)" = "Cygwin" ]; then
    userid="$USERNAME"
  fi

packages="python3 simg2img img2simg cpio sed libnss3-tools python3-pip brotli curl bc cpio default-jre android-sdk-libsparse-utils openjdk-11-jre aria2 p7zip-full"
if [[ ! -f "$binner/depment" ]]; then
	echo -e "\033[33m $(cat $binner/banners/1) \033[0m"
	if [[ $(whoami) = "root" ]]; then
		userid="root"
	fi
	if [[ $userid = "root" ]]; then
		clear
		ywarn "检测到系统sudo，将强制目录赋满权！"
		sleep $sleeptime
	fi
	if [ "$platform" = "aarch64" ] && [[ ! -d "/sdcard/TIK3" ]]; then
		mkdir /sdcard/TIK3
	fi
	yecho "开始配置环境..."
    sleep $sleeptime
    yecho "更换北外大源..."
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
    sudo sed -i 's/ports.ubuntu.com/mirrors.bfsu.edu.cn/g' /etc/apt/sources.list
    sudo sed -i 's/archive.ubuntu.com/mirrors.bfsu.edu.cn/g' /etc/apt/sources.list
    sudo sed -i 's/security.ubuntu.com/mirrors.bfsu.edu.cn/g' /etc/apt/sources.list
	sudo chmod 0777 /etc/apt/sources.list
    yecho "正在更新软件列表..."
    sudo apt-get update  -y && sudo apt-get upgrade -y 
    yecho "正在安装必备软件包..."
    for i in $packages; do
        yecho "安装$i..."
        sudo apt-get install $i -y
    done
    sudo apt --fix-broken install
    sudo apt update --fix-missing
	pip3 install --upgrade pip -i $PIP_MIRROR
	pip3 install extract-dtb pycryptodome docopt requests beautifulsoup4 -i $PIP_MIRROR
	pip3 install --ignore-installed pyyaml -i $PIP_MIRROR
	touch $binner/depment
fi
if [[ ! -d "TEMP" ]]; then
	mkdir TEMP
fi
cleantemp && rm -rf *.log
if [[ $userid = "root" ]]; then
	${su} chmod 777 -R *
fi
if [[ -d "/sdcard" ]];then
	Sourcedir=/sdcard/$mydir
else
	Sourcedir=$LOCALDIR
fi
promenu
}

checkpath
