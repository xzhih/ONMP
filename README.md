ONMP
===

适用于安装了Entware固件的onmp一键安装命令

目前已经在Padavan、LEDE上测试成功

## 说明

ONMP: Opkg + Nginx + MySQL + PHP

这是一个用Linux Shell编写的脚本，可以为使用opkg包管理的路由器快速搭建Nginx/MySQL/PHP环境，并且内置了一些好用的网站程序一键免配置快速安装

```
ONMP内置了以下程序的一键安装：
(1) phpMyAdmin（数据库管理工具）
(2) WordPress（使用最广泛的CMS）
(3) Owncloud（经典的私有云）
(4) Nextcloud（Owncloud团队的新作，美观强大的个人云盘）
(5) h5ai（优秀的文件目录）
(6) Lychee（一个很好看，易于使用的Web相册）
(7) Kodexplorer（可道云aka芒果云在线文档管理器）
(8) Netdata（详细得惊人的服务器监控面板）
```

所有的软件包均通过opkg安装，一切配置均在脚本中可见，请放心使用

## 使用说明

[在LEDE上使用Entware](https://github.com/xzhih/ONMP/blob/master/LEDE-entware.md)

本脚本使用教程发布在恩山无线论坛
传送门：[Padavan固件一键安装onmp](http://www.right.com.cn/forum/thread-244810-1-1.html)