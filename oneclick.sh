#!/bin/sh
# 一键安装onmp

rm -rf /opt/bin/onmp /opt/onmp
mkdir -p /opt/onmp

# 获取onmp脚本
curl -lsSl https://raw.githubusercontent.com/xzhih/ONMP/master/onmp.sh > /opt/onmp/onmp.sh
chmod +x /opt/onmp/onmp.sh

# 获取php探针文件
curl -lsSl https://raw.githubusercontent.com/xzhih/ONMP/master/tz.php > /opt/onmp/tz.php

/opt/onmp/onmp.sh