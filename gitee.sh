#字体颜色
red="\e[31;1m"      #红
green="\e[32;1m"   #绿
yellow="\e[33;1m"  #黄
blue="\e[34;1m"    #蓝
purple="\e[35;1m"    #紫红
cyanine="\e[36;1m"    #青
white="\e[0m"

# 测试123
#bash -n /data/data/com.termux/files/home/hzt/op.sh
#[ ! "$?" == "0" ]&&echo -e "\n\n$red检查到op.sh有语法错误，停止上传!$white"&&exit


msg() { echo -e "\n$blue[*]$white$1$2$white" ;:;}  ##自定义通告颜色

msg $green 'git config --global user.name "WindowHZT"'
git config --global user.name "WindowHZT"

msg $green 'git config --global user.email "2028741073@qq.com"'
git config --global user.email "2028741073@qq.com"

#mkdir termux-ubuntu2004
#cd ~/termux-ubuntu2004 ;find ~/termux-ubuntu2004/ -name "*.bak" |xargs rm -f
#cd ~/hzt ;find ~/hzt/ -name "*.bak" |xargs rm -f
cd ~/linux-tools/ ;find ~/linux-tools/ -name "*.bak" |xargs rm -f


msg $green 'git init '
git init
#git pull --rebase origin master

msg $green 'git remote add origin https://gitee.com/djyd/termux-ubuntu2004.git'
git remote add origin https://gitee.com/djyd/linux-tools.git
#git pull origin master

msg $green 'git pull origin master'
git pull origin master
#git pull 
#git fetch

msg $green 'git add .'
git add .

msg $green 'git status'
git status



msg $green 'git commit -m "使用git提交 gitee" '
git commit -m 'git gitee' 
#git config --global user.name "djyd"

msg $green 'git push '
#git push 
#git push 
git push --set-upstream origin master #<<"账号\n密码"
##git config credential.helper store  # 执行一次，之后只需要输入一次密码，再也不需要了