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
	GREY="\e[1;30m"     #灰色
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
_enter() { echo -en "\n${GREEN}Press Enter to continue${WHITE}";read op ;:;}
# 自定义通告颜色 
_msg() {
	# I：消息
	# W：警告
	# E：错误
	case $1 in
	I)
		echo -e "\n${GREEN}I：$2${WHITE}"
		;;
	W)
		echo -e "\n${YELLOW}W：$2${WHITE}"
		;;
	E)
		echo -e "\n${RED}E：$2${WHITE}"
		;;
	esac 
}

# 栈模拟，菜单多级控制
export stack=()
_node(){
		#echo "------$*------"
		stack[${#stack[@]}]="$*"
		while :
		do
			# exec
			while :
			do
			[ "$((${#stack[@]}-1))" == "-1" ] && exit
				${stack[$((${#stack[@]}-1))]}
				case $? in
				0)
					unset stack[$((${#stack[@]}-1))]
					_enter
					break
					;;
				255)
					unset stack[$((${#stack[@]}-1))]
					unset stack[$((${#stack[@]}-2))]
					_enter
					break					
					;;
				esac
			done		
		done
}

_checkInstall(){
		Path="$1"
		if [ -e "$Path" ];then
			_msg W "检测到本地已安装"
			echo -en "$red是否需要卸载[Y/N]$white" ""
			read op
			case $op in
				y|Y)
					echo -en "${RED}回车两次即可卸载！${WHITE}" ""
					_enter;_enter
					 rm -rf $Path
	    				_msg W "移除完成！"
	    				return 0
					;;
				*)
					return -1
					;;
			esac
		fi
		
}


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
	else
		status=0
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


# dialog
_dialog(){
	export PORT=1
	
	dialog --clear \
		--backtitle "$1" \
		--title "@参(•̀⌄•́)芜湖起飞" \
	 	--nocancel \
	 	--menu "$2" 20 40 8 \
		"${OPTIONS[@]}" \
	 	2>$HOME/menu
	 	
	export op=`cat $HOME/menu`
}

# 检查依赖
_checkenv(){
	num=0
	for x in $@
	do
if [ -z "$(dpkg -l | awk '{print $2}' | grep -wo $x)" ];then
			if [ "${num}" == "0" ];then
				_command "pkg update -y"
				num=1
			fi
			_command "pkg install" "${x}" "-y"
		fi
	done
}


_installAPK(){
	echo -e "\n\n\t${YELLOW}Install APK Begin！${WHITE}"
	root=$(echo ${json} | jq -r ".root")
	count=0
	echo -e "\n\t\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[0m"
	arr=($(ls | grep ".apk"))
	for x in $(seq 0 $((${#arr[@]} - 1)))
	do
		echo -e "\t${GREEN}$((${x} + 1))${WHITE}．${arr[${x}]}"
	done
	echo -en "\n请在10s内输入安装的APK[${GREY}default: 1${WHITE}]：${GREEN}" ""
	read -t 10 op
	op=$(echo ${op} | sed "s# ##g")
	[ "${op}" == "" ] && op=1
	if [[ ${op} =~ ^[-]?[0-9]+$ && ${op} -gt 0 && ${op} -le ${#arr[@]} ]];then
		apk=${arr[$((${op} - 1))]}
	else
		echo -e "\n此选项 --> ${GREEN}${op}${WHITE} 对应的软件包不存在！${WHITE}"
		exit
	fi
	# 需要root
	if [ "${root}" == "true" ];then
		su -c pm install ${apk}
		su -c monkey -p "${namespace}" -c android.intent.category.LAUNCHER 1
	else
		mkdir -p "${sharedPath}/apk-signe"
		cp -r "${workplace}" "${sharedPath}/apk-signe"
		echo -e "\n${GREEN}[Note]${WHITE}：APK已复制一份至 /storage/emulated/0/Download/apktool/apk-signe/${namespace}"
		am start -a android.intent.action.VIEW -t application/vnd.android.package-archive -d "file:///storage/emulated/0/Download/apktool/apk-signe/${namespace}/${apk}"
	fi
}


# 给apk签名
_signe(){
	_createkey(){
		if [ ! -e "${workplace}/${keyName}" ];then
			keytool -genkeypair -v -keystore ${keyName} -alias release -keyalg RSA -keysize 2048 -validity 10000 -storetype PKCS12 -sigalg SHA256withRSA  -storepass ${password} -keypass ${password} -dname "CN=${Name}, OU=${OrganizationalUnit}, O=${Organization}, L=${City}, S=${State}, C=${CountryCode}"
			# keytool -genkey -v -keystore ${keyName} -alias release -keyalg RSA -keysize 2048 -validity 10000 -storepass ${password} -keypass ${password} -dname "CN=${Name}, OU=${OrganizationalUnit}, O=${Organization}, L=${City}, S=${State}, C=${CountryCode}"
			echo -e "\nkeytool -genkeypair -v -keystore ${keyName} -alias release -keyalg RSA -keysize 2048 -validity 10000 -storetype PKCS12 -sigalg SHA256withRSA  -storepass ${password} -keypass ${password} -dname "CN=${Name}, OU=${OrganizationalUnit}, O=${Organization}, L=${City}, S=${State}, C=${CountryCode}""
		fi
	}
	
	_V1(){
		echo -e "\n[${YELLOW}Note${WHITE}]：对${apkname}进行V1签名"
		echo -e "\n${GREEN}[cmd]${WHITE}：${GREEN}jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ${keyName} -storepass ${password} -keypass ${password} ${apkname} alias_name${WHITE}"
		jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ${keyName} -storepass ${password} -keypass ${password} ${apkname} release
	}
	_V2(){
		echo -e "\n[${YELLOW}Note${WHITE}]：对${apkname}进行V2签名"
		echo -e "\n${GREEN}[cmd]${WHITE}：${GREEN}apksigner sign --v1-signing-enabled false --v2-signing-enabled true --v3-signing-enabled false --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --ks-key-alias release ${apkname}${WHITE}"	
		apksigner sign --v1-signing-enabled false --v2-signing-enabled true --v3-signing-enabled false --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --ks-key-alias release ${apkname}
	}
	_V3(){
		echo -e "\n[${YELLOW}Note${WHITE}]：对${apkname}进行V3签名"
		echo -e "\n${GREEN}[cmd]${WHITE}：${GREEN}apksigner sign --v1-signing-enabled false --v2-signing-enabled true --v3-signing-enabled false --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --ks-key-alias release ${apkname}${WHITE}"	
		apksigner sign --v1-signing-enabled false --v2-signing-enabled true --v3-signing-enabled false --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --ks-key-alias release ${apkname}
	}
	_V1_V2(){
		echo -e "\n[${YELLOW}Note${WHITE}]：对${apkname}进行V1 + V2签名"
		echo -e "\n${GREEN}[cmd]${WHITE}：${GREEN}apksigner sign --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled false --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --ks-key-alias release ${apkname}${WHITE}"	
		apksigner sign --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled false --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --ks-key-alias release ${apkname}
	}
	_V1_V3(){
		echo -e "\n[${YELLOW}Note${WHITE}]：对${apkname}进行V1 + V3签名"
		echo -e "\n${GREEN}[cmd]${WHITE}：${GREEN}apksigner sign --v1-signing-enabled true --v2-signing-enabled false --v3-signing-enabled true --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --ks-key-alias release ${apkname}${WHITE}"	
		apksigner sign --v1-signing-enabled true --v2-signing-enabled false --v3-signing-enabled true --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --ks-key-alias release ${apkname}
	}
	_V2_V3(){
		echo -e "\n[${YELLOW}Note${WHITE}]：对${apkname}进行V2 + V3签名"
		echo -e "\n${GREEN}[cmd]${WHITE}：${GREEN}apksigner sign --v1-signing-enabled false --v2-signing-enabled true --v3-signing-enabled true --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --ks-key-alias release ${apkname}${WHITE}"	
		apksigner sign --v1-signing-enabled false --v2-signing-enabled true --v3-signing-enabled true --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --ks-key-alias release ${apkname}
	}
	_V1_V2_V3(){
		echo -e "\n[${YELLOW}Note${WHITE}]：对${apkname}进行V1 + V2 + V3签名"
		echo -e "\n${GREEN}[cmd]${WHITE}：${GREEN}apksigner sign --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --ks-key-alias release ${apkname}${WHITE}"	
		apksigner sign --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --ks-key-alias release ${apkname}
	}
	
	if [ "$#" == "0" ];then
		_userSelect
	fi
	data=$(echo ${json} | jq -r ".androidProject[${projectNum}]")
	
	# 配置信息
	signeType=$(echo ${data} | jq -r ".signeType")
	jdk=$(echo ${data} | jq -r ".jdk")
	# 项目信息
	projectName=$(echo ${data} | jq -r ".projectName")
	projectPath=$(eval echo "$(echo ${data} | jq -r ".projectPath")")   # Android项目路径
	namespace=$(echo ${data} | jq -r ".namespace")   # Android项目的包名
	# 密匙信息内容
	keyName=$(echo ${data} | jq -r ".keyName")   # 证书文件名
	password=$(echo ${data} | jq -r ".password")    # 证书密码
	Name=$(echo ${data} | jq -r ".Name")     # 姓名
	OrganizationalUnit=$(echo ${data} | jq -r ".OrganizationalUnit")    # 组织
	Organizational=$(echo ${data} | jq -r ".Organizational")      # 组织
	City=$(echo ${data} | jq -r ".City")     # 所在城市
	State=$(echo ${data} | jq -r ".State")    # 
	CountryCode=$(echo ${data} | jq -r ".CountryCode")   # 所在国家代码
	
	echo -e "\n\t${YELLOW}Signe APK Begin！${WHITE}"
	echo -e "\n${GREEN}[projectName]${WHITE}：${projectName}"
	if [ ! -d "${projectPath}" ];then
		echo -e "${RED}[E]${WHITE}：项目路径不存在 OR 配置不正确？\n${RED}Exit ！"
		exit
	fi
	workplace="${wordPathRoot}/apk-signe/${namespace}"
	mkdir -p ${workplace}
	cd ${workplace}
	rm -rf *.apk
	rm -rf *.apk.idsig
	for x in $(find ${projectPath} -type f -name *.apk)
	do
		cp ${x} ${workplace}
	done
	# 创建证书
	_createkey ${workplace}
	
	v=$(echo ${signeType} | sed "s# ##g;s#+#_#g" | tr '[:lower:]' '[:upper:]')

	for x in $(ls | grep ".apk")
	do
		apkname=${x}
		rm -rf *.apk.idsig
		case "${v}" in
			"V1")
				_V1
				;;
			"V2")
				_V2
				;;
			"V3")
				_V3
				;;
			"V1_V2" | "V2_V1")
				_V1_V2
				;;
			"V1_V3" | "V3_V1")
				_V1_V3
				;;
			"V2_V3" | "V3_V2")
				_V2_V3
				;;
			"V1_V2_V3" | "V2_V1_V3" | "V2_V3_V1" | "V1_V3_V2" | "V3_V1_V2" | "V3_V2_V1")
				_V1_V2_V3
				;;
			*)
				echo -e "${RED}[E]${WHITE}：配置文件签名书写不正确！\n -->> signeType=${signeType}\n${RED}Exit ！"
				exit
				;;
			esac
	done
	rm -rf *.apk.idsig
	# 安装软件
	_installAPK ${workplace} ${namespace}
}

# 更换aapt2
_changeAAPT2(){
	if [ "$#" == "0" ];then
		_userSelect
	fi
	data=$(echo ${json} | jq -r ".androidProject[${projectNum}]")
	path=${wordPathRoot}/AAPT2
	AAPT2Bin=$(eval echo "$(echo ${data} | jq -r ".AAPT2")")
	projectName=$(echo ${data} | jq -r ".projectName")
	echo -e "\n\t${YELLOW}AAPT2 Replace Begin！${WHITE}"
	echo -e "\n${GREEN}[projectName]${WHITE}：${projectName}"
	mkdir -p ${path}
	cd ${path}
	rm -rf ${path}/*
	echo -e "\n${BLUE}[Current AAPT2 info]${WHITE}："
	${AAPT2Bin} version
	echo ""
	
	# 替换jar
	for x in $(find $HOME/.gradle -type f -name "aapt2*linux.jar")
	do
		jarName="$(echo ${x} | awk -F "/" '{print $NF}')"
		echo -e "\n${BLUE}[Find]${WHITE}：${x}\n${GREEN}[jar name]${WHITE}：${jarName}\n${RED}[Note]${WHITE}：Auto Replace Jar......\n"
		cp ${x} ./
		jar -xf ${jarName}
		ls
		cp ${AAPT2Bin} ${path}
		jar -cf ${jarName} *
		ls
		cp ${jarName} ${x}
		rm -rf ${path}/*
	done

	# 替换AAPT2
	for x in $(find $HOME/.gradle -type f -name "aapt2")
	do	
		binName="$(echo ${x} | awk -F "/" '{print $NF}')"
		cp ${AAPT2Bin} ${x}
		echo -e "\n${BLUE}[Find]${WHITE}：${x}\n${GREEN}[bin name]${WHITE}：${binName}\n${RED}[Note]${WHITE}：Auto Replace Jar......\n"
	done
}

# 自动构建安装
_auto(){
	_userSelect
	data=$(echo ${json} | jq -r ".androidProject[${projectNum}]")
	# export ANDROID_SDK_ROOT=${HOME}/sdk
	
	# 配置信息
	jdk=$(echo ${data} | jq -r ".jdk" | sed "# ##")
	# 项目信息
	projectName=$(echo ${data} | jq -r ".projectName")
	projectPath=$(eval echo "$(echo ${data} | jq -r ".projectPath")")   # Android项目路径
	#cmd=$(eval echo "$(echo ${data} | jq -r ".cmd")")   # 构建命令
	cmd="$(echo ${data} | jq -r ".cmd")"   # 构建命令

	
	echo -e "\n\t${YELLOW}Auto Build Begin！${WHITE}"
	echo -e "\n${GREEN}[projectName]${WHITE}：${projectName}"
	if [ ! -d "${projectPath}" ];then
		echo -e "${RED}[E]${WHITE}：项目路径不存在 OR 配置不正确？\n${RED}Exit ！"
		exit
	fi
	cd ${projectPath}
	chmod +x gradlew
	rm -rf .gradle app/build
	
	_autoBuild(){
		echo -e "\n${GREEN}[pwd]${WHITE}：$(pwd)"
		case ${jdk} in
			8)
				echo -e "\n${RED}[E]：${WHITE} 使用JDK8构建似乎存在bug，目前请优先使用 jdk11 OR jdk17！${RED}EXIT！"
				exit
				export JAVA_HOME="${HOME}/jdk/jdk8"
				if [ ! -d "${JAVA_HOME}" ];then
					echo -e "\n${RED}[E]：${WHITE} JDK8不存在请先安装！${RED}EXIT！"
					exit
				fi
				echo -e "\n${GREEN}[Note]${WHITE}：JAVA_HOME=${JAVA_HOME}"
				echo -e "\n${GREEN}[cmd]${WHITE}：${GREEN}${cmd}${WHITE}"
				eval ${cmd}
				return $?
				;;
			11)
				export JAVA_HOME="${HOME}/jdk/jdk11"
				if [ ! -d "${JAVA_HOME}" ];then
					echo -e "\n${RED}[E]：${WHITE} JDK11不存在请先安装！${RED}EXIT！"
					exit
				fi
				echo -e "\n${GREEN}[Note]${WHITE}：JAVA_HOME=${JAVA_HOME}"
				echo -e "\n${GREEN}[cmd]${WHITE}：${GREEN}${cmd}${WHITE}"
				eval ${cmd}
				return $?
				;;
			17)
				export JAVA_HOME="${PREFIX}/opt/openjdk"
				if [ ! -d "${JAVA_HOME}" ];then
					echo -e "\n${RED}[E]：${WHITE} JDK17不存在请先安装！${RED}EXIT！"
					exit
				fi
				echo -e "\n${GREEN}[Note]${WHITE}：JAVA_HOME=${JAVA_HOME}"
				echo -e "\n${GREEN}[cmd]${WHITE}：${GREEN}${cmd}${WHITE}"
				eval ${cmd}
				
				return $?
				;;
			*)
				echo -e "\njdk版本仅限： --> ${GREEN}8 OR 11 OR 17${WHITE}\n${RED}请改正配置文件的jdk版本 EXIT！${WHITE}"
				exit
				;;
		esac
	}
	for x in $(seq 2)
	do
		case ${x} in
			1)
				echo -e "\n\t${YELLOW}The First Automatic Build！${WHITE}"
				;;
			2)
				echo -e "\n\t${YELLOW}The Second Automatic Build！${WHITE}"	
				_changeAAPT2 ${projectNum}
				cd ${projectPath}
				;;
		esac
		_autoBuild
		s=$?
		if [[ ${s} -eq 0 && ${x} -eq 1 ]];then
			break
		fi
		if [[ ! ${s} -eq 0 && ${x} -eq 2 ]];then
			echo -e "\n${RED}[Note]${WHITE}：自动构建失败，请检查日志！${RED}EXIT ！"
			exit
		fi
	done
	_signe ${projectNum}
}






_install(){
	_sdkmanager(){
		url=$(echo ${json} | jq -r ".sdk.downloadUrl")
		using_jdk=$(echo ${json} | jq -r ".sdk.using_jdk")
		sdk_root=$(eval echo "$(echo ${json} | jq -r ".sdk.sdk_root")")
		name=$(echo $url | awk -F "/" '{print $NF}' | sed "s#.zip##g")
		_checkInstall ${sdk_root}/cmdline-tools
		[ ! "$?" == "0" ] && exit
		mkdir -p ${sdk_root}
		cd ${sdk_root}
		_command "wget -c" "${url}"
		unzip -o ${name}.zip
		rm -rf ${name}.zip
		echo -e "\n${BLUE}[Current SDK info]${WHITE}："
		case $using_jdk in
			#8)
			#	export JAVA_HOME="${HOME}/jdk/jdk8"
			#	if [ ! -d "${JAVA_HOME}" ];then
			#		echo -e "\n${RED}[E]：${WHITE} JDK8不存在请先安装！${RED}EXIT！"
			#		exit
			#	fi
			#	${sdk_root}/cmdline-tools/bin/sdkmanager --sdk_root=${sdk_root} --list
			#	;;
			11)
				export JAVA_HOME="${HOME}/jdk/jdk11"
				if [ ! -d "${JAVA_HOME}" ];then
					echo -e "\n${RED}[E]：${WHITE} JDK8不存在请先安装！${RED}EXIT！"
					exit
				fi
				;;
			17)
				export JAVA_HOME="${PREFIX}/opt/openjdk"
				if [ ! -d "${JAVA_HOME}" ];then
					echo -e "\n${RED}[E]：${WHITE} JDK8不存在请先安装！${RED}EXIT！"
					exit
				fi
				;;
			*)
				echo -e "\njdk版本仅限： --> ${GREEN}11 OR 17${WHITE}\n${RED}请改正配置文件的jdk版本 EXIT！${WHITE}"
				exit
				;;
		esac
		${sdk_root}/cmdline-tools/bin/sdkmanager --sdk_root=${sdk_root} --list
	}
	_jdk8(){
		path=${HOME}/jdk
		mkdir -p ${path}
		cd ${path}
		_checkInstall ${path}/jdk8
		[ ! "$?" == "0" ] && exit
		echo -e "\n\t${YELLOW}Download JDK8！${WHITE}"
		echo -e "\n${GREEN}[Note]${WHITE}：jdk8 will be installed in ${HOME}/jdk"
		url=$(echo ${json} | jq -r ".jdk.jdk8_downloadUrl")
		name=$(echo $url | awk -F "/" '{print $NF}' | sed "s#.zip##g")
		_command "wget -c" "${url}"
		unzip -o ${name}.zip
		mv ${name} jdk8
		rm -rf ${name}.zip
		cd jdk8
		cp -rf dex ${PREFIX}/share
		cp -rf java ${PREFIX}/share
		chmod +x bin/*
		echo -e "\n${BLUE}[Current JDK8 info]${WHITE}："
		${path}/jdk8/bin/java -version
	}
	_jdk11(){
		path=${HOME}/jdk
		mkdir -p ${path}
		cd ${path}
		_checkInstall ${path}/jdk11
		[ ! "$?" == "0" ] && exit
		echo -e "\n\t${YELLOW}Download JDK11！${WHITE}"
		echo -e "\n${GREEN}[Note]${WHITE}：jdk11 will be installed in ${HOME}/jdk"
		url=$(echo ${json} | jq -r ".jdk.jdk11_downloadUrl")
		name=$(echo $url | awk -F "/" '{print $NF}' | sed "s#.zip##g")
		_command "wget -c" "${url}"
		unzip -o ${name}.zip
		mv ${name} jdk11
		rm -rf ${name}.zip
		chmod +x jdk11/bin/*
		echo -e "\n${BLUE}[Current JDK11 info]${WHITE}："
		${path}/jdk11/bin/java -version
	}
	_buildTools(){
		using_jdk=$(echo ${json} | jq -r ".sdk.using_jdk")
		sdk_root=$(eval echo "$(echo ${json} | jq -r ".sdk.sdk_root")")
		case $using_jdk in
			#8)
			#	export JAVA_HOME="${HOME}/jdk/jdk8"  
			#	if [ ! -d "${JAVA_HOME}" ];then
			#		echo -e "\n${RED}[E]：${WHITE} JDK8不存在请先安装！${RED}EXIT！"
			#		exit
			#	fi
			#	;;
			11)
				export JAVA_HOME="${HOME}/jdk/jdk11"
				if [ ! -d "${JAVA_HOME}" ];then
					echo -e "\n${RED}[E]：${WHITE} JDK11不存在请先安装！${RED}EXIT！"
					exit
				fi
				;;
			17)
				export JAVA_HOME="${PREFIX}/opt/openjdk"
				if [ ! -d "${JAVA_HOME}" ];then
					echo -e "\n${RED}[E]：${WHITE} JDK17不存在请先安装！${RED}EXIT！"
					exit
				fi
				;;
			*)
				echo -e "\njdk版本仅限： --> ${GREEN}11 OR 17${WHITE}\n${RED}请改正配置文件的jdk版本 EXIT！${WHITE}"
				exit
				;;
		esac
		${sdk_root}/cmdline-tools/bin/sdkmanager --sdk_root=${sdk_root} --list > .tmp 
		if [ ! $? == 0 ];then
			echo -e "\n${RED}[Note]${WHITE}：网络错误 OR 请先安装sdkmanager！${RED}EXIT！"
			exit
		fi
		row=$(cat .tmp | grep -n "Available Packages:"  | awk -F ":" '{print $1}' )
		row2=$(cat .tmp | grep -n "Available Updates:"  | awk -F ":" '{print $1}' )
		if [ "$row2" == "" ];then
			buildToolsArr=($(awk "NR>=${row}{print}" .tmp | grep "build-tools;" | awk '{print $1}'))	
		else
			buildToolsArr=($(awk "NR==${row},NR==${row2}" .tmp | grep "build-tools;" | awk '{print $1}'))	
		fi
		num=${#buildToolsArr[@]}
		for x in $(seq 0 $((${num} - 1)))
		do
			name=${buildToolsArr[$x]}
			version=$(echo ${name} | awk -F ";" '{print $2}')
			path="${sdk_root}/build-tools/${version}"
			if [ -e "${path}" ];then
				echo -e "${GREEN}$((${x} + 1))${WHITE}．${name}\t[${GREEN}installed ${YELLOW}✔${WHITE}]"
			else
				echo -e "${GREEN}$((${x} + 1))${WHITE}．${name}"
			fi
		done
	echo -en "请输入序号：${GREEN}" ""
	read op
	op=$(echo ${op} | sed "s# ##g")
	if [[ ${op} =~ ^[-]?[0-9]+$ && ${op} -gt 0 && ${op} -le ${num} ]];then
		name=${buildToolsArr[$((${op} - 1))]}
		echo -e "${GREEN}[Note]${WHITE}：选中 ${name}"
		version=$(echo ${name} | awk -F ";" '{print $2}')
		path="${sdk_root}/build-tools/${version}"
		_checkInstall ${path}
		[ ! "$?" == "0" ] && exit
		yes | ${sdk_root}/cmdline-tools/bin/sdkmanager --sdk_root=${sdk_root} --install "${name}"
		if [ ! -d "${path}" ];then
			version=$(echo ${version} | sed 's#\.0\.0##g')
			_command "wget -c" "http://dl-ssl.google.com/android/repository/build-tools_r${version}-linux.zip"
			unzip -o "build-tools_r${version}-linux.zip" -d "build-tools_r${version}-linux"
			if [ "$?" == "0" ];then
				mkdir -p ${path}
				num=$(ls build-tools_r${version}-linux/* | wc -l)
				if [ ${num} -eq 1 ];then
					mv build-tools_r${version}-linux/*/* ${path}
				else
					mv build-tools_r${version}-linux/*/* ${path}
				fi
			fi
			rm -rf build-tools_r${version}-linux*
		fi
		echo -e "\n\n${YELLOW}[Note]${WHITE}：如需卸载请使用：${sdk_root}/cmdline-tools/bin/sdkmanager --sdk_root=${sdk_root} --uninstall \"${name}\""
	else
		echo -e "\n此选项 --> ${GREEN}${op}${WHITE} 对应的build-tools版本不存在！${WHITE}"
		exit
	fi
	
	}
	_sdk(){
		using_jdk=$(echo ${json} | jq -r ".sdk.using_jdk")
		sdk_root=$(eval echo "$(echo ${json} | jq -r ".sdk.sdk_root")")
		case $using_jdk in
			#8)
			#	export JAVA_HOME="${HOME}/jdk/jdk8"  
			#	if [ ! -d "${JAVA_HOME}" ];then
			#		echo -e "\n${RED}[E]：${WHITE} JDK8不存在请先安装！${RED}EXIT！"
			#		exit
			#	fi
			#	;;
			11)
				export JAVA_HOME="${HOME}/jdk/jdk11"
				if [ ! -d "${JAVA_HOME}" ];then
					echo -e "\n${RED}[E]：${WHITE} JDK11不存在请先安装！${RED}EXIT！"
					exit
				fi
				;;
			17)
				export JAVA_HOME="${PREFIX}/opt/openjdk"
				if [ ! -d "${JAVA_HOME}" ];then
					echo -e "\n${RED}[E]：${WHITE} JDK17不存在请先安装！${RED}EXIT！"
					exit
				fi
				;;
			*)
				echo -e "\njdk版本仅限： --> ${GREEN}11 OR 17${WHITE}\n${RED}请改正配置文件的jdk版本 EXIT！${WHITE}"
				exit
				;;
		esac
		${sdk_root}/cmdline-tools/bin/sdkmanager --sdk_root=${sdk_root} --list > .tmp 
		if [ ! $? == 0 ];then
			echo -e "\n${RED}[Note]${WHITE}：网络错误 OR 请先安装sdkmanager！${RED}EXIT！"
			exit
		fi
		row=$(cat .tmp | grep -n "Available Packages:"  | awk -F ":" '{print $1}' )
		row2=$(cat .tmp | grep -n "Available Updates:"  | awk -F ":" '{print $1}' )
		if [ "$row2" == "" ];then
			buildToolsArr=($(awk "NR>=${row}{print}" .tmp | grep "platforms;" | awk '{print $1}'))	
		else
			buildToolsArr=($(awk "NR==${row},NR==${row2}" .tmp | grep "platforms;" | awk '{print $1}'))	
		fi
		num=${#buildToolsArr[@]}
		for x in $(seq 0 $((${num} - 1)))
		do
			name=${buildToolsArr[$x]}
			version=$(echo ${name} | awk -F ";" '{print $2}')
			path="${sdk_root}/platforms/${version}"
			if [ -e "${path}" ];then
				echo -e "${GREEN}$((${x} + 1))${WHITE}．${name}\t[${GREEN}installed ${YELLOW}✔${WHITE}]"
			else
				echo -e "${GREEN}$((${x} + 1))${WHITE}．${name}"
			fi
		done
	echo -en "请输入序号：${GREEN}" ""
	read op
	op=$(echo ${op} | sed "s# ##g")
	if [[ ${op} =~ ^[-]?[0-9]+$ && ${op} -gt 0 && ${op} -le ${num} ]];then
		name=${buildToolsArr[$((${op} - 1))]}
		echo -e "${GREEN}[Note]${WHITE}：选中 ${name}"
		version=$(echo ${name} | awk -F ";" '{print $2}')
		path="${sdk_root}/platforms/${version}"
		_checkInstall ${path}
		[ ! "$?" == "0" ] && exit
		yes | ${sdk_root}/cmdline-tools/bin/sdkmanager --sdk_root=${sdk_root} --install "${name}"
		#if [ ! -d "${path}" ];then
		#	version=$(echo ${version} | sed 's#\.0\.0##g')
		#	
		#	_command "wget -c" "http://dl-ssl.google.com/android/repository/platform-31_r01*.zip"
		#	unzip -o "build-tools_r${version}-linux.zip" -d "build-tools_r${version}-linux"
		#	if [ "$?" == "0" ];then
		#		mkdir -p ${path}
		#		num=$(ls build-tools_r${version}-linux/* | wc -l)
		#		if [ ${num} -eq 1 ];then
		#			mv build-tools_r${version}-linux/*/* ${path}
		#		else
		#			mv build-tools_r${version}-linux/*/* ${path}
		#		fi
		#	fi
		#	rm -rf build-tools_r${version}-linux*
		#fi
		
		echo -e "\n\n${YELLOW}[Note]${WHITE}：如需卸载请使用：${sdk_root}/cmdline-tools/bin/sdkmanager --sdk_root=${sdk_root} --uninstall \"${name}\""
	else
		echo -e "\n此选项 --> ${GREEN}${op}${WHITE} 对应的 platforms;android-* 版本不存在！${WHITE}"
		exit
	fi
	
	}
	_sources(){
		using_jdk=$(echo ${json} | jq -r ".sdk.using_jdk")
		sdk_root=$(eval echo "$(echo ${json} | jq -r ".sdk.sdk_root")")
		case $using_jdk in
			#8)
			#	export JAVA_HOME="${HOME}/jdk/jdk8"  
			#	if [ ! -d "${JAVA_HOME}" ];then
			#		echo -e "\n${RED}[E]：${WHITE} JDK8不存在请先安装！${RED}EXIT！"
			#		exit
			#	fi
			#	;;
			11)
				export JAVA_HOME="${HOME}/jdk/jdk11"
				if [ ! -d "${JAVA_HOME}" ];then
					echo -e "\n${RED}[E]：${WHITE} JDK11不存在请先安装！${RED}EXIT！"
					exit
				fi
				;;
			17)
				export JAVA_HOME="${PREFIX}/opt/openjdk"
				if [ ! -d "${JAVA_HOME}" ];then
					echo -e "\n${RED}[E]：${WHITE} JDK17不存在请先安装！${RED}EXIT！"
					exit
				fi
				;;
			*)
				echo -e "\njdk版本仅限： --> ${GREEN}11 OR 17${WHITE}\n${RED}请改正配置文件的jdk版本 EXIT！${WHITE}"
				exit
				;;
		esac
		${sdk_root}/cmdline-tools/bin/sdkmanager --sdk_root=${sdk_root} --list > .tmp 
		if [ ! $? == 0 ];then
			echo -e "\n${RED}[Note]${WHITE}：网络错误 OR 请先安装sdkmanager！${RED}EXIT！"
			exit
		fi
		row=$(cat .tmp | grep -n "Available Packages:"  | awk -F ":" '{print $1}' )
		row2=$(cat .tmp | grep -n "Available Updates:"  | awk -F ":" '{print $1}' )
		if [ "$row2" == "" ];then
			buildToolsArr=($(awk "NR>=${row}{print}" .tmp | grep "sources;" | awk '{print $1}'))	
		else
			buildToolsArr=($(awk "NR==${row},NR==${row2}" .tmp | grep "sources;" | awk '{print $1}'))	
		fi
		num=${#buildToolsArr[@]}
		for x in $(seq 0 $((${num} - 1)))
		do
			name=${buildToolsArr[$x]}
			version=$(echo ${name} | awk -F ";" '{print $2}')
			path="${sdk_root}/sources/${version}"
			if [ -e "${path}" ];then
				echo -e "${GREEN}$((${x} + 1))${WHITE}．${name}\t[${GREEN}installed ${YELLOW}✔${WHITE}]"
			else
				echo -e "${GREEN}$((${x} + 1))${WHITE}．${name}"
			fi
		done
	echo -en "请输入序号：${GREEN}" ""
	read op
	op=$(echo ${op} | sed "s# ##g")
	if [[ ${op} =~ ^[-]?[0-9]+$ && ${op} -gt 0 && ${op} -le ${num} ]];then
		name=${buildToolsArr[$((${op} - 1))]}
		echo -e "${GREEN}[Note]${WHITE}：选中 ${name}"
		version=$(echo ${name} | awk -F ";" '{print $2}')
		path="${sdk_root}/sources/${version}"
		_checkInstall ${path}
		[ ! "$?" == "0" ] && exit
		yes | ${sdk_root}/cmdline-tools/bin/sdkmanager --sdk_root=${sdk_root} --install "${name}"
		#if [ ! -d "${path}" ];then
		#	version=$(echo ${version} | sed 's#\.0\.0##g')
		#	_command "wget -c" "http://dl-ssl.google.com/android/repository/build-tools_r${version}-linux.zip"
		#	unzip -o "build-tools_r${version}-linux.zip" -d "build-tools_r${version}-linux"
		#	if [ "$?" == "0" ];then
		#		mkdir -p ${path}
		#		num=$(ls build-tools_r${version}-linux/* | wc -l)
		#		if [ ${num} -eq 1 ];then
		#			mv build-tools_r${version}-linux/*/* ${path}
		#		else
		#			mv build-tools_r${version}-linux/*/* ${path}
		#		fi
		#	fi
		#	rm -rf build-tools_r${version}-linux*
		#fi
		echo -e "\n\n${YELLOW}[Note]${WHITE}：如需卸载请使用：${sdk_root}/cmdline-tools/bin/sdkmanager --sdk_root=${sdk_root} --uninstall \"${name}\""
	else
		echo -e "\n此选项 --> ${GREEN}${op}${WHITE} 对应的build-tools版本不存在！${WHITE}"
		exit
	fi
	
	}
	case "$@" in
		"sdkmanager")
			_sdkmanager
			;;
		"sdk")
			_sdk
			;;
		"build-tools")
			_buildTools
			;;
		"sources")
			_sources
			;;			
		"jdk8")
			_jdk8
			;;		
		"jdk11")
			_jdk11
			;;		
		*)
			echo -e "\n${RED}[E]${WHITE}：$@ 参数错误！${RED}EXIT！${WHITE}"
		;;
	esac
}

_clear(){
	# 全局缓存
	echo -e "\n${YELLOW}[Global]${WHITE}：${HOME}/.gradle"
	echo -en "\n是否清除全局缓存${GREY}[default: N]${WHITE}[${YELLOW}Y/N${WHITE}]：${GREEN}" ""
	read op
	op=$(echo ${op} | sed "s# ##g")
	if [[ "${op}" == "y" || "${op}" == "Y" ]];then
		rm -rf ${HOME}/.gradle
	fi
	
	# 项目缓存
	echo -e "\n${YELLOW}[Project]${WHITE}：project/.gradle"
	echo -en "\n是否清除项目缓存${GREY}[default: N]${WHITE}[${YELLOW}Y/N${WHITE}]：${GREEN}" ""
	read op
	op=$(echo ${op} | sed "s# ##g")
	if [[ "${op}" == "y" || "${op}" == "Y" ]];then
		num=$(echo ${json} | jq -r ".androidProject | length")
		if [ "${num}" == "0" ];then
			echo -e "\n${YELLOW}[W]：${WHITE}当前配置文件，没有任何项目，不需要清除缓存！${jsonPath} ${RED}EXIT ！${WHITE}"
			exit
		fi
		for x in $(seq 0 $((${num} - 1)))
		do
			projectName=$(echo ${json} | jq -r ".androidProject[${x}].projectName")
			projectPath=$(eval echo "$(echo ${json} | jq -r ".androidProject[${x}].projectPath")")
			echo -e "\n${YELLOW}[projectName]${WHITE}：${projectName}"
			rm -rf ${projectPath}/{.gradle,app/build}
			tree -L 2 ${projectPath}
		done
	fi
	
	# 清除配置文件无效项目
	echo -e "\n${YELLOW}[Config]${WHITE}：${HOME}/apkToolConfig.json"
	echo -en "\n是否清除配置文件无效项目${GREY}[default: Y]${WHITE}[${YELLOW}Y/N${WHITE}]：${GREEN}" 
	read op
	[[ "${op}" == "n" || "${op}" == "N" ]] && exit
	num=$(echo ${json} | jq -r ".androidProject | length")
	flags=0
	for x in $(seq 0 $((${num} - 1)))
	do
		projectPath=$(eval echo "$(echo ${json} | jq -r .androidProject[${x}].projectPath)")
		if [ ! -e "${projectPath}" ];then
			echo -e "\n${YELLOW}[Note]${WHITE}：${GREEN}del${WHITE} ${projectPath}"
			arr[${x}]=${x}
			flags=1
		fi
	done
	if [ "${flags}" == "1" ];then
		index=$(echo ${arr[@]} | sed "s# #,#g")
		json=$(echo ${json} | jq -r "del(.androidProject[${index}])")
		echo ${json} | jq -r > ${jsonPath}
	fi
}


_create(){
	sdk_version=(
		'API 16:Android 4.1 (Jelly Bean)'
		'API 17:Android 4.2 (Jelly Bean)'
		'API 18:Android 4.3 (Jelly Bean)'
		'API 19:Android 4.4 (KitKat)'
		'API 20:Android 4.4W (KitKat Wear)'
		'API 21:Android 5.0 (Lollipop)'
		'API 22:Android 5.1 (Lollipop)'
		'API 23:Android 6.0 (Marshmallow)'
		'API 24:Android 7.0 (Nougat)'
		'API 25:Android 7.1.1 (Nougat)'
		'API 26:Android 8.0 (Oreo)'
		'API 27:Android 8.1 (Oreo)'
		'API 28:Android 9.0 (Pie)'
		'API 29:Android 10.0 (Q)'
		'API 30:Android 11.0 (R)'
		'API 31:Android 12.0 (S)'
		'API 32:Android 12L (Sv2)'
		'API 33:Android 13.0 (Tiramisu)'
	)
	_up_json(){
		json_data="{}"
		json_data=$(echo ${json_data} | jq -r ". + {\"projectName\": \"${projectName}\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"projectPath\": \"${projectpath}\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"namespace\": \"${namespace}\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"signeType\": \"V1 + V2 +V3\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"AAPT2\": \"\${PREFIX}/bin/aapt2\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"jdk\": \"17\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"cmd\": \"./gradlew build\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"keyName\": \"release-key.keystore\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"password\": \"123456\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"Name\": \"xiaoming\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"OrganizationalUnit\": \"test\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"Organizational\": \"test\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"City\": \"test\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"State\": \"test\"} ")
		json_data=$(echo ${json_data} | jq -r ". + {\"CountryCode\": \"86\"} ")
	}
	_createProject(){
		# 应用名称
		echo -en "\n[${GREEN}Note${WHITE}]：空值回车为默认值(Default)"
		echo -en "\n应用名称[default: ${YELLOW}MyApplication${WHITE}]：${GREEN}" ""
		read op
		op=$(echo ${op} | sed "s# ##g")
		# 项目名字
		export projectName=${op}
		if [ -z "${op}" ];then
			export projectName="MyApplication"
		fi
		
		# 包名
		namespace=com.example.${projectName}
		echo -en "${WHITE}\n应用包名[default: ${YELLOW}${namespace}${WHITE}]：${GREEN}" ""
		read op
		op=$(echo ${op} | sed "s# ##g")
		export namespace=${op}
		if [ -z "${op}" ];then
			export namespace="com.example.${projectName}"
		fi

		# 项目位置
		echo -en "${WHITE}\n保存路径[default: ${YELLOW}${HOME}/${projectName}${WHITE}]：${GREEN}" ""
		read op
		op=$(echo ${op} | sed "s# ##g")
		if [ -e "${HOME}/${projectName}" ];then
			echo -e "\n${RED}[E]：${WHITE}此保存路径，已存在，请更换！ ${RED}EXIT ！${WHITE}"
			exit
		fi
		export projectpath=${op}
		if [ -z "${op}" ];then
			export projectpath="${HOME}/${projectName}"
		fi
		
		# 项目语言
		Language=($(echo ${Language} | sed "s#/# #g"))
		count=0
		echo -e "\n\t\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[0m"
		for x in $(seq 0 $((${#Language[@]} - 1)))
		do
			echo -e "\t${GREEN}$((${x} + 1))${WHITE}．${Language[${x}]}"
			let count++
		done
		echo -en "${WHITE}\n项目语言[default: ${YELLOW}${Language[0]}${WHITE}]：${GREEN}" ""
		read op
		op=$(echo ${op} | sed "s# ##g")
		expr ${op} + 10 >>/dev/null 2>&1
		if [ ! $? == 0 ];then
			echo -e "\n${RED}[E]：${WHITE}不存在此选项！ ${RED}EXIT ！${WHITE}"
			exit
		fi
		
		if [ -z "${op}" ];then
			export Language="${Language[0]}"
		else
			expr ${op} + 10 >>/dev/null 2>&1
			if [ ! $? == 0 ] || [ ${op} -le 0 ] || [ ${op} -gt ${#Language[@]} ];then
				echo -e "\n${RED}[E]：${WHITE}不存在此选项！ ${RED}EXIT ！${WHITE}"
				exit
			fi
			export Language=${Language[$((${op} - 1))]}
		fi
		
		# 最小SDK
		count=0
		echo -e "\n\t\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[0m"
		for x in $(seq 0 $((${#sdk_version[@]} - 1)))
		do
			echo -e "\t${GREEN}$((${x} + 1))${WHITE}．${sdk_version[${x}]}"
			let count++
		done
		echo -en "${WHITE}\n最小SDK版本[default: ${YELLOW}9 ${GREY}MinSDK=API 24:Android 7.0${WHITE}]：${GREEN}" ""
		read op
		op=$(echo ${op} | sed "s# ##g")
		if [ -z "${op}" ];then
			export minSdk=$((9 +16))
		else
			expr ${op} + 10 >>/dev/null 2>&1
			if [ ! $? == 0 ] || [ ${op} -le 0 ] || [ ${op} -gt ${#sdk_version[@]} ];then
				echo -e "\n${RED}[E]：${WHITE}不存在此选项！ ${RED}EXIT ！${WHITE}"
				exit
			fi
			export minSdk=$(( ${op} - 1 + 16 ))
		fi
		
		# 目标🎯SDK
		count=0
		echo -e "\n\t\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[0m"
		for x in $(seq 0 $((${#sdk_version[@]} - 1)))
		do
			echo -e "\t${GREEN}$((${x} + 1))${WHITE}．${sdk_version[${x}]}"
			let count++
		done
		echo -en "${WHITE}\n目标SDK版本🎯[default: ${YELLOW}17 ${GREY}MinSDK=API 32:Android 12.0${WHITE}]：${GREEN}" ""
		read op
		op=$(echo ${op} | sed "s# ##g")
		if [ -z "${op}" ];then
			export targetSdk=$((17 + 16))
		else
			expr ${op} + 10 >>/dev/null 2>&1
			if [ ! $? == 0 ] || [ ${op} -le 0 ] || [ ${op} -gt ${#sdk_version[@]} ];then
				echo -e "\n${RED}[E]：${WHITE}不存在此选项！ ${RED}EXIT ！${WHITE}"
				exit
			fi
			export targetSdk=$(( ${op} - 1 + 16 ))
		fi
	}
	
	_emptyActivity(){
		# 支持的语言
		Language="Java/Kotlin"
		_createProject ${Language}
		echo -e "$(
			cat <<-EOF
			\n\n\n${YELLOW}Info${WHITE}
			----------
			应用名称：${GREEN}${projectName}${WHITE}
			应用包名：${GREEN}${namespace}${WHITE}
			项目保存路径：${GREEN}${projectpath}${WHITE}
			项目语言：${GREEN}${Language}${WHITE}
			最小SDK版本：${GREEN}${minSdk}${WHITE}
			目标SDK版本🎯：${GREEN}${targetSdk}${WHITE}
			EOF
		)"
		_up_json
		if [ "${Language}" == "Java" ];then
			mkdir -p ${projectpath}
			cd ${projectpath}
			gradle init --type java-application --test-framework junit --project-name ${projectName} --dsl groovy --package ${namespace} <<< "\n\n"
			rm -rf ${projectpath}/{.gitattributes,app/src/{main,test}/resources}
			if [ ! -e "`pwd`/emptyActivity_Java.zip" ];then
				echo -e "\n${RED}[E]：${WHITE}模板资源emptyActivity_Java.zip已被删除，请适当调低apkToolConfig.json配置文件里面对应的参数template_versio，再更新脚本！ ${RED}EXIT ！${WHITE}"
				rm -rf ${projectpath}
				exit
			fi
			cd ${wordPathRoot}/template
			rm -rf emptyActivity_Java
			unzip -o emptyActivity_Java.zip
			# 处理根目录
			cd emptyActivity_Java
			noActivityPath=${wordPathRoot}/template/emptyActivity_Java
		elif [ "${Language}" == "Kotlin" ];then
			mkdir -p ${projectpath}
			cd ${projectpath}
			gradle init --type kotlin-application --project-name ${projectName} --dsl groovy --package ${namespace} <<< "\n\n"
			rm -rf ${projectpath}/{.gitattributes,app/src/{main,test}/resources}
			mkdir -p app/libs
			if [ ! -e "`pwd`/emptyActivity_Kotlin.zip" ];then
				echo -e "\n${RED}[E]：${WHITE}模板资源emptyActivity_Kotlin.zip已被删除，请适当调低apkToolConfig.json配置文件里面对应的参数template_versio，再更新脚本！ ${RED}EXIT ！${WHITE}"
				rm -rf ${projectpath}
				exit
			fi
			cd ${wordPathRoot}/template
			rm -rf emptyActivity_Kotlin
			unzip -o emptyActivity_Kotlin.zip
			# 处理根目录
			cd emptyActivity_Kotlin
			noActivityPath=${wordPathRoot}/template/emptyActivity_Kotlin
		fi
		grep -r -l "DEMO" "${noActivityPath}" | xargs sed -i "s/DEMO/${projectName}/g"
		grep -r -l "com.example.demo" "${noActivityPath}" | xargs sed -i "s/com.example.demo/${namespace}/g"
		SDKPATH=$(eval echo "$(echo ${json} | jq -r .sdk.sdk_root)")
		grep -r -l "sdk.dir=" "${noActivityPath}" | xargs sed -i "s#SDKPATH#${SDKPATH}#g"
		cp ./{.gitignore,build.gradle,gradle.properties,local.properties,settings.gradle} ${projectpath}
		# 处理app
		cd app
		grep -r -l "minSdk value" "${noActivityPath}" | xargs sed -i "s/minSdk value/minSdk ${minSdk}/g"
		grep -r -l "targetSdk value" "${noActivityPath}" | xargs sed -i "s/targetSdk value/targetSdk ${targetSdk}/g"
		cp ./{.gitignore,build.gradle,proguard-rules.pro} ${projectpath}/app
		# 处理src
		cd src
		rm -rf ${projectpath}/app/src/*
		namespace="$(echo ${namespace} | sed 's|\.|/|g')"
		mkdir -p ${projectpath}/app/src/{main,test,androidTest}/java/${namespace}
		mkdir -p ${projectpath}/app/src/main/res
		cp -rf ./main/{AndroidManifest.xml,res} ${projectpath}/app/src/main
		for x in androidTest main test
		do
			 [ "${Language}" == "Kotlin" ] && find "`pwd`/${x}" -name *.kt  -print0 | xargs -0 cp -rp --target-directory=${projectpath}/app/src/${x}/java/${namespace}
			 [ "${Language}" == "Java" ] && find "`pwd`/${x}" -name *.java  -print0 | xargs -0 cp -rp --target-directory=${projectpath}/app/src/${x}/java/${namespace}
		done
		echo -e "\n${GREEN}Done！"
		json=$(echo ${json} | jq -r ".androidProject += [${json_data}]")
		echo ${json} | jq -r > ${jsonPath}
	}

	_noActivity(){
		# 支持的语言
		Language="Java/Kotlin"
		_createProject ${Language}
		echo -e "$(
			cat <<-EOF
			\n\n\n${YELLOW}Info${WHITE}
			----------
			应用名称：${GREEN}${projectName}${WHITE}
			应用包名：${GREEN}${namespace}${WHITE}
			项目保存路径：${GREEN}${projectpath}${WHITE}
			项目语言：${GREEN}${Language}${WHITE}
			最小SDK版本：${GREEN}${minSdk}${WHITE}
			目标SDK版本🎯：${GREEN}${targetSdk}${WHITE}
			EOF
		)"
		_up_json
		if [ "${Language}" == "Java" ];then
			mkdir -p ${projectpath}
			cd ${projectpath}
			gradle init --type java-application --test-framework junit --project-name ${projectName} --dsl groovy --package ${namespace} <<< "\n\n"
			rm -rf ${projectpath}/{.gitattributes,app/src/{main,test}/resources}
			if [ ! -e "`pwd`/noActivity_Java.zip" ];then
				echo -e "\n${RED}[E]：${WHITE}模板资源noActivity_Java.zip已被删除，请适当调低apkToolConfig.json配置文件里面对应的参数template_versio，再更新脚本！ ${RED}EXIT ！${WHITE}"
				rm -rf ${projectpath}
				exit
			fi
			cd ${wordPathRoot}/template
			rm -rf noActivity_Java
			unzip -o noActivity_Java.zip
			# 处理根目录
			cd noActivity_Java
			noActivityPath=${wordPathRoot}/template/noActivity_Java
			grep -r -l "DEMO" "${noActivityPath}" | xargs sed -i "s/DEMO/${projectName}/g"
			grep -r -l "com.example.demo" "${noActivityPath}" | xargs sed -i "s/com.example.demo/${namespace}/g"
			SDKPATH=$(eval echo "$(echo ${json} | jq -r .sdk.sdk_root)")
			grep -r -l "sdk.dir=" "${noActivityPath}" | xargs sed -i "s#SDKPATH#${SDKPATH}#g"
			cp ./{.gitignore,build.gradle,gradle.properties,local.properties,settings.gradle} ${projectpath}
			# 处理app
			cd app
			grep -r -l "minSdk value" "${noActivityPath}" | xargs sed -i "s/minSdk value/minSdk ${minSdk}/g"
			grep -r -l "targetSdk value" "${noActivityPath}" | xargs sed -i "s/targetSdk value/targetSdk ${targetSdk}/g"
			cp ./{.gitignore,build.gradle,proguard-rules.pro} ${projectpath}/app
			# 处理src
			cd src
			mkdir -p ${projectpath}/app/src/androidTest
			cp -rf ${projectpath}/app/src/main/java ${projectpath}/app/src/androidTest
			cp -rf ./main/{AndroidManifest.xml,res} ${projectpath}/app/src/main
			find ${projectpath} -name *.java | xargs rm -rf
			echo -e "\n${GREEN}Done！"
		elif [ "${Language}" == "Kotlin" ];then
			mkdir -p ${projectpath}
			cd ${projectpath}
			gradle init --type kotlin-application --project-name ${projectName} --dsl groovy --package ${namespace} <<< "\n\n"
			rm -rf ${projectpath}/{.gitattributes,app/src/{main,test}/resources}
			mkdir -p app/libs
			if [ ! -e "`pwd`/noActivity_Kotlin.zip" ];then
				echo -e "\n${RED}[E]：${WHITE}模板资源noActivity_Kotlin.zip已被删除，请适当调低apkToolConfig.json配置文件里面对应的参数template_versio，再更新脚本！ ${RED}EXIT ！${WHITE}"
				rm -rf ${projectpath}
				exit
			fi
			cd ${wordPathRoot}/template
			rm -rf noActivity_Kotlin
			unzip -o noActivity_Kotlin.zip
			# 处理根目录
			cd noActivity_Kotlin
			noActivityPath=${wordPathRoot}/template/noActivity_Kotlin
			grep -r -l "DEMO" "${noActivityPath}" | xargs sed -i "s/DEMO/${projectName}/g"
			grep -r -l "com.example.demo" "${noActivityPath}" | xargs sed -i "s/com.example.demo/${namespace}/g"
			SDKPATH=$(eval echo "$(echo ${json} | jq -r .sdk.sdk_root)")
			grep -r -l "sdk.dir=" "${noActivityPath}" | xargs sed -i "s#SDKPATH#${SDKPATH}#g"
			cp ./{.gitignore,build.gradle,gradle.properties,local.properties,settings.gradle} ${projectpath}
			# 处理app
			cd app
			grep -r -l "minSdk value" "${noActivityPath}" | xargs sed -i "s/minSdk value/minSdk ${minSdk}/g"
			grep -r -l "targetSdk value" "${noActivityPath}" | xargs sed -i "s/targetSdk value/targetSdk ${targetSdk}/g"
			cp ./{.gitignore,build.gradle,proguard-rules.pro} ${projectpath}/app
			# 处理src
			cd src
			rm -rf ${projectpath}/app/src/*
			namespace="$(echo ${namespace} | sed 's|\.|/|g')"
			echo {main,test,androidTest}/${namespace}
			mkdir -p ${projectpath}/app/src/{main,test,androidTest}/java/${namespace}
			mkdir -p ${projectpath}/app/src/main/res
			cp -rf ${projectpath}/app/src/main/java ${projectpath}/app/src/androidTest
			cp -rf ./main/{AndroidManifest.xml,res} ${projectpath}/app/src/main
			find ${projectpath} -name *.java | xargs rm -rf
			echo -e "\n${GREEN}Done！"		
		fi
		#- --type：指定项目类型，这里指定为 Java 应用程序。
		#- --test-framework：指定测试框架，这里指定为 JUnit。
		#- --project-name：指定项目名称。
		#- --dsl：指定构建脚本语言，这里指定为 Groovy。
		#- --package：指定项目的 Java 包名称。
		#- --skip-build：跳过生成默认的构建脚本和 Git 仓库配置。
		json=$(echo ${json} | jq -r ".androidProject += [${json_data}]")
		echo ${json} | jq -r > ${jsonPath}
	}
	
	# main
	arr=(
	'No Activity'
	'Empty Activity	'
	)
	echo -e "\t\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[0m"
	num=${#arr[@]}
	for x in $(seq 0 $((${num} - 1)))
	do		
		echo -e "\t${GREEN}$((${x} + 1))${WHITE}．${arr[${x}]}"
	done
	echo -en "\n请选择创建的模板[default: ${YELLOW}2${WHITE}]：${GREEN}" ""
	read op
	op=$(echo ${op} | sed "s# ##g")
	[ -z ${op} ] && op=2
	case $op in
		1)
			_noActivity
			;;
		2)
			_emptyActivity	
			;;
		*)
			echo -e "\n此选项 --> ${GREEN}${op}${WHITE} 对应的项目模板不存在！${WHITE}"
			exit
			;;
	esac
}

_update(){
	echo -e "\n${YELLOW}尝试获取最新版本.......${WHITE}"
	url="https://raw.githubusercontent.com/Tridays/command-tools/main/Termux/android-tool"
	# json
	echo -e "\n${GREEN}[URL]${WHITE}：${url}/apkToolConfig.json"
	txt=$(curl -sL "${url}/apkToolConfig.json")
	curl -sL "${url}/apktool.sh" > ${HOME}/.tmp
	# 备份
	cd ${HOME}
	mkdir -p ${wordPathRoot}/backup ${sharedPath}/backup
	if [ $(ls -1q "${wordPathRoot}/backup" | wc -l) -gt 10 ]; then
	    oldest=$(ls -1tq "${wordPathRoot}/backup" | tail -n 1)
	    #删除最旧的文件
	    rm -rf "${wordPathRoot}/backup/${oldest}" ${sharedPath}/backup/*
	fi
	t=$(date +%Y-%m-%d_%H-%M-%S)
	zip ${wordPathRoot}/backup/apktool-${t}.zip apkToolConfig.json
	zip ${wordPathRoot}/backup/apktool-${t}.zip apktool.sh
	echo -e "\n${GREEN}[Script  Backups]${WHITE}：${HOME}/apktool-${t}.zip"
	# shell
	#echo -e "\n${GREEN}[URL]${WHITE}：${url}/apktool.sh"
	# 依次更新 脚本，配置文件，模板
	for j in shell config template
	do
		newVersion=$(echo "${txt}" | jq -r ".${j}_version")
		oldVersion=$(echo "${json}" | jq -r ".${j}_version")
		if [[ -z "${newVersion}" || "${newVersion}" == "null" ]];then
			echo -e "\n${RED}读取最新版本失败！请检查网络重试......"
			exit
		fi
		nV=($(echo ${newVersion}  | sed "s#.# #g" ))
		oV=($(echo ${oldVersion}  | sed "s#.# #g" ))
		s=true
		for x in 0 1 2
		do
			if [[ ${nV[${x}]} =~ ^[-]?[0-9]+$ && ${nV[${x}]} =~ ^[-]?[0-9]+$ && ${nV[${x}]} -lt ${oV[${x}]} ]];then
				# echo "${nV[${x}]} 和 ${oV[${x}]}"
				s=false
			fi
		done
		if [ ! "${s}" == "true" ];then
			echo -e "\n${GREEN}[${j}]${WHITE}：无最新版本可用......."
			continue
		fi
			echo -e "\n${GREEN}[${j} new version]${WHITE}：${newVersion}"
			case ${j} in
				shell)
					mv ${HOME}/.tmp ${HOME}/apktool.sh
					;;
				config)
					echo ${txt} | jq -r > ${HOME}/apkToolConfig.json
					echo -e "\n${YELLOW}[Note]${WHITE}：旧的配置文件已被新配置文件覆盖！请重新配置！"
					;;
				template)
					cd ${wordPathRoot}
					rm -rf template.zip
					_command "wget -c" "${url}/template.zip"
					unzip -o template.zip
					;;
			esac							
	done
	cp -r "${wordPathRoot}/backup" "${sharedPath}"
	echo -e "\n${GREEN}此次更新结束！${WHITE}"
}

_info(){
	echo -e "${GREEN}	_____________                  ________                       
	___  __/__  /_____________________  __ \_____ _____  _________
	__  /  __  __ \_  ___/  _ \  _ \_  / / /  __ \`/_  / / /_  ___/
	_  /   _  / / /  /   /  __/  __/  /_/ // /_/ /_  /_/ /_(__  ) 
	/_/    /_/ /_//_/    \___/\___//_____/ \__,_/ _\__, / /____/  
	                                              /____/${WHITE}"
	echo -e "$(
	cat <<-EOF
	    \n${RED}    Source of project support${WHITE}[目前Android项目来源支持的情况]：
	        ${GREEN}·${WHITE}Android Studio  [${GREEN}✔${WHITE}][win/Linux软件]--> https://developer.android.google.cn/studio
	        ${YELLOW}·${WHITE}IntelliJ IDEA   [${YELLOW}unknown${WHITE}][win/Linux软件]--> https://www.jetbrains.com/idea
	        ${YELLOW}·${WHITE}Eclipse         [${YELLOW}unknown${WHITE}][win/Linux软件]--> https://www.eclipse.org/downloads
	        ${GREEN}·${WHITE}CodeAssist      [${GREEN}✔${WHITE}][安卓软件]--> https://github.com/tyron12233/CodeAssist
	        ${GREEN}·${WHITE}AndroidIDE      [${GREEN}✔${WHITE}][安卓软件]--> https://github.com/AndroidIDEOfficial/AndroidIDE
	        ${GREEN}·${WHITE}AIDE            [${GREEN}✔${WHITE}][安卓软件]
	        ${GREEN}·${WHITE}This Script     [${GREEN}✔${WHITE}][shell脚本]--> https://github.com/Tridays/command-tools/tree/main/Termux/android-tool
	        
		${RED}    Supported languages${WHITE}[目前支持的语言的情况]：
	        ${GREEN}·${WHITE}Java         [${GREEN}✔${WHITE}]
	        ${GREEN}·${WHITE}Kotlin       [${GREEN}✔${WHITE}]
	        ${RED}·${WHITE}C++          [${RED}✘${WHITE}]
	        ${RED}·${WHITE}C#           [${RED}✘${WHITE}]
	        ${RED}·${WHITE}JavaScript   [${RED}✘${WHITE}]
	        ${RED}·${WHITE}Python       [${RED}✘${WHITE}]
	        
		    Author's message：目前脚本在起步阶段，作者偶尔摸鱼写 OR 修bug ${GREEN}(${YELLOW}p${RED}≧${GREEN}w\e${RED}≦\e${YELLOW}q\e${GREEN})${WHITE}
		    
		    ${GREY}QQ交流群：1888888      [入群密码：apktool]
		    ${GREY}温馨提示：如果使用脚本下载SDK或者构建APK开始时的下载工作，网速表现的非常慢，这说明你的魔法不够强，需要自带强大的魔法才能够带动网速！
		\n\n
	EOF
	)"
}

_userSelect(){
	num=$(echo ${json} | jq -r ".androidProject | length")
	if [ "${num}" == "0" ];then
		echo -e "\n${YELLOW}[W]：${WHITE}当前配置文件，没有任何项目！${jsonPath} ${RED}EXIT ！${WHITE}"
		exit
	fi
	
	echo -e "\t\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[31m■\e[33m■\e[32m■\e[36m■\e[34m■\e[35m■\e[0m"
	for x in $(seq 0 $((${num} - 1)))
	do
		projectName=$(echo ${json} | jq -r ".androidProject[${x}].projectName")
		echo -e "\t${GREEN}$((${x} + 1))${WHITE}．${projectName}"
	done
	echo -en "请输入项目序号：${GREEN}" ""
	read op
	op=$(echo ${op} | sed "s# ##g")
	if [[ ${op} =~ ^[-]?[0-9]+$ && ${op} -gt 0 && ${op} -le ${num} ]];then
		export projectNum=$((${op} - 1))
	else
		echo -e "\n此选项 --> ${GREEN}${op}${WHITE} 对应的项目不存在！${WHITE}"
		exit
	fi
}

# 依赖
#dependences="tur-repo apksigner aapt aapt2 gradle git wget neofetch jq x11-repo qemu-system-x86_64 "
dependences="tur-repo tree apksigner aapt aapt2 gradle zip git wget neofetch jq"
_checkenv ${dependences}
jsonPath="${HOME}/apkToolConfig.json"
if [ ! -e "${jsonPath}" ];then
	echo -e "\n${RED}[E]：${WHITE}配置文件不存在！请把json配置文件移至${HOME}${RED}EXIT ！${WHITE}"
	echo -e "\n${GREEN}或者移步下载：https://raw.githubusercontent.com/Tridays/command-tools/main/Termux/android-tool/apkToolConfig.json"
	exit
fi
json=$(cat ${jsonPath})
echo ${json} | jq -r > /dev/null 2>&1
if [ ! "$?" == "0" ];then
	echo -e "\n${RED}[E]：${WHITE}配置文件出现错误，请改正！${jsonPath} ${RED}EXIT ！${WHITE}"
	exit
fi
# 脚本工作路径
wordPathRoot=$(eval echo "$(echo ${json} | jq -r .wordPathRoot)")
if [ ! -d "${wordPathRoot}" ];then
	mkdir -p ${wordPathRoot}
fi
if [ ! -d "${HOME}/storage" ];then
	termux-setup-storage
fi
Version=$(echo ${json} | jq -r .shell_version)
sharedPath="/storage/emulated/0/Download/apktool"
mkdir -p ${sharedPath}
main(){
	case "$1" in
	"-create")
		_create
		;;	
	"-update")
		_update
		;;	
	"-install" | "-i")
		shift 1
		_install $@
		;;	
	"-signe")
		_signe
		;;
	"-replace")
		_changeAAPT2
		;;
	"-clear")
		_clear
		;;
	"-auto")
		_auto
		;;
	"-info")
		_info
		;;
	*)
		echo -e "$(
		cat <<-EOF
		\n\n${RED}Usage${WHITE}[用法]：
			
		    ${GREEN}-create project${WHITE}         创建Android项目
		    ${GREEN}-update${WHITE}                 更新脚本和配置
		    
		    ${RED}[-install (OR) -i]${WHITE}
		    ${GREEN}-install sdkmanager${WHITE}     安装cmdline-tools管理包
		    ${GREEN}-install sdk${WHITE}            安装sdk platforms;android-*
		    ${GREEN}-install build-tools${WHITE}    安装build-tools
		    ${GREEN}-install sources${WHITE}        安装sources;android-*
		    ${RED}[Default jdk17]${WHITE}
		    ${GREEN}-install jdk8${WHITE}           额外安装jdk8
		    ${GREEN}-install jdk11${WHITE}          额外安装jdk11
		    
		    ${GREEN}-replace${WHITE}                自动替换aapt2		    
		    ${GREEN}-signe${WHITE}                  自动签名APK -> 有root权限会自动安装
		    ${GREEN}-clear${WHITE}                  清除所有项目的构建缓存、全局缓存、配置文件失效项目等
		    ${GREEN}-auto${WHITE}                   自动构建 -> 替换AAPT2 -> 签名APK -> 安装APK
		    ${RED}    APK Build Flow${WHITE}[APK 构建流程思路]：
		            create project    [创建Android项目]
		                  ↓
		            gradle build (OR) ./gradlew build    [首次，构建/打包Android项目]
		                                                 Note：第一次构建基本会失败，所以需要替换AAPT2
		                  ↓
		            replace AAPT2      [替换首次构建项目所使用的AAPT2]
		                  ↓
		            gradle build (OR) ./gradlew build    [再次，构建/打包Android项目]
		                  ↓
		            signe APK     [APK签名 V1 + V2 + V3]
		                  ↓
		            install APK     [安装APK：有root：自动安装 (OR) 无root：手动安装]
		        
		    ${GREEN}-info${WHITE}                   获取脚本更详细信息
		    ${GREEN}-h${WHITE}                      帮助
		    
		    Current Script Version：${Version}
		    Termux Version：0.118.0
		    Author：${YELLOW}By ThreeDays${WHITE}
		    
		    \n\n
		EOF
		)"
		;;
	esac
}
main $@

