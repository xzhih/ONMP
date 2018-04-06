如何格式化U盘
===

本教程适用于梅林、padavan、LEDE、openwrt等固件

以下具体方法都基于ext4，NTFS相关错误不做回答

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [安装fdisk](#%E5%AE%89%E8%A3%85fdisk)
- [查看你的设备](#%E6%9F%A5%E7%9C%8B%E4%BD%A0%E7%9A%84%E8%AE%BE%E5%A4%87)
- [删除分区、新建分区](#%E5%88%A0%E9%99%A4%E5%88%86%E5%8C%BA%E6%96%B0%E5%BB%BA%E5%88%86%E5%8C%BA)
- [格式化分区](#%E6%A0%BC%E5%BC%8F%E5%8C%96%E5%88%86%E5%8C%BA)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

使用ssh连接路由器，把U盘插到路由器上

我们需要在命令行进行以下4步操作：

## 安装fdisk

一般梅林固件都会自带的，不用安装

```bash
$ opkg update
$ opkg install fdisk
# 输出Configuring fdisk. 并且没有错误
# fdisk就安装好了
```

## 查看你的设备

```bash
$ fdisk -l 
# 这里先输出系统分区之类的不用管，外置设备一般在最后
Disk /dev/sda: 30.7 GB, 30752000000 bytes
64 heads, 32 sectors/track, 29327 cylinders
Units = cylinders of 2048 * 512 = 1048576 bytes
Device Boot      Start         End      Blocks  Id System
/dev/sda1               2       29327    30029824  83 Linux
```

上面的信息注意看到和你的存储大小一样的设备，我的是`/dev/sda`，在它里面有个`/dev/sda1`的分区

## 删除分区、新建分区

```
$ fdisk /dev/sda # 这是你的设备別打成分区

Welcome to fdisk (util-linux 2.29.2).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Command (m for help): d # 输入d回车，我只有一个分区，它自动选择了，如果你有多个分区，可以多次使用d
Selected partition 1
Partition 1 has been deleted.

Command (m for help): n # 输入n会车，创建分区
Partition type
p   primary (0 primary, 0 extended, 4 free)
e   extended (container for logical partitions)

Select (default p): p # 选择p
Partition number (1-4, default 1): # 回车
First sector (2048-2065023, default 2048): #回车
Last sector, +sectors or +size{K,M,G,T,P} (2048-2065023, default 2065023): # 回车
Created a new partition 1 of type 'Linux' and of size 1007.3 MiB.

Command (m for help): w # 输入w回车，保存并退出
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

经过以上的操作，你可以用`fdisk -l`命令查看U盘上是否只有一个Linux分区

```bash
$ fdisk -l 
# 找到你的设备 可以看到ID为83就对了
Disk /dev/sda: 30.7 GB, 30752000000 bytes
64 heads, 32 sectors/track, 29327 cylinders
Units = cylinders of 2048 * 512 = 1048576 bytes
Device Boot      Start         End      Blocks  Id System
/dev/sda1               2       29327    30029824  83 Linux
```

## 格式化分区

分区已经有了，现在开始格式化，其实现在的分区已经是ext4格式的了，不过我们还是对它进行一下格式化，算是熟悉一下命令，以后直接这样格式化吧

```bash 
$ mkfs.ext4 /dev/sda1 
# 如果你的硬盘比较大，256G以上的话，是这个命令：mkfs.ext4 -T largefile /dev/sda1
mke2fs 1.43.3 (04-Sep-2016)
/dev/sda1 contains a ext4 file system labelled 'ONMP'
last mounted on Sun Nov 12 09:21:22 2017
Proceed anyway? (y,n) y # 输入y回车

$ umount /dev/sda1 # 如果出错，可能是因为已经被挂载了，先执行这个卸载
```

这样，U盘就被格式化完了
