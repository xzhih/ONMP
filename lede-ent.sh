#!/bin/sh
# sh -c "$(curl -ksSL http://192.168.4.126:4000/lede-ent.sh)"
export PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin$PATH

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
EOF

cd /tmp || exit

case $(uname -m) in
    *armv5*)
INST_URL="http://bin.entware.net/armv5sf-k3.2/installer/generic.sh"
;;
*armv7l*)
INST_URL="http://bin.entware.net/armv7sf-k3.2/installer/generic.sh"
;;
*aarch64*)
INST_URL="http://bin.entware.net/aarch64-k3.10/installer/generic.sh"
;;
*mips*)
INST_URL="http://bin.entware.net/mipselsf-k3.4/installer/generic.sh"
;;
x86_64)
INST_URL="http://bin.entware.net/x64-k3.2/installer/generic.sh"
;;
*)
echo "不好意思，你的平台似乎无法安装 Entware"
exit 1
;;
esac

echo -e "以下是你的磁盘信息\n"
df -h
echo -e "\n"

i=1
for mounted in $(mount | grep -E "ext4" | grep -v "overlay" | cut -d" " -f3) ; do
    echo "[$i] --> $mounted"
    eval mounts$i="$mounted"
    i=$((i + 1))
done

if [ $i = "1" ] ; then
    echo -e "找不到 Ext4 分区，正在退出..."
    exit 1
fi

echo -e "\n找到以上 Ext4 分区"
echo -en "输入分区序号或输入 0 退出 [0-$((i - 1))]: "
read -r partitionNumber
if [ "$partitionNumber" = "0" ] ; then
    echo -e "$INFO" 退出...
    exit 0
fi
if [ "$partitionNumber" -gt $((i - 1)) ] ; then
    echo -e "分区编号错误，正在退出..."
    exit 1
fi

eval entPartition=\$mounts"$partitionNumber"
echo -e "已选择 $entPartition \n"

entFolder="$entPartition/opt"

if [ -d "$entFolder" ] ; then
  echo -e "在这个分区上发现了旧的 Entware 文件，正在备份..."
  mv "$entFolder" "$entFolder-old_$(date +%F_%H-%M)"
  echo -e "已经备份到 $entFolder-old_$(date +%F_%H-%M) \n"
fi

mkdir "$entFolder"

if [ -d /opt ] ; then
    rm -rf /opt
fi

ln -sf "$entFolder" /opt
echo -e "新的软连接已创建\n"
echo -e "现在开始安装 Entware..."

wget -qO - $INST_URL | sh

startup="/etc/rc.d/entware-startup.sh"

echo "ln -sf "$entFolder" /opt" > $startup
echo "/opt/etc/init.d/rc.unslung start" >> $startup
chmod 777 /etc/rc.d/entware-startup.sh

sed -e "/^.\ \/opt\/etc\/profile/d" -i /etc/profile
echo ". /opt/etc/profile" >> /etc/profile
source /etc/profile

if [[ "$(which opkg)" == "/opt/bin/opkg" ]]; then
    echo -e "\n安装成功，重启查看是否生效\n"
fi
