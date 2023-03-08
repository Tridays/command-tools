#!/usr/bin/env bash

:<<Q
Github国内镜像网站
加速 clone
	https://gitclone.com/abc/xxx.git
加速 release
	原地址
	wget https://github.com/goharbor/harbor/releases/download/v2.0.2/harbor-offline-installer-v2.0.2.tgz
	加速下载方法一
	wget https://download.fastgit.org/goharbor/harbor/releases/download/v2.0.2/harbor-offline-installer-v2.0.2.tgz
	加速下载方法二
	wget https://hub.fastgit.org/goharbor/harbor/releases/download/v2.0.2/harbor-offline-installer-v2.0.2.tgz

加速 raw
	原地址
	wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/README.md
	加速下载方法一
	wget https://raw.staticdn.net/kubernetes/kubernetes/master/README.md
	加速下载方法二
	wget https://raw.fastgit.org/kubernetes/kubernetes/master/README.md
Q

#  Github国内镜像网站
CLONE_SPEED_UP_LINK=("https://gitclone.com/" )
RELEASE_SPEED_UP_LINK=("https://hub.fastgit.org/" )
RAW_SPEED_UP_LINK=("https://raw.fastgit.org/" )




# colors 颜色
if [ "$TERM" == "xterm-256color" ];then
	RED="\e[31;1m"      #红
	GREEN="\e[32;1m"   #绿
	YELLOW="\e[33;1m"  #黄
	BLUE="\e[34;1m"    #蓝
	PURPLE="\e[35;1m"    #紫红
	CYANINE="\e[36;1m"    #青蓝
	WHITE="\e[0m"       ##白色
else
	RED=""
	GREEN=""
	YELLOW=""
	BLUE=""
	PURPLE=""
	CYANINE=""
	WHITE=""
fi

# some function
_enter() { echo -en "\n\n${GREEN}Press Enter to continue${WHITE}";read op ;:;}

# exec command
_command(){
	# args：$1 $2 $3
	case $# in
	1)
		echo -e "\n${BLUE}[*]$white${GREEN}$1${WHITE}"
		command $1
		;;
	2 | 3)
		for x in $2
		do
			while :
			do
				echo -e "\n${BLUE}[*]$white${GREEN}$1 $x $3 ${WHITE}"
				command="$1 $x $3"
				command $command
				if [ "$?" == "0" ];then
					break
				else
					echo -e "\n${RED}Failed，please try again！${WHITE}"
					_enter
				fi
			done
		done		
		;;
	esac
	
}


# select UI
_selectUI(){
	echo -e "$(
	cat <<-EOF
		${PURPLE}\t------------Please Select System Tools------------${WHITE}
		\t\t1：${GREEN}Termux${WHITE} (Android 9+｜aarch64)
		\t\t2：${GREEN}ish${WHITE} (iPhone｜MacOS｜Apline)
		\t\t3：${GREEN}Ubuntu${WHITE} (20.04 LTS｜aarch64)
		\t\t4：${GREEN}Ubuntu${WHITE} (20.04 LTS｜amd64)
		\t\t5：${GREEN}Exit${WHITE}
		${PURPLE}\t--------------------------------------------------${WHITE}
	EOF
	)"
}

# select option
while :
do
	_selectUI
	echo -en "\n${GREEN}Please Enter Your Choice:[1-5]：${WHITE}"
	read op
	case $op in
	1)
		cat<<-EOF>"/data/data/com.termux/files/usr/etc/apt/sources.list"  ##北京外国语
		# The main termux repository, behind cloudflare cache:
		# deb https://packages-cf.termux.dev/apt/termux-main/ stable main
		# The main termux repository:
		#deb https://packages.termux.dev/apt/termux-main/ stable main
		deb https://mirrors.bfsu.edu.cn/termux/apt/termux-main stable main
		EOF
		_command "pkg update"
		_command "pkg i -y" "wget"
		rm -rf $PREFIX/bin/td
		_command "wget -c" "https://gitee.com/djyd/linux-tools/raw/master/Termux/td" "-O $PREFIX/bin/td"
		chmod 775 $PREFIX/bin/td
		echo -e "\nRun the ${RED}td${WHITE} command to start\n"
		break
		;;
	2)
		
		break
		;;
	3)
		
		break
		;;
	4)
		
		break
		;;
	5)
		_command "exit"
		#break
		;;
	*)
		echo -e "\n\n${RED}Not Found the option！${WHITE}\n\n"
		_enter
		;;
	esac
done












