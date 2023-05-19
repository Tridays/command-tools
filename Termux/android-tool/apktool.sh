
# Android项目路径
projectPath="${HOME}/App"
# Android项目的包名
packageName="com.example.app"

# 密匙信息内容
keyName="release-key.keystore"   # 证书文件名
password="123456"    # 证书密码
Name="xiaoming"     # 姓名
OrganizationalUnit="td"    # 组织
Organizational="td"      # 组织
City="td"     # 所在城市
State="td"    # 
CountryCode="86"   # 所在国家代码

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

i(){
	for x in $(ls | grep ".apk")
	do
		if [ -n "$(echo ${x} | grep "debug")" ];then
			echo "debug版本apk跳过安装"
			continue
		fi
		# 需要root
		su -c pm install ${x}
		su -c monkey -p "${packageName}" -c android.intent.category.LAUNCHER 1
	done
}

# 给apk签名
signe(){
	if [ ! -e "${projectPath}" ];then
		echo "Exit ！"
		exit
	fi
	workplace="${HOME}/.apk-signe"
	mkdir -p ${workplace}
	cd ${workplace}
	rm -rf *.apk
	for x in $(find ${projectPath} -type f -name *.apk)
	do
		cp ${x} ${workplace}
	done
	# 创建证书
	createkey ${workplace}
	# V1签名
	V1
	# V2签名
	V2
	# V3签名
	V3
	# 安装软件
	i
}

# 更换aapt2
changeAAPT2(){
	jarpath=$(find $HOME/.gradle -type f -name "aapt2*linux.jar")
	jarName="$(echo ${jarpath} | awk -F "/" '{print $NF}')"
	mkdir aapt2
	cd aapt2
	cp ${jarpath} ./
	jar -cf ${jarName} *
	ls -al
	cp ${PREFIX}/bin/aapt2 ./
	echo "-------------"
	ls -al
	jar -cf ${jarName} *
	cp ${jarName} ${jarpath}
	rm -rf ./*
	for x in $(find $HOME/.gradle -type f -name aapt2)
	do	
		cp ${PREFIX}/bin/aapt2 ${x}
	done
}



# pkg i tur-repo -y
# pkg i apksigner aapt aapt2 gradle -y
main(){
	case "$@" in
	"-signe")
		signe
		;;
	"-change")
		changeAAPT2
		;;
	*)
		echo "$(
		cat <<-EOF
		    -signe   自动签名APK
		    -change   自动替换aapt2
		    -H    帮助
		EOF
		)"
		;;
	esac
}
main $@