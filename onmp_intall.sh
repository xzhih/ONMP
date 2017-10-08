#!/bin/sh
## @Author: triton
# @Date:   2017-07-29 06:10:54
# @Last Modified by:   triton2
# @Last Modified time: 2017-10-08 16:21:00

#软件包列表
pkglist="unzip php7 php7-cgi php7-cli php7-fastcgi php7-fpm php7-mod-calendar php7-mod-ctype php7-mod-curl php7-mod-dom php7-mod-exif php7-mod-fileinfo php7-mod-ftp php7-mod-gd php7-mod-gettext php7-mod-gmp php7-mod-hash php7-mod-iconv php7-mod-intl php7-mod-json php7-mod-ldap php7-mod-session php7-mod-mbstring  php7-mod-mcrypt  php7-mod-mysqli php7-mod-opcache php7-mod-openssl php7-mod-pdo php7-mod-pcntl php7-mod-pdo-mysql php7-mod-phar php7-mod-session php7-mod-shmop php7-mod-simplexml php7-mod-soap php7-mod-sockets php7-mod-sqlite3 php7-mod-sysvmsg php7-mod-sysvsem php7-mod-sysvshm php7-mod-tokenizer php7-mod-xml php7-mod-xmlreader php7-mod-xmlwriter php7-mod-zip php7-pecl-dio php7-pecl-http php7-pecl-libevent php7-pecl-propro php7-pecl-raphf nginx zoneinfo-core zoneinfo-asia shadow-groupadd shadow-useradd libmariadb mariadb-server mariadb-client mariadb-client-extra"
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
mkdir -p /opt/wwwroot/default

# NGINX设置
killall -9 nginx
rm -rf /opt/etc/nginx/vhost 
rm -rf /opt/etc/nginx/conf
mkdir -p /opt/etc/nginx/vhost
mkdir -p /opt/etc/nginx/conf

cat > "/opt/etc/nginx/nginx.conf" <<-\EOF
user  theOne root;
pid /opt/var/run/nginx.pid;
worker_processes auto;
worker_rlimit_nofile 51200;
events {
    worker_connections  256;
}
http {
    sendfile                        on;
    tcp_nopush                      on;
    tcp_nodelay                     on;
    default_type                    application/octet-stream;
    server_tokens                   off;
    keepalive_timeout               60;
    client_max_body_size            50m;
    client_header_buffer_size       32k;
    large_client_header_buffers     4 32k;
    server_names_hash_bucket_size   128;
    gzip                            on;
    gzip_vary                       on;
    gzip_proxied                    expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types                      application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;
    gzip_disable                    "MSIE [1-6]\.";
    gzip_buffers                    4 16k;
    gzip_comp_level                 4;
    gzip_min_length                 1k;
    gzip_http_version               1.1;
    fastcgi_buffers                 4 64k;
    fastcgi_buffer_size             64k;
    fastcgi_send_timeout            300;
    fastcgi_read_timeout            300;
    fastcgi_connect_timeout         300;
    fastcgi_busy_buffers_size       128k;
    fastcgi_temp_file_write_size    256k;
    include                         mime.types;
    include                         /opt/etc/nginx/vhost/*.conf;
}
EOF

sed -e "s/theOne/$USER/g" -i /opt/etc/nginx/nginx.conf

# 特定程序的nginx配置
cat > "/opt/etc/nginx/conf/nextcloud.conf" <<-\OOO
location = /.well-known/carddav {
  return 301 $scheme://$host/remote.php/dav;
}
location = /.well-known/caldav {
  return 301 $scheme://$host/remote.php/dav;
}
location / {
    rewrite ^ /index.php$uri;
}
location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
    deny all;
}
location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
    deny all;
}
location ~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+)\.php(?:$|/) {
    fastcgi_split_path_info ^(.+\.php)(/.*)$;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param PATH_INFO $fastcgi_path_info;
    #Avoid sending the security headers twice
    fastcgi_param modHeadersAvailable true;
    fastcgi_param front_controller_active true;
    fastcgi_pass unix:/opt/var/run/php7-fpm.sock;
    fastcgi_intercept_errors on;
    fastcgi_request_buffering off;
}
location ~ ^/(?:updater|ocs-provider)(?:$|/) {
    try_files $uri/ =404;
    index index.php;
}
location ~ \.(?:css|js|woff|svg|gif)$ {
    try_files $uri /index.php$uri$is_args$args;
    add_header Cache-Control "public, max-age=15778463";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Download-Options noopen;
    add_header X-Permitted-Cross-Domain-Policies none;
    # Optional: Don't log access to assets
    access_log off;
}
location ~ \.(?:png|html|ttf|ico|jpg|jpeg)$ {
    try_files $uri /index.php$uri$is_args$args;
    # Optional: Don't log access to other assets
    access_log off;
}
OOO
cat > "/opt/etc/nginx/conf/wordpress.conf" <<-\OOO
location / {
    try_files $uri $uri/ /index.php?$args;
}
rewrite /wp-admin$ $scheme://$host$uri/ permanent;
OOO

    # 添加探针
    cp /opt/ONMP-master/default /opt/wwwroot/ -R
    add_vhost 81 default

# MySQL设置
cat > "/opt/etc/mysql/my.cnf" <<-\MMM
[client-server]
port                            = 3306
socket                          = /opt/tmp/mysql.sock

[mysqld]
user                            = theOne
port                            = 3306
socket                          = /opt/tmp/mysql.sock

basedir                         = /opt
tmpdir                          = /opt/tmp/
datadir                         = /opt/var/mysql/

lc_messages                     = en_US
lc_messages_dir                 = /opt/share/mysql

skip-external-locking

bind-address                    = 127.0.0.1
key_buffer_size                 = 16M
table_open_cache                = 64
read_buffer_size                = 256K
sort_buffer_size                = 512K
net_buffer_length               = 8K
max_allowed_packet              = 1M
read_rnd_buffer_size            = 512K
myisam_sort_buffer_size         = 8M

server-id                       = 1

innodb_file_format              = barracuda 
innodb_large_prefix             = on 
innodb_data_home_dir            = /opt/var/mysql
innodb_log_file_size            = 5M
innodb_file_per_table           = true
innodb_use_sys_malloc           = 0
innodb_data_file_path           = ibdata1:10M:autoextend
default-storage-engine          = innodb
innodb_log_buffer_size          = 8M
innodb_buffer_pool_size         = 16M
innodb_autoinc_lock_mode        = 2
innodb_lock_wait_timeout        = 50
innodb_log_group_home_dir       = /opt/var/mysql
innodb_flush_log_at_trx_commit  = 1
innodb_additional_mem_pool_size = 2M

[mysqldump]
quick
max_allowed_packet              = 16M

[mysql]
no-auto-rehash

[myisamchk]
read_buffer                     = 2M
write_buffer                    = 2M
key_buffer_size                 = 20M
sort_buffer_size                = 20M

[mysqlhotcopy]
interactive-timeout

!includedir /opt/etc/mysql/conf.d/
MMM

sed -e "s/theOne/$USER/g" -i /opt/etc/mysql/my.cnf

reset_sql >/dev/null 2>&1

    # PHP7设置 
    if [ `ps | grep php-fpm |wc -l` -ne 1 ];then
        killall -9 php-fpm
    fi
    sed -e "/^doc_root/d" -i /opt/etc/php.ini
    sed -e "s/.*memory_limit = .*/memory_limit = 64M/g" -i /opt/etc/php.ini
    sed -e "s/.*post_max_size = .*/post_max_size = 1000M/g" -i /opt/etc/php.ini
    sed -e "s/.*max_execution_time = .*/max_execution_time = 200 /g" -i /opt/etc/php.ini
    sed -e "s/.*upload_max_filesize.*/upload_max_filesize = 1000M/g" -i /opt/etc/php.ini
    sed -e "s/.*listen.mode.*/listen.mode = 0666/g" -i /opt/etc/php7-fpm.d/www.conf

    # 生成ONMP命令
    set_onmp_sh
    onmp start
    echo "浏览器地址栏输入：$localhost:81 查看php探针"
}

#设置数据库密码
set_passwd()
{
    echo -e "\033[41;37m 初始密码：123456 \033[0m"
    mysqladmin -u root -p password
    onmp restart
}

# 重置数据库
reset_sql()
{
    killall -9 mysqld
    rm -rf /opt/mysql
    rm -rf /opt/var/mysql

    mkdir -p /opt/mysql/
    /opt/bin/mysql_install_db 1>/dev/null
    /opt/bin/mysqld >/dev/null 2>&1 &
    if [ `ps | grep mysqld |wc -l` -ne 2 ];then
        /opt/bin/mysqld >/dev/null 2>&1 &
    fi
    sleep 2
    echo -e "\n正在初始化数据库，请稍等"
    sleep 10
    mysqladmin -u root password 123456 1>/dev/null
    killall mysqld
    killall -9 mysqld
    echo -e "\033[41;37m 数据库用户：root, 初始密码：123456 \033[0m"
    onmp restart
}

# 卸载onmp
remove_onmp()
{
    killall -9 nginx mysqld php-fpm
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
# 删除
rm -rf /opt/bin/onmp
rm -rf /opt/etc/init.d/Sonmp
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
onmp_restart()
{
    killall -9 nginx mysqld php-fpm  >/dev/null 2>&1
    sleep 2
    /opt/bin/mysqld >/dev/null 2>&1 &
    /opt/etc/init.d/S79php7-fpm start  >/dev/null 2>&1
    nginx
    onmplist="nginx mysqld php-fpm"
    num=1
    for i in $onmplist; do
        sleep 2
        if [ `ps | grep $i |wc -l` -eq 1 ];then
            echo "$i 启动失败"
            nvram set onmp_enable=0
            let num++
        fi
    done
    if [[ $num -gt 1 ]]; then
        echo "onmp启动失败"
        logger -t "【ONMP】" "启动失败"
    else
        nvram set onmp_enable=1
        echo "onmp已启动"
        logger -t "【ONMP】" "已启动"
        vhost_list
    fi
}
case $1 in
    open ) 
    /opt/ONMP-master/onmp_intall.sh
    ;;

    start )
    echo "onmp正在启动"
    logger -t "【ONMP】" "正在启动"
    onmp_restart
    ;;

    stop )
    echo "onmp正在停止"
    logger -t "【ONMP】" "正在停止"
    killall -9 nginx mysqld php-fpm
    nvram set onmp_enable=0
    echo "onmp已停止"
    logger -t "【ONMP】" "已停止"
    ;;

    restart )
    echo "onmp正在重启"
    logger -t "【ONMP】" "正在重启"
    onmp_restart
    ;;

    list )
    vhost_list
    ;;
    * )
    echo "----------------------------------------"
    echo "|*************  onmp 命令  *************|"
    echo "|**********  管理 onmp open  **********|"
    echo "|*********  启动 停止 重启ONMP  *********|"
    echo "|*****  onmp start|stop|restart   *****|"
    echo "|*******  查看网站列表 onmp list  *******|"
    echo "----------------------------------------"
    ;;
esac
EOF
# 开机启动
cat > "/opt/etc/init.d/Sonmp" <<-\MMM
#!/bin/sh
case "$1" in
    start)
    onmp start
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
echo "|**********  管理 onmp open  **********|"
echo "|*********  启动 停止 重启ONMP  *********|"
echo "|*****  onmp start|stop|restart   *****|"
echo "|*******  查看网站列表 onmp list  *******|"
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
(3) Nextcloud（Owncloud团队的新作，美观强大的个人云盘）
(4) h5ai（优秀的文件目录）
(5) Lychee（一个很好看，易于使用的Web相册）
(0) 退出
AAA
read -p "输入你的选择[0-5]: " input
case $input in
    1) install_phpmyadmin;;
2) install_wordpress;;
3) install_nextcloud;;
4) install_h5ai;;
5) install_lychee;;
0) exit;;
*) echo "你输入的不是 0 ~ 5 之间的!"
break;;
esac
}

# WEB程序安装器
web_installer()
{
    filelink=$1
    zipfilename=$2
    dirname=$3
    port=$4
    clear
    echo "----------------------------------------"
    echo "|***********  WEB程序安装器  ***********|"
    echo "----------------------------------------"
    echo "安装 $2："
    read -p "输入服务端口（请避开已使用的端口）[留空默认$port]: " nport
    if [[ $nport ]]; then
        $port=$nport
    fi
    read -p "输入目录名（留空默认：$zipfilename）: " webdir
    if [[ ! -n "$webdir" ]]; then
        webdir=$zipfilename
    fi
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
    if [[ ! -f /opt/wwwroot/$zipfilename.zip ]]; then
        wget --no-check-certificate -O /opt/wwwroot/$zipfilename.zip $filelink
    fi
    if [[ ! -f /opt/wwwroot/$zipfilename.zip ]]; then
        echo "下载未成功"
    else
        echo "正在解压..."
        unzip /opt/wwwroot/$zipfilename.zip -d /opt/wwwroot/ >/dev/null 2>&1
        mv /opt/wwwroot/$dirname /opt/wwwroot/$webdir
        echo "解压完成..."
    fi
fi
if [ ! -d "/opt/wwwroot/$webdir" ] ; then
    echo "安装未成功"
    exit
fi
}

# 安装phpMyAdmin
install_phpmyadmin()
{
    filelink="https://files.phpmyadmin.net/phpMyAdmin/4.7.3/phpMyAdmin-4.7.3-all-languages.zip"
    web_installer $filelink phpMyAdmin phpMyAdmin-4.7.3-all-languages 82
    echo "正在配置phpmyadmin..."
    cp /opt/wwwroot/$webdir/config.sample.inc.php /opt/wwwroot/$webdir/config.inc.php
    chmod 644 /opt/wwwroot/$webdir/config.inc.php
    add_vhost $port $webdir
    sed -e "s/.*blowfish_secret.*/\$cfg['blowfish_secret'] = 'onmponmponmponmponmponmponmponmp';/g" -i /opt/wwwroot/$webdir/config.inc.php
    onmp restart >/dev/null 2>&1
    echo "phpMyaAdmin安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "phpMyaAdmin的用户、密码就是数据库用户、密码"
}

# 安装WordPress
install_wordpress()
{
    filelink="https://cn.wordpress.org/wordpress-4.8-zh_CN.zip"
    web_installer $filelink WordPress wordpress 83
    echo "正在配置WordPress..."
    echo "define("FS_METHOD","direct");" >> /opt/wwwroot/$webdir/wp-config-sample.php
    echo "define("FS_CHMOD_DIR", 0777);" >> /opt/wwwroot/$webdir/wp-config-sample.php
    echo "define("FS_CHMOD_FILE", 0777);" >> /opt/wwwroot/$webdir/wp-config-sample.php
    add_vhost $port $webdir
    sed -e "s/.*\#otherconf.*/        include     \/opt\/etc\/nginx\/conf\/wordpress.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf
    onmp restart >/dev/null 2>&1
    echo "WordPress安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "可以用phpMyaAdmin建立数据库，然后在这个站点上一步步配置网站信息"
}

# 安装h5ai
install_h5ai()
{
    filelink="https://release.larsjung.de/h5ai/h5ai-0.29.0.zip"
    web_installer $filelink h5ai _h5ai 85
    echo "正在配置h5ai..."
    mv /opt/wwwroot/$webdir /opt/wwwroot/_h5ai
    mkdir -p /opt/wwwroot/$webdir/ 
    mv /opt/wwwroot/_h5ai /opt/wwwroot/$webdir/
    cp /opt/wwwroot/$webdir/_h5ai/README.md /opt/wwwroot/$webdir/
    add_vhost $port $webdir
    sed -e "s/.*\index index.html.*/    index  index.html  index.php  \/_h5ai\/public\/index.php;/g" -i /opt/etc/nginx/vhost/$webdir.conf
    onmp restart >/dev/null 2>&1
    echo "h5ai安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "配置文件在/opt/wwwroot/$webdir/_h5ai/private/conf/options.json"
    echo "你可以通过修改它来获取更多功能"
}

# 安装Lychee
install_lychee()
{
    filelink="https://github.com/electerious/Lychee/archive/master.zip"
    web_installer $filelink Lychee Lychee-master 86
    echo "正在配置Lychee..."
    chmod -R 777 /opt/wwwroot/$webdir/uploads/ /opt/wwwroot/$webdir/data/
    add_vhost $port $webdir
    onmp restart >/dev/null 2>&1
    echo "Lychee安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "首次打开会要配置数据库信息"
    echo "地址：127.0.0.1 用户、密码你自己设置的或者默认是root 123456"
    echo "下面的可以不配置，然后下一步创建个用户就可以用了"
}

# 安装Nextcloud
install_nextcloud()
{
    filelink="https://download.nextcloud.com/server/releases/nextcloud-12.0.0.zip"
    web_installer $filelink Nextcloud nextcloud 87
    echo "正在配置Nextcloud..."
    add_vhost $port $webdir
    sed -e "s/.*\#otherconf.*/        include     \/opt\/etc\/nginx\/conf\/nextcloud.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf
    onmp restart >/dev/null 2>&1
    echo "Nextcloud安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "首次打开会要配置数据库信息"
    echo "地址：127.0.0.1 用户、密码你自己设置的或者默认是root 123456"
    echo "下面的可以不配置，然后下一步创建个用户就可以用了"
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
    index index.html index.htm index.php tz.php;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Download-Options noopen;
    add_header X-Permitted-Cross-Domain-Policies none;
    location ~ \.php$ {
        fastcgi_pass                    unix:/opt/var/run/php7-fpm.sock;
        fastcgi_index                   index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include                         fastcgi_params;
    }
    #otherconf
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
(3) 设置数据库密码
(4) 重置数据库
(5) 全部重置（会删除网站目录，请注意备份）
(6) 安装网站程序
(0) 退出

EOF
read -p "输入你的选择[0-6]: " input
case $input in
    1) install_onmp_ipk
;;
2) remove_onmp
;;
3) set_passwd
;;
4) reset_sql
;;
5) init_onmp
;;
6) install_website
;;
0) break
;;
*) echo "你输入的不是 0 ~ 6 之间的!"
break
;;
esac 
}

start