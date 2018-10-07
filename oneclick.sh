#!/bin/sh
# 一键安装onmp
# @Author: xzhih
# @Date:   2018-03-19 04:44:09
# @Last Modified by:   xzhih
# @Last Modified time: 2018-10-08 01:51:35
# sh -c "$(curl -kfsSL http://192.168.4.126:4000/oneclick.sh)"

cat << EOF
      ___           ___           ___           ___    
     /  /\         /__/\         /__/\         /  /\   
    /  /::\        \  \:\       |  |::\       /  /::\  
   /  /:/\:\        \  \:\      |  |:|:\     /  /:/\:\ 
  /  /:/  \:\   _____\__\:\   __|__|:|\:\   /  /:/~/:/ 
 /__/:/ \__\:\ /__/::::::::\ /__/::::| \:\ /__/:/ /:/  
 \  \:\ /  /:/ \  \:\~~\~~\/ \  \:\~~\__\/ \  \:\/:/   
  \  \:\  /:/   \  \:\  ~~~   \  \:\        \  \::/    
   \  \:\/:/     \  \:\        \  \:\        \  \:\    
    \  \::/       \  \:\        \  \:\        \  \:\   
     \__\/         \__\/         \__\/         \__\/   

=======================================================

ONMP 是一个 web 环境快速安装脚本，适用于安装了
Entware 的路由器，目前已经在 Padavan、
LEDE（openwrt）、梅林上测试成功。

项目地址：https://github.com/xzhih/ONMP

更多使用教程：https://zhih.me

EOF

Install()
{
	rm -rf /opt/bin/onmp /opt/onmp
	mkdir -p /opt/onmp

    # 获取onmp脚本
    curl -kfsSL https://raw.githubusercontent.com/xzhih/ONMP/master/onmp.sh > /opt/onmp/onmp.sh
    # curl -kfsSL http://192.168.4.126:4000/onmp.sh > /opt/onmp/onmp.sh
    chmod +x /opt/onmp/onmp.sh

    # 获取php探针文件
    curl -kfsSL https://raw.githubusercontent.com/WuSiYu/PHP-Probe/master/tz.php > /opt/onmp/tz.php

    /opt/onmp/onmp.sh
}

Updata()
{
	rm -rf /opt/onmp/onmp.sh
	curl -kfsSL https://raw.githubusercontent.com/xzhih/ONMP/master/onmp.sh > /opt/onmp/onmp.sh
	# curl -kfsSL http://192.168.4.126:4000/onmp.sh > /opt/onmp/onmp.sh
	chmod +x /opt/onmp/onmp.sh
	/opt/onmp/onmp.sh renewsh > /dev/null 2>&1
	echo "升级完成"
}

start()
{
#
cat << EOF
(1) 开始安装
(2) 升级脚本
EOF

read -p "请输入：" input
case $input in
	1 ) Install;;
2) Updata;;
*) exit;;
esac

}

start