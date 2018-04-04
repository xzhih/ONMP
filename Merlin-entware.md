在梅林上使用Entware
===

Entware-ng是一个适用于嵌入式系统的软件包库，使用opkg包管理系统进行管理，现在在官方的源上已经有超过2000个软件包了，可以说是非常的丰富

官方地址：[Entware-ng](http://entware.net/about/)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [U盘格式化](#u%E7%9B%98%E6%A0%BC%E5%BC%8F%E5%8C%96)
- [U盘挂载](#u%E7%9B%98%E6%8C%82%E8%BD%BD)
- [安装和使用 Entware-ng](#%E5%AE%89%E8%A3%85%E5%92%8C%E4%BD%BF%E7%94%A8-entware-ng)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## U盘格式化

我们的设备本身的储存较少，而且如果哪天崩了，数据还有找不回的风险，所以我们一般把软件包和程序安装到U盘之类的外置设备上，所以需要对它格式化为ext4，NTFS格式不推荐使用

格式化教程：[如何格式化U盘](https://github.com/xzhih/ONMP/blob/master/format-partition.md)

## U盘挂载

分区、格式都没问题之后，开始挂载

```bash
~ mkdir /mnt/sda1
~ mount -t ext4 /dev/sda1 /mnt/sda1/
# 这样就挂载上了
~ df -h
Filesystem                Size      Used Available Use% Mounted on
/dev/sda1               975.5M      2.5M    906.6M   0% /tmp/mnt/sda1
# 可以看到已经挂载
```

## 安装和使用 Entware-ng

梅林内置了一个安装命令很方便

```bash
~ entware-setup.sh

# 然后会提示你选择哪个分区，就选择刚才挂载的那个
···省略
Info:  Looking for available partitions...
[1] --> /tmp/mnt/sda1
=>  Please enter partition number or 0 to exit
[0-1]: 1 # 选1回车
···省略
# 跑完之后只要不提示错误，就是安装成功了
```

经过以上步骤，已经可以从 `Entware-ng` 上进行下载安装包并安装到U盘上

这下可以享受丰富的软件包，还不占用内部储存空间

