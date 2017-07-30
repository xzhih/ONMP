#!/bin/sh
## @Author: triton
# @Date:   2017-07-29 06:10:54
# @Last Modified by:   xuzhihao
# @Last Modified time: 2017-07-30 16:25:21

#软件包列表
pkglist="wget unzip php7 php7-mod-gd php7-mod-session php7-mod-pdo php7-mod-pdo-mysql php7-mod-mysqli php7-mod-mcrypt php7-mod-mbstring php7-fastcgi php7-cgi php7-mod-xml php7-mod-ctype php7-mod-curl php7-mod-exif php7-mod-ftp php7-mod-iconv php7-mod-json php7-mod-sockets php7-mod-sqlite3 php7-mod-tokenizer php7-mod-zip nginx spawn-fcgi zoneinfo-core zoneinfo-asia shadow-groupadd shadow-useradd mariadb-server mariadb-client mariadb-client-extra"
localhost=$(grep `hostname` /etc/hosts | awk '{print $1}')
install_check()
{
    notinstall=""
    for data in $pkglist ; do
        if [ `opkg list-installed | grep $data |wc -l` -ne 0 ];then
            echo "$data 已安装"
        else
            notinstall="$notinstall $data"
            echo "$data 正在安装..."
            opkg install $data
        fi
    done
}
# 安装软件包
install_onmp_ipk()
{
    opkg update
    opkg upgrade
    install_check
    if [[ ${#notinstall} -gt 0 ]]; then
        install_check
    fi
    if [[ ${#notinstall} -gt 0 ]]; then
        install_check
    fi
    if [[ ${#notinstall} -gt 0 ]]; then
        echo "可能会因为网络问题某些软件包无法安装，请挂全局VPN再次运行命令"
    else
        echo "----------------------------------------"
        echo "|********** ONMP软件包已完整安装 *********|"
        echo "----------------------------------------"
        echo "现在开始初始化ONMP"
        init_onmp
        echo ""
    fi
}

#初始化onmp
init_onmp()
{
    # 网站目录
    rm -rf /opt/wwwroot
    mkdir -p /opt/wwwroot
    mkdir -p /opt/wwwroot/default

# NGINX设置
killall -9 nginx
rm -rf /opt/etc/nginx/vhost 
rm -rf /opt/etc/nginx/conf
mkdir -p /opt/etc/nginx/vhost
mkdir -p /opt/etc/nginx/conf

cat > "/opt/etc/nginx/nginx.conf" <<-\EOF
user  www www;
pid /opt/var/run/nginx.pid;
worker_processes auto;
worker_rlimit_nofile 51200;
events {
    worker_connections  256;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    server_names_hash_bucket_size 128;
    client_header_buffer_size 32k;
    large_client_header_buffers 4 32k;
    client_max_body_size 50m;
    sendfile   on;
    tcp_nopush on;
    keepalive_timeout 60;
    tcp_nodelay on;
    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    fastcgi_buffer_size 64k;
    fastcgi_buffers 4 64k;
    fastcgi_busy_buffers_size 128k;
    fastcgi_temp_file_write_size 256k;
    gzip on;
    gzip_min_length  1k;
    gzip_buffers     4 16k;
    gzip_http_version 1.1;
    gzip_comp_level 2;
    gzip_types     text/plain application/javascript application/x-javascript text/javascript text/css application/xml application/xml+rss;
    gzip_vary on;
    gzip_proxied   expired no-cache no-store private auth;
    gzip_disable   "MSIE [1-6]\.";
    server_tokens off;
    include /opt/etc/nginx/vhost/*.conf;
}
EOF
cat > "/opt/etc/nginx/php-fpm" <<-\EEE
location ~ \.php$ {
    try_files                   $uri = 404;
    fastcgi_pass                127.0.0.1:9000;
    fastcgi_index               index.php;
    fastcgi_intercept_errors    on;
    fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
    fastcgi_param  QUERY_STRING       $query_string;
    fastcgi_param  REQUEST_METHOD     $request_method;
    fastcgi_param  CONTENT_TYPE       $content_type;
    fastcgi_param  CONTENT_LENGTH     $content_length;
    fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
    fastcgi_param  REQUEST_URI        $request_uri;
    fastcgi_param  DOCUMENT_URI       $document_uri;
    fastcgi_param  DOCUMENT_ROOT      $document_root;
    fastcgi_param  SERVER_PROTOCOL    $server_protocol;
    fastcgi_param  REQUEST_SCHEME     $scheme;
    fastcgi_param  HTTPS              $https if_not_empty;
    fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
    fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;
    fastcgi_param  REMOTE_ADDR        $remote_addr;
    fastcgi_param  REMOTE_PORT        $remote_port;
    fastcgi_param  SERVER_ADDR        $server_addr;
    fastcgi_param  SERVER_PORT        $server_port;
    fastcgi_param  SERVER_NAME        $server_name;
    fastcgi_param  REDIRECT_STATUS    200;
}
EEE
cat > "/opt/etc/nginx/conf/wordpress.conf" <<-\OOO
location / {
    try_files $uri $uri/ /index.php?$args;
}
rewrite /wp-admin$ $scheme://$host$uri/ permanent;
OOO
    # 添加探针
    cp /opt/ONMP-master/default /opt/wwwroot/ -R
    chown -R www:www /opt/wwwroot/default
    add_vhost 81 default

    # MySQL设置
    reset_sql

    # PHP7设置 
    if [ `ps | grep php-cgi |wc -l` -ne 1 ];then
        killall -9 php-cgi
    fi
    sed -e "/^doc_root/d" -i /opt/etc/php.ini

    # 生成ONMP命令
    set_onmp_sh
    echo "onmp正在启动"
    /opt/etc/init.d/Sonmp restart >/dev/null 2>&1
    echo "onmp已运行"
    echo "浏览器地址栏输入：$localhost:81 查看php探针"
}

# 重置数据库
reset_sql()
{
    killall mysqld
    killall -9 mysqld
    rm -rf /opt/mysql
    rm -rf /opt/var/mysql
    sed -e "s/.*user.*/user        = admin/g" -i /opt/etc/mysql/my.cnf
    sed -e "s/^pid-file.*/socket      = \/opt\/tmp\/mysql\.sock/g" -i /opt/etc/mysql/my.cnf
    mkdir -p /opt/mysql/
    /opt/bin/mysql_install_db 1>/dev/null
    /opt/bin/mysqld &
    if [ `ps | grep mysqld |wc -l` -ne 2 ];then
        /opt/bin/mysqld &
    fi
    sleep 2
    echo -e "\n正在初始化数据库，请稍等"
    sleep 10
    mysqladmin -u root password 123456 1>/dev/null
    killall mysqld
    killall -9 mysqld
    echo -e "\033[41;37m 数据库用户：root, 初始密码：123456 \033[0m"
}

# 卸载onmp
remove_onmp()
{
    killall -9 nginx mysqld php-cgi
    for data in $pkglist; do
        opkg remove $data --force-depends
    done
    rm -rf /opt/wwwroot
    rm -rf /opt/etc/nginx/vhost
    rm -rf /opt/bin/onmp
    rm -rf /opt/mysql
    rm -rf /opt/var/mysql
    rm -rf /opt/etc/php.ini
    rm -rf /opt/etc/nginx/
    rm -rf /opt/etc/php*
    rm -rf /opt/etc/mysql
}

# 生成ONMP命令
set_onmp_sh()
{
# 删除onmp
rm -rf /opt/bin/onmp
cat > "/opt/bin/onmp" <<-\EOF
#!/bin/sh
localhost=$(grep `hostname` /etc/hosts | awk '{print $1}')
vhost_list()
{
    echo "网站列表："
    logger -t "【ONMP】" "网站列表："
    for conf in /opt/etc/nginx/vhost/*;
    do
        path=$(cat $conf | awk 'NR==4' | awk '{print $2}' | sed 's/;//')
        port=$(cat $conf | awk 'NR==2' | awk '{print $2}' | sed 's/;//')
        echo "$path        $localhost:$port"
        logger -t "【ONMP】" "$path     $localhost:$port"
    done
}
case $1 in
    start )
    echo "onmp正在启动"
    logger -t "【ONMP】" "正在启动"
    killall -9 nginx mysqld php-cgi  >/dev/null 2>&1
    sleep 2
    /opt/bin/mysqld &
    sleep 2
    /opt/bin/spawn-fcgi -a 127.0.0.1 -p 9000 -C 2 -f /opt/bin/php-cgi  >/dev/null 2>&1
    sleep 2
    nginx
    echo "onmp已启动"
    logger -t "【ONMP】" "已启动"
    vhost_list
    ;;

    stop )
    echo "onmp正在停止"
    logger -t "【ONMP】" "正在停止"
    killall -9 nginx mysqld php-cgi
    echo "onmp已停止"
    logger -t "【ONMP】" "已停止"
    ;;

    restart )
    echo "onmp正在重启"
    logger -t "【ONMP】" "正在重启"
    killall -9 nginx mysqld php-cgi  >/dev/null 2>&1
    sleep 2
    /opt/bin/mysqld &
    sleep 2
    /opt/bin/spawn-fcgi -a 127.0.0.1 -p 9000 -C 2 -f /opt/bin/php-cgi  >/dev/null 2>&1
    sleep 2
    nginx
    echo "onmp已经重启"
    logger -t "【ONMP】" "已重启"
    vhost_list
    ;;
    list )
    vhost_list
    ;;
    * )
    echo "----------------------------------------"
    echo "|****  请用以下命令启动 停止 重启ONMP  ****|"
    echo "|*****  onmp start|stop|restart   *****|"
    echo "|*******  查看网站列表 onmp list  *******|"
    echo "----------------------------------------"
    ;;
esac
EOF
cat > "/opt/etc/init.d/Sonmp" <<-\MMM
#!/bin/sh
#onmp web环境
onmp_start()
{
    groupadd www
    useradd -g www www
    chown -R www:www /opt/wwwroot
    onmp start
}
onmp_stop()
{
    onmp stop
}
onmp_restart()
{
    onmp restart
}
case "$1" in
    start)
    onmp_start
    ;;
    stop)
    onmp_stop
    ;;
    restart)
    onmp_restart
    ;;
    *)
    onmp
    exit 1
    ;;
esac
MMM
chmod +x /opt/bin/onmp
chmod +x /opt/etc/init.d/Sonmp
echo "----------------------------------------"
echo "|**********  onmp命令已经生成  **********|"
echo "|****  请用以下命令启动 停止 重启ONMP  ****|"
echo "|*****  onmp start|stop|restart   *****|"
echo "----------------------------------------"
}

# 网站程序安装
install_website()
{
    clear
# 选择程序
cat << AAA
----------------------------------------
|************* 选择WEB程序 *************|
----------------------------------------
(1) phpMyAdmin（数据库管理工具）
(2) WordPress（使用最广泛的CMS）

AAA
read -p "输入你的选择[1-2]: " input
case $input in
    1) install_phpmyadmin;;
2) install_wordpress;;
*) echo "你输入的数字不是 1 到 2 之间的!"
break;;
esac
}

# 安装phpMyAdmin
install_phpmyadmin()
{
    if [ ! -d "/opt/wwwroot/phpmyadmin/libraries" ] ; then
        rm -rf /opt/etc/nginx/vhost/phpmyadmin.conf
        if [[ ! -f /opt/wwwroot/phpmyadmin.zip ]]; then
            wget --no-check-certificate -O /opt/wwwroot/phpmyadmin.zip https://files.phpmyadmin.net/phpMyAdmin/4.7.3/phpMyAdmin-4.7.3-all-languages.zip
        fi
        echo "正在解压..."
        unzip /opt/wwwroot/phpmyadmin.zip -d /opt/wwwroot/ >/dev/null 2>&1
        echo "解压完成..."
        mv /opt/wwwroot/phpMyAdmin* /opt/wwwroot/phpmyadmin
    fi
    if [ ! -d "/opt/wwwroot/phpmyadmin/libraries" ] ; then
        echo "安装未成功"
    else
        chown -R www:www /opt/wwwroot
        add_vhost 82 phpmyadmin
        echo "正在配置phpmyadmin..."
        cp /opt/wwwroot/phpmyadmin/config.sample.inc.php /opt/wwwroot/phpmyadmin/config.inc.php
        sed -e "s/.*blowfish_secret.*/\$cfg['blowfish_secret'] = 'onmponmponmponmponmponmponmponmp';/g" -i /opt/wwwroot/phpmyadmin/config.inc.php
        chmod 644 /opt/wwwroot/phpmyadmin/config.inc.php
        onmp restart >/dev/null 2>&1
        echo "phpMyaAdmin安装完成"
        echo "浏览器地址栏输入：$localhost:82 即可访问"
    fi
}

# 安装WordPress
install_wordpress()
{
    clear
    echo "----------------------------------------"
    echo "|*********  WordPress安装程序  *********|"
    echo "----------------------------------------"
    read -p "输入服务端口（请避开已使用的端口）: " port
    read -p "输入网站目录名（如：wordpress）: " webdir
    if [ ! -d "/opt/wwwroot/$webdir" ] ; then
        echo "开始安装..."
    else
        read -p "网站目录 /opt/wwwroot/$webdir 已存在，是否删除: [y/n(小写)]" ans
        case $ans in
            y ) 
rm -rf /opt/wwwroot/$webdir 
echo "已删除";;
n ) echo "未删除";;
* ) echo "没有这个选项" ;;
esac
fi
if [ ! -d "/opt/wwwroot/$webdir" ] ; then
    rm -rf /opt/etc/nginx/vhost/$webdir.conf
    if [[ ! -f /opt/wwwroot/wordpress.zip ]]; then
        wget --no-check-certificate -O /opt/wwwroot/wordpress.zip https://cn.wordpress.org/wordpress-4.8-zh_CN.zip
    fi
    echo "正在解压..."
    unzip /opt/wwwroot/wordpress.zip -d /opt/wwwroot/ >/dev/null 2>&1
    mv /opt/wwwroot/wordpress /opt/wwwroot/$webdir
    echo "解压完成..."
fi
if [ ! -d "/opt/wwwroot/$webdir" ] ; then
    echo "安装未成功"
else
    echo "正在配置WordPress..."
    echo "define("FS_METHOD","direct");" >> /opt/wwwroot/$webdir/wp-config-sample.php
    echo "define("FS_CHMOD_DIR", 0777);" >> /opt/wwwroot/$webdir/wp-config-sample.php
    echo "define("FS_CHMOD_FILE", 0777);" >> /opt/wwwroot/$webdir/wp-config-sample.php
    chown -R www:www /opt/wwwroot
    add_vhost $port $webdir
    sed -e "s/.*\#otherconf.*/        include     \/opt\/etc\/nginx\/conf\/wordpress.conf\;/g" -i /opt/etc/nginx/vhost/wwwwwww.conf
    onmp restart >/dev/null 2>&1
    echo "WordPress安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
fi
}

# 添加网站
add_vhost()
{
# 
cat > "/opt/etc/nginx/vhost/$2.conf" <<-\EOF
server {
    listen 81;
    server_name  localhost;
    root  /opt/wwwroot/www/;
    index index.html index.htm index.php default.php tz.php;
    location / {
        autoindex   on;
        include     /opt/etc/nginx/php-fpm;
        #otherconf
    }
}
EOF
sed -e "s/.*listen.*/    listen $1\;/g" -i /opt/etc/nginx/vhost/$2.conf
sed -e "s/.*\/opt\/wwwroot\/www\/.*/    root  \/opt\/wwwroot\/$2\/\;/g" -i /opt/etc/nginx/vhost/$2.conf
}

# 脚本开始
start()
{
# 输出选项
cat << EOF
----------------------------------------
|**************** ONMP ****************|
----------------------------------------
(1) 安装ONMP
(2) 卸载ONMP
(3) 重做onmp命令
(4) 重置数据库
(5) 全部重置（会删除网站目录，请注意备份）
(6) 安装网站程序
(7) 查看网站列表
(0) 退出

EOF
read -p "输入你的选择[0-6]: " input
case $input in
    1) install_onmp_ipk
;;
2) remove_onmp
;;
3) set_onmp_sh
;;
4) reset_sql
;;
5) init_onmp
;;
6) install_website
;;
7) onmp list
;;
0) break
;;
*) echo "你输入的数字不是 0 到 6 之间的!"
break
;;
esac 
}

start