#!/usr/bin/env bash

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

# some constant var
TERMUX_AARCH64_TD="https://raw.gitfast.tk/Tridays/command-tools/main/Termux/td"
ISH_TD=""
UBUNTU2004_AARCH64_TD=""
UBUNTU2004_AMD64_TD=""
# github speed up
CLONE_SPEED_UP_LINK=("https://gitclone.com/" "https://ghproxy.com/" )
RELEASE_SPEED_UP_LINK=("https://kgithub.com/" "https://ghproxy.com/")
RAW_SPEED_UP_LINK=("raw.fastgit.org" "raw.gitfast.tk") # "raw.fastgit.org" https://ghproxy.com/

#  Github国内镜像网站
_github_mirror_speed_up(){
	# args：$1 $2
	# $((RANDOM%3)) -> [0,3)
	case $1 in
	clone)
		n=${#CLONE_SPEED_UP_LINK[@]}
		r=$((RANDOM%n))
		if [ $r -eq 0 ];then
			url="${CLONE_SPEED_UP_LINK[0]}"
			url=$(echo $2 | sed "s#https://#$url#g")
		elif [ $r -eq 1 ];then
			url="${CLONE_SPEED_UP_LINK[1]}${2}"
		fi
		;;
	release)
		n=${#RELEASE_SPEED_UP_LINK[@]}
		r=$((RANDOM%n))
		if [ $r -eq 0 ];then
			url="${RELEASE_SPEED_UP_LINK[0]}${2}"
		elif [ $r -eq 1 ];then
			url="${RELEASE_SPEED_UP_LINK[1]}${2}"
		fi
		;;
	raw)
		n=${#RAW_SPEED_UP_LINK[@]}
		r=$((RANDOM%n))
		#echo $((RANDOM%1))
		if [ $r -eq 0 ];then
			url="${RAW_SPEED_UP_LINK[0]}"
			url=$(awk -F "/" "{\$3 = \"$url\" ; print \$0}" OFS="/" <<<${2})
		elif [ $r -eq 1 ];then
			url="${RAW_SPEED_UP_LINK[1]}"
			url=$(awk -F "/" "{\$3 = \"$url\" ; print \$0}" OFS="/" <<<${2})
		fi
		;;
	esac
}


# some function
_enter() { echo -en "\n\n${GREEN}Press Enter to continue${WHITE}";read op ;:;}

# exec command
_command(){
	if [ "$1" == "-clone" ];then
		status=1
		shift 1
	elif [ "$1" == "-release" ];then
		status=2
		shift 1
	elif [ "$1" == "-raw" ];then
		status=3
		shift 1
	fi
	# args：$1 $2 $3
	case $# in
	1)
		echo -e "\n${BLUE}[*]$white${GREEN}$1${WHITE}"
		command $1
		;;
	*)
		for x in $2
		do
			while :
			do
				y=$x
				if [ "$status" == "1" ];then
					_github_mirror_speed_up clone $x
					y=$url
				elif [ "$status" == "2" ];then
					_github_mirror_speed_up release $x
					y=$url				
				elif [ "$status" == "3" ];then
					_github_mirror_speed_up raw $x
					y=$url
				fi
				echo -e "\n${BLUE}[*]$white${GREEN}$1 $y $3 ${WHITE}"
				command="$1 $y $3"
				command $command
				if [ "$?" == "0" ];then
					break
				else
					echo -e "\n${RED}Erro：Failed，please try again！${WHITE}"
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
		\t\t4：${GREEN}Openwrt${WHITE} (Linux｜aarch64)
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
		yes | pkg update
		_command "pkg i -y" "wget"
		rm -rf $PREFIX/bin/td
		#_github_mirror_speed_up raw $TERMUX_AARCH64_TD
		_command "wget -c" "$TERMUX_AARCH64_TD" "-O $PREFIX/bin/td"
		
		chmod 775 $PREFIX/bin/td
		echo -e "\nRun the ${RED}td${WHITE} command to start\n"
		break
		;;
	2)
		echo -e "${YELLOW}The function is temporarily open${WHITE}"
		break
		;;
	3)
		echo -e "${YELLOW}The function is temporarily open${WHITE}"
		break
		;;
	4)
		echo -e "${YELLOW}The function is temporarily open${WHITE}"
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



# git for ssh
# install ssh
# ssh-keygen -t rsa -b 4096 
# Enter passphrase ... < password  （<  enter or not password ）
# cat $HOME/.ssh/id_rsa.pub


# [Process completed (signal 9) - press Enter]
# su -c "/system/bin/device_config set_sync_disabled_for_tests persistent; /system/bin/device_config put activity_manager max_phantom_processes 2147483647"