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
		if [ -z "$(dpkg -l | grep $x)" ];then
			if [ "${num}" == "0" ];then
				_command "pkg update -y"
				num=1
			fi
			_command "pkg install" "${x}" "-y"
		fi
	done
}


createkey(){
	if [ ! -e "${workplace}/${keyName}" ];then
		keytool -genkey -v -keystore ${keyName} -alias release -keyalg RSA -keysize 2048 -validity 10000 -storepass ${password} -keypass ${password} -dname "CN=${Name}, OU=${OrganizationalUnit}, O=${Organization}, L=${City}, S=${State}, C=${CountryCode}"
		echo -e "\nkeytool -genkey -v -keystore ${keyName} -alias release -keyalg RSA -keysize 2048 -validity 10000 -storepass ${password} -keypass ${password} -dname "CN=${Name}, OU=${OrganizationalUnit}, O=${Organization}, L=${City}, S=${State}, C=${CountryCode}""
	fi
}
V1(){
	for x in $(ls | grep ".apk")
	do
		apkname=$(echo "${x}" | sed "s#.apk##g;s#-unsigned##g")
		echo "V1签名：${apkname}.apk"
		# jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore my-release-key.keystore app/build/outputs/apk/release/app-release-unsigned-aligned.apk my-key-alias
		jarsigner -verbose -keystore ${keyName} -storepass ${password} -keypass ${password} -signedjar ${apkname}-signed.apk ${x} release
		echo -e "\njarsigner -verbose -keystore ${keystore} -storepass ${password} -keypass ${keypass} -signedjar ${apkname}-signed.apk ${x} release"
		rm -rf ${x}
	done
}
V2(){
	for x in $(ls | grep ".apk")
	do
		apkname=$(echo "${x}" | sed "s#.apk##g;s#-unsigned##g")
		echo "V2签名：${apkname}.apk"
		apksigner sign --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} ${x}
		echo -e "\napksigner sign --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} ${x}"
		rm -rf *.idsig
	done
}
V3(){
	for x in $(ls | grep ".apk")
	do
		apkname=$(echo "${x}" | sed "s#.apk##g;s#-unsigned##g")
		echo "zipalign签名优化：${apkname}.apk"
		zipalign -v 4 ${x} ${apkname}-zipalign.apk
		echo -e "\nzipalign -v 4 ${x} ${apkname}-zipalign.apk"
		rm -rf ${x}
	done

	for x in $(ls | grep ".apk")
	do
		apkname=$(echo "${x}" | sed "s#.apk##g;s#-unsigned##g")
		echo "V3签名：${apkname}.apk"
		apksigner sign --ks ${keyName} --ks-pass pass:${password} --key-pass pass:${password} --out ${apkname}-aligned.apk --v4-signing-enabled true ${x}
		echo -e "\napksigner sign --ks ${keyName} --key-pass pass:${password} --out ${apkname}-aligned.apk --v4-signing-enabled true ${x}"
		rm -rf ${x}
		rm -rf *.idsig
	done
}

_installAPK(){
	root=$(echo ${json} | jq -r ".root")
	for x in $(ls | grep ".apk")
	do
		if [ -n "$(echo ${x} | grep "debug")" ];then
			echo "debug版本apk跳过安装"
			continue
		fi
		# 需要root
		if [ "${root}" == "true" ];then
			root=$(echo $json | jq -r .root)
			su -c pm install ${x}
			su -c monkey -p "${namespace}" -c android.intent.category.LAUNCHER 1
		else
			mkdir -p "${sharedPath}/apk-signe"
			cp -r "${workplace}" "${sharedPath}/apk-signe"
			echo -e "\n${GREEN}[Note]${WHITE}：APK已复制一份至 /storage/emulated/0/Download/apktool/${namespace} 请手动安装"
		fi
	done
	exit
}


# 给apk签名
_signe(){
	if [ "$#" == "0" ];then
		_userSelect
	fi
	data=$(echo ${json} | jq -r ".androidProject[${projectNum}]")
	# export ANDROID_SDK_ROOT=${HOME}/sdk
	
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
	for x in $(find ${projectPath} -type f -name *.apk)
	do
		cp ${x} ${workplace}
	done
	# 创建证书
	createkey ${workplace}
	for x in $(echo ${signeType} | sed "s#+# #g")
	do
		${x}
	done
	# 安装软件
	_installAPK ${workplace} ${namespace} ${namespace}
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

_update(){
	echo -e "\n${YELLOW}尝试获取最新版本.......${WHITE}"
	url="https://raw.githubusercontent.com/Tridays/command-tools/main/Termux/android-tool"
	echo -e "\n${GREEN}[URL]${WHITE}：${url}/apkToolConfig.json"
	txt=$(curl -sL "${url}/apkToolConfig.json")
	echo -e "\n${GREEN}[URL]${WHITE}：${url}/apktool.sh"
	at=$(curl -sL "${url}/apktool.sh")
	newVersion=$(echo "${txt}" | jq -r .version)
	oldVersion=$(echo "${json}" | jq -r .version)
	if [[ -z "${newVersion}" || "${newVersion}" == "null" ]];then
		echo -e "\n${RED}读取最新版本失败！请检查网络重试......"
		exit
	fi
	nV=($(echo ${newVersion}  | sed "s#.# #g" ))
	oV=($(echo ${oldVersion}  | sed "s#.# #g" ))
	s=true
	for x in 0 1 2
	do
		if [ ${nV[${x}]} -lt ${oV[${x}]} ];then
			s=false
		fi
	done
	if [ "${s}" == "true" ];then
		echo -e "\n${GREEN}[new version]${WHITE}：${newVersion}"
		echo ${txt} > ${HOME}/apkToolConfig.json
		echo ${at} > ${HOME}/apktool.sh
		echo -e "\n${GREEN}更新完毕！${WHITE}"
		exit
	else
		echo -e "\n${YELLOW}无最新版本可用.......${WHITE}"
		exit
	fi
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
	    \n${RED}    Source of project support${WHITE}[目前支持的Android项目来源]：
	        ·Android Studio  [win/Linux软件]--> https://developer.android.google.cn/studio
	        ·CodeAssist      [安卓软件]--> https://github.com/tyron12233/CodeAssist
	        ·AIDE            [安卓软件]
	        ·This Script     [termux脚本]--> https://github.com/Tridays/command-tools/tree/main/Termux/android-tool
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
dependences="tur-repo apksigner aapt aapt2 gradle git wget neofetch jq  "
_checkenv ${dependences}
jsonPath="${HOME}/apkToolConfig.json"
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
Version=$(echo ${json} | jq -r .version)
sharedPath="${HOME}/storage/shared/Download/apktool"
mkdir -p ${sharedPath}
main(){
	case "$1" in
	"-create")
		echo
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
		        
		    ${GREEN}-info${WHITE}                   获取脚本详细信息、最新版本等等
		    ${GREEN}-H${WHITE}                      帮助
		    
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

