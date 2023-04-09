#!/data/data/com.termux/files/usr/bin/env bash
unset LD_PRELOAD
#set -x
# 容器路径
rootfs_url="https://dl-cdn.alpinelinux.org/alpine/v3.17/releases/aarch64/alpine-minirootfs-3.17.3-aarch64.tar.gz"
rootfs_name="alpine_3.17.3_arm64"
rootfs_path="${HOME}/.local/td/containers/proot/${rootfs_name}"
proc_path="${HOME}/.local/td/containers/proot_proc"
mkdir -p ${rootfs_path}
mkdir -p ${proc_path}



_install_apline(){
	wget -c "${rootfs_url}" -O ${rootfs_name}.tar.gz
	tar -zxvf ${rootfs_name}.tar.gz -C ${rootfs_path}
	wget -c Apline-bind.zip
	unzip -o Apline-bind.zip -d ${proc_path}
}


_exec_apline(){
	command="proot --root-id "
	command+=" --pwd=/root "
	command+=" --rootfs=${rootfs_path} "
	command+=" --mount=/system "
	command+=" --mount=/apex "
	command+=" --kill-on-exit "
	command+=" --sysvipc -L "
	command+=" --link2symlink "
	command+=" --mount=/proc:/proc "
	command+=" --mount=/dev:/dev "
	command+=" --mount=${rootfs_path}/tmp:/dev/shm "
	command+=" --mount=/dev/urandom:/dev/random "
	command+=" --mount=/proc/self/fd:/dev/fd "
	command+=" --mount=/proc/self/fd/0:/dev/stdin "
	command+=" --mount=/proc/self/fd/1:/dev/stdout "
	command+=" --mount=/proc/self/fd/2:/dev/stderr "
	command+=" --mount=/dev/null:/dev/tty0 "
	command+=" --mount=${proc_path}/Apline-bind/gitstatus:/root/.cache/gitstatus "
	command+=" --mount=/dev/null:/proc/sys/kernel/cap_last_cap "
	command+=" --mount=/storage/self/primary/Download:/media/sd "
	command+=" --mount=${proc_path}/Apline-bind/stat:/proc/stat "
	command+=" --mount=${proc_path}/Apline-bind/version:/proc/version "
	command+=" --mount=${proc_path}/Apline-bind/bus:/proc/bus "
	command+=" --mount=${proc_path}/Apline-bind/buddyinfo:/proc/buddyinfo "
	command+=" --mount=${proc_path}/Apline-bind/cgroups:/proc/cgroups "
	command+=" --mount=${proc_path}/Apline-bind/consoles:/proc/consoles "
	command+=" --mount=${proc_path}/Apline-bind/crypto:/proc/crypto "
	command+=" --mount=${proc_path}/Apline-bind/devices:/proc/devices "
	command+=" --mount=${proc_path}/Apline-bind/diskstats:/proc/diskstats "
	command+=" --mount=${proc_path}/Apline-bind/execdomains:/proc/execdomains "
	command+=" --mount=${proc_path}/Apline-bind/fb:/proc/fb "
	command+=" --mount=${proc_path}/Apline-bind/filesystems:/proc/filesystems "
	command+=" --mount=${proc_path}/Apline-bind/interrupts:/proc/interrupts "
	command+=" --mount=${proc_path}/Apline-bind/iomem:/proc/iomem "
	command+=" --mount=${proc_path}/Apline-bind/ioports:/proc/ioports "
	command+=" --mount=${proc_path}/Apline-bind/kallsyms:/proc/kallsyms "
	command+=" --mount=${proc_path}/Apline-bind/keys:/proc/keys "
	command+=" --mount=${proc_path}/Apline-bind/key-users:/proc/key-users "
	command+=" --mount=${proc_path}/Apline-bind/kpageflags:/proc/kpageflags "
	command+=" --mount=${proc_path}/Apline-bind/loadavg:/proc/loadavg "
	command+=" --mount=${proc_path}/Apline-bind/locks:/proc/locks "
	command+=" --mount=${proc_path}/Apline-bind/misc:/proc/misc "
	command+=" --mount=${proc_path}/Apline-bind/modules:/proc/modules "
	command+=" --mount=${proc_path}/Apline-bind/pagetypeinfo:/proc/pagetypeinfo "
	command+=" --mount=${proc_path}/Apline-bind/partitions:/proc/partitions "
	command+=" --mount=${proc_path}/Apline-bind/sched_debug:/proc/sched_debug "
	command+=" --mount=${proc_path}/Apline-bind/softirqs:/proc/softirqs "
	command+=" --mount=${proc_path}/Apline-bind/timer_list:/proc/timer_list "
	command+=" --mount=${proc_path}/Apline-bind/uptime:/proc/uptime "
	command+=" --mount=${proc_path}/Apline-bind/vmallocinfo:/proc/vmallocinfo "
	command+=" --mount=${proc_path}/Apline-bind/vmstat:/proc/vmstat "
	command+=" --mount=${proc_path}/Apline-bind/zoneinfo:/proc/zoneinfo "
	command+=" /usr/bin/env -i HOSTNAME=23049RAD8C HOME=/root USER=root TERM=xterm-256color SDL_IM_MODULE=fcitx XMODIFIERS=\@im=fcitx QT_IM_MODULE=fcitx GTK_IM_MODULE=fcitx TMOE_CHROOT=false TMOE_PROOT=true TMPDIR=/tmp DISPLAY=:2 PULSE_SERVER=tcp:127.0.0.1:4713 LANG=zh_CN.UTF-8 SHELL=/bin/ash PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games "
	case "$1" in
	"-ash")
			command+="/bin/ash -c"
			;;
	"-bash")
			command+="/bin/bash -c"
			;;
	"-login" | "-l")
			command+="/bin/ash -l"
			shift 1
			command ${command}
			return 0
			;;
	esac
	command ${command} "${cmd}"
}
	

_vscode_config(){
		[ -z "$(dpkg -l | grep code-server)"  ] && _msg E "请先安装VScode-server！" && _enter && return 0
		address=$(dialog --clear --title "code-server连接地址" \
		--inputbox "输入你的地址(不填为默认值)
		([默认127.0.0.1])" 8 50 \
		3>&1 1>&2 2>&3 3>&-)
		[ -z "$address" ]&&address=127.0.0.1
		
		port=$(dialog --clear --title "code-server连接端口" \
		--inputbox "输入你的端口(不填为默认值)
		([默认8050])" 8 50 \
		3>&1 1>&2 2>&3 3>&-)
		[ -z "$port" ]&&port=8050
		
		password=$(dialog --clear --title "code-server连接密码" \
		--inputbox "输入你的密码(不填为默认值)
		([默认：无])" 8 50 \
		3>&1 1>&2 2>&3 3>&-)
		
		auth=none
		[ -n "$password" ]&&auth=password
		
		cat<<-EOF > $HOME/.config/code-server/config.yaml
		bind-addr: 127.0.0.1:2020
		auth: none
		password: 123456
		cert: false
		EOF
		echo -e "${YELLOW}\n-------------code-server配置文件-------------${WHITE}"
		cat $HOME/.config/code-server/config.yaml
		echo -e "${YELLOW}---------------------------------------------------${WHITE}"
		echo -e "${GREEN}小提示：关闭后启动配置生效${WHITE}"
}



# install vscode
_install_vscode(){
	cat <<-EOF >${rootfs_path}/etc/resolv.conf
	nameserver 114.114.114.114
	nameserver 8.8.8.8
	nameserver 1.2.4.8
	nameserver 240c::6666
	nameserver 240c::6644
	EOF
	
	cmd="$(
		cat <<-EOF
		apk add bash tzdata newt sudo shadow
		apk upgrade
		neofetch
		apk add  aria2 binutils curl iproute2 tar procps nano xz zstd
		apk add micro git
		
		# Apline 3.17
		apk add alpine-sdk bash libstdc++ libc6-compat
		echo "http://dl-cdn.alpinelinux.org/alpine/v3.16/main" > /etc/apk/repositories
		apk update
		apk add python3 nodejs
		echo "http://dl-cdn.alpinelinux.org/alpine/v3.16/community" > /etc/apk/repositories
		apk update
		apk add npm
		npm config set python python3
		npm install --global code-server --unsafe-perm
		npm install -g 'spdlog' 'yauzl' 'minimist' 'yazl' '@microsoft/1ds-core-js'
		cat ~/.config/code-server/config.yaml
		#code-server --help
		EOF
	)"
	_exec_apline -ash ${cmd}
}



# main
main(){
	case $* in
	-c | --config )
		_vscode_config
		;;
	-i | --install )
		_install_vscode
		;;
	-s | --start )
		echo
		;;
	-l | --login )
		_exec_apline -l
		;;
	--info )
		echo
		;;
    -h* | --h* | *)
        cat <<-EOF
			-i OR --install         --安装vscode-web
			-s OR --start          --启动vscode-web
			--info                 --显示更多信息
			-h OR --help          --帮助
		EOF
        
        exit 0
        ;;
    esac
}

main $@