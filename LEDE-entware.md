在LEDE上使用entware
==================

之前给老毛子padavan固件写了[onmp一键包](http://www.right.com.cn/forum/thread-244810-1-1.html)，有不少使用LEDE软路由的小伙伴回帖说不能安装，所以我决定修改脚本进行适配，LEDE的opkg源内似乎没有我需要的包，所以转投使用Entware

Eenware-ng是一个适用于嵌入式系统的软件包库，使用opkg包管理系统进行管理，现在在官方的源上已经有超过2000个软件包了，可以说是非常的丰富
官方地址：[Entware-ng](http://entware.net/about/)

### U盘格式化（可选）

我们的设备本身的储存较少，而且如果哪天崩了，数据还有找不回的风险，所以我们一般把软件包和程序安装到U盘之类的外置设备上，所以需要对它进行格式化，NTFS格式我个人不推荐使用，以下具体方法都基于ext4，NTFS相关错误不做回答

使用ssh连接路由器shell，把U盘插到路由器上

我们需要在命令行进行以下4步操作：

**1**. 安装fdisk

```shell
root@LEDE:~ opkg update
root@LEDE:~ opkg install 
# 输出Configuring fdisk. 并且没有错误
# fdisk就安装好了
```

**2**. 查看你的设备

```shell
root@LEDE:~ fdisk -l 
# 这里先输出系统分区之类的不用管，外置设备一般在最后
Disk /dev/sdb: 1008.3 MiB, 1057292288 bytes, 2065024 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x7a0d6aa3
Device     Boot Start     End Sectors    Size Id Type
/dev/sdb1        2048 2065023 2062976 1007.3M  7 HPFS/NTFS/exFAT
```

上面的信息注意看到和你的存储大小一样的设备，我的是`/dev/sdb`，在它里面有个`/dev/sdb1`的分区

**3**. 删除分区、新建分区

```
root@LEDE:~ fdisk /dev/sdb # 这是你的设备別打成分区

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
root@LEDE:~
```

经过以上的操作，你可以用`fdisk -l`命令查看U盘上是否只有一个Linux分区

```shell
root@LEDE:~ fdisk -l 

# 找到你的设备 可以看到ID为83就对了
Disk /dev/sdb: 1008.3 MiB, 1057292288 bytes, 2065024 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x7a0d6aa3
Device     Boot Start     End Sectors    Size Id Type
/dev/sdb1        2048 2065023 2062976 1007.3M 83 Linux
```

**4**. 格式化分区

分区已经有了，现在开始格式化，其实现在的分区已经是ext4格式的了，不过我们还是对它进行一下格式化，算是熟悉一下命令，以后直接这样格式化吧

```shell 
root@LEDE:~ mkfs.ext4 /dev/sdb1 
# 如果你的硬盘比较大，256G以上的话，是这个命令：mkfs.ext4 -T largefile /dev/sdb1
mke2fs 1.43.3 (04-Sep-2016)
/dev/sdb1 contains a ext4 file system labelled 'ONMP'
        last mounted on Sun Nov 12 09:21:22 2017
Proceed anyway? (y,n) y # 输入y回车

root@LEDE:~ umount /dev/sdb1 # 如果已经被挂载了，先执行这个卸载
```

这样，U盘就被格式化完了

### U盘挂载

分区、格式都没问题之后，开始挂载

```shell
root@LEDE:~ mkdir /mnt/onmp
# 挂载方法1
root@LEDE:~ mount -t ext4 /dev/sdb1 /mnt/onmp/
# 这样就挂载上了
root@LEDE:~ df -h
Filesystem                Size      Used Available Use% Mounted on
/dev/sdb1               975.5M      2.5M    906.6M   0% /mnt/onmp
# 可以看到已经挂载

# 挂载方法2（推荐）
root@LEDE:~ vi /etc/fstab # 按一下i编辑文件
# <file system> <mount point> <type> <options> <dump> <pass>
/dev/sdb1 /mnt/onmp ext4 defaults 0 1 # 添加这一行
# 按一下Esc再输入冒号`:`，输入wq回车保存
root@LEDE:~ mount -a # 以后每次要挂载就直接输入这个命令
```

开机自动挂载

```shell
root@LEDE:~ vi /etc/rc.local # 编辑，vim基本用法和上面一样
mount -a # 在exit 0之前添加命令，开机后自动执行挂载
exit 0
```

### 安装和使用 Entware-ng

**1**. 挂载opt

在U盘上创建一个空的opt文件夹

``` shell
root@LEDE:~ mkdir /mnt/onmp/opt
```

在系统根目录创建opt文件夹，并绑定U盘的opt文件夹

```shell
root@LEDE:~ mkdir /opt
root@LEDE:~ mount -o bind /mnt/onmp/opt /opt
# 可以用 mount 或 df -h 命令查看是否挂载成功
```

**2**. 运行 Entware-ng 安装命令

不同的CPU平台有不同的命令

- armv5

```shell
wget -O - http://pkg.entware.net/binaries/armv5/installer/entware_install.sh | /bin/sh
```

- armv7

```shell
wget -O - http://pkg.entware.net/binaries/armv7/installer/entware_install.sh | /bin/sh
```

- x86-32

```shell
wget -O - http://pkg.entware.net/binaries/x86-32/installer/entware_install.sh | /bin/sh
```

- x86-64

```shell
wget -O - http://pkg.entware.net/binaries/x86-64/installer/entware_install.sh | /bin/sh
```

- MIPS

```shell
wget -O - http://pkg.entware.net/binaries/mipsel/installer/installer.sh | /bin/sh
```

在输入命令之后之后会自己跑起来，出现以下结果就代表成功，没成功的记得把U盘上的opt文件夹清空再来

```shell
Info: Congratulations!
Info: If there are no errors above then Entware-ng was successfully initialized.
```

**3**. 开机启动

编辑 `/etc/rc.local` 将以下代码加在 `exit 0` 之前，`mount -a` 之后

```shell
mkdir -p /opt
mount -o bind /mnt/onmp/opt /opt
/opt/etc/init.d/rc.unslung start
```

**4**. 环境变量

编辑 `/etc/profile` 在他的最后加入以下代码

```shell
. /opt/etc/profile
```

这样开机之后将会添加 `/opt/bin` 和 `/opt/sbin` 到环境变量PATH里

**5**. 重启

重启之后，可以使用一下命令检查是否成功

```shell
# 检查环境变量
root@LEDE:~ echo $PATH
/opt/bin:/opt/sbin:/usr/sbin:/usr/bin:/sbin:/bin # 可以看到已经有/opt的路径了

# 检查 `/opt` 挂载情况
root@LEDE:~# df -h
/dev/sdb1               975.5M     13.9M    895.2M   2% /mnt/onmp # U盘挂载成功
/dev/sdb1               975.5M     13.9M    895.2M   2% /opt # opt挂载成功

# opkg 更新数据
root@LEDE:~# opkg update
Downloading http://pkg.entware.net/binaries/x86-64/Packages.gz # 默认从entware下载
Updated list of available packages in /opt/var/opkg-lists/packages # 成功
```

经过以上步骤，已经可以从 `Entware-ng` 上进行下载安装包并安装到U盘上

这下可以享受丰富的软件包，还不占用内部储存空间，非常适合LEDE软路由
我的onmp一键包也可以在LEDE上使用了

### Tips

每次升级固件后如果失效了，重新设置开机启动和环境变量即可

**参考**

[Install on Synology NAS](https://github.com/Entware-ng/Entware-ng/wiki/Install-on-Synology-NAS)

[How To Configure Routers Asus RT-N56U/RT-N65U For Entware Usage](https://bitbucket.org/padavan/rt-n56u/wiki/EN/HowToConfigureEntware)

