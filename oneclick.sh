#!/bin/sh
# 一键安装onmp
# @Author: xzhih
# @Date:   2018-03-19 04:44:09
# @Last Modified by:   xzhih
# @Last Modified time: 2018-04-06 18:07:44

cat << EOF
----------------------------------------
|**************** ONMP ****************|
----------------------------------------
ONMP 是一个 web 环境快速安装脚本，适用于安装了
Entware 的路由器，目前已经在 Padavan、
LEDE（openwrt）、梅林上测试成功。

项目地址：https://github.com/xzhih/ONMP

更多使用教程：https://zhih.me

QQ交流群：346477750

EOF

install()
{

    rm -rf /opt/bin/onmp /opt/onmp
    mkdir -p /opt/onmp

    # 获取onmp脚本
    curl -kfsSL https://raw.githubusercontent.com/xzhih/ONMP/master/onmp.sh > /opt/onmp/onmp.sh
    # curl -kfsSL http://localhost/onmp.sh > /opt/onmp/onmp.sh
    chmod +x /opt/onmp/onmp.sh

    # 获取php探针文件
    curl -kfsSL https://raw.githubusercontent.com/xzhih/ONMP/master/tz.php > /opt/onmp/tz.php

    /opt/onmp/onmp.sh

}

install