#!/data/data/com.termux/files/usr/bin/bash
unset LD_PRELOAD
set -x
rootfs_name="alpine_3.17.3_arm64"
rootfs_path="${HOME}/.local/td/containers/proot/${rootfs_name}"
proc_path="${HOME}/.local/td/containers/proot_proc"
cmd="chmod 775 /root/a && /root/a"
cmd="/root/a"

_start_apline(){
    proot --root-id \
    --pwd=/root \
    --rootfs=${rootfs_path} \
    --mount=/system \
    --mount=/apex \
    --kill-on-exit \
    --sysvipc -L \
    --link2symlink \
    --mount=/proc:/proc \
    --mount=/dev:/dev \
    --mount=${rootfs_path}/tmp:/dev/shm \
    --mount=/dev/urandom:/dev/random \
    --mount=/proc/self/fd:/dev/fd \
    --mount=/proc/self/fd/0:/dev/stdin \
    --mount=/proc/self/fd/1:/dev/stdout \
    --mount=/proc/self/fd/2:/dev/stderr \
    --mount=/dev/null:/dev/tty0 \
    --mount=${proc_path}/Apline-fs/gitstatus:/root/.cache/gitstatus \
    --mount=/dev/null:/proc/sys/kernel/cap_last_cap \
    --mount=/storage/self/primary/Download:/media/sd \
    --mount=${proc_path}/Apline-fs/stat:/proc/stat \
    --mount=${proc_path}/Apline-fs/version:/proc/version \
    --mount=${proc_path}/Apline-fs/bus:/proc/bus \
    --mount=${proc_path}/Apline-fs/buddyinfo:/proc/buddyinfo \
    --mount=${proc_path}/Apline-fs/cgroups:/proc/cgroups \
    --mount=${proc_path}/Apline-fs/consoles:/proc/consoles \
    --mount=${proc_path}/Apline-fs/crypto:/proc/crypto \
    --mount=${proc_path}/Apline-fs/devices:/proc/devices \
    --mount=${proc_path}/Apline-fs/diskstats:/proc/diskstats \
    --mount=${proc_path}/Apline-fs/execdomains:/proc/execdomains \
    --mount=${proc_path}/Apline-fs/fb:/proc/fb \
    --mount=${proc_path}/Apline-fs/filesystems:/proc/filesystems \
    --mount=${proc_path}/Apline-fs/interrupts:/proc/interrupts \
    --mount=${proc_path}/Apline-fs/iomem:/proc/iomem \
    --mount=${proc_path}/Apline-fs/ioports:/proc/ioports \
    --mount=${proc_path}/Apline-fs/kallsyms:/proc/kallsyms \
    --mount=${proc_path}/Apline-fs/keys:/proc/keys \
    --mount=${proc_path}/Apline-fs/key-users:/proc/key-users \
    --mount=${proc_path}/Apline-fs/kpageflags:/proc/kpageflags \
    --mount=${proc_path}/Apline-fs/loadavg:/proc/loadavg \
    --mount=${proc_path}/Apline-fs/locks:/proc/locks \
    --mount=${proc_path}/Apline-fs/misc:/proc/misc \
    --mount=${proc_path}/Apline-fs/modules:/proc/modules \
    --mount=${proc_path}/Apline-fs/pagetypeinfo:/proc/pagetypeinfo \
    --mount=${proc_path}/Apline-fs/partitions:/proc/partitions \
    --mount=${proc_path}/Apline-fs/sched_debug:/proc/sched_debug \
    --mount=${proc_path}/Apline-fs/softirqs:/proc/softirqs \
    --mount=${proc_path}/Apline-fs/timer_list:/proc/timer_list \
    --mount=${proc_path}/Apline-fs/uptime:/proc/uptime \
    --mount=${proc_path}/Apline-fs/vmallocinfo:/proc/vmallocinfo \
    --mount=${proc_path}/Apline-fs/vmstat:/proc/vmstat \
    --mount=${proc_path}/Apline-fs/zoneinfo:/proc/zoneinfo \
    /usr/bin/env -i HOSTNAME=23049RAD8C HOME=/root USER=root TERM=xterm-256color SDL_IM_MODULE=fcitx XMODIFIERS=\@im=fcitx QT_IM_MODULE=fcitx GTK_IM_MODULE=fcitx TMOE_CHROOT=false TMOE_PROOT=true TMPDIR=/tmp DISPLAY=:2 PULSE_SERVER=tcp:127.0.0.1:4713 LANG=zh_CN.UTF-8 SHELL=/bin/ash PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games \
    /bin/ash -e "${cmd}"
}






_start_apline ${cmd}


