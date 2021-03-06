#!/bin/bash
#
# cd /home/pi/
# wget -O setup.sh https://raw.githubusercontent.com/chirimen-oh/chirimen/master/setup.sh
# chmod 777 setup.sh
# ./setup.sh
#

# ----------------------- 定義 ----------------
HOME="/home/pi"
NODE_VERSION=12.20.0
ARDUINO_VERSION=1.8.13
CHIRIMEN_GC_ZIP="https://r.chirimen.org/gc.zip"
CHIRIMEN__GC_ZIP="https://r.chirimen.org/_gc.zip"
ARDUINO_SOUCE="https://downloads.arduino.cc/arduino-${ARDUINO_VERSION}-linuxarm.tar.xz"
VSCODE_DEB="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-armhf"
XDG_AUTOSTART=$(cat << EOF
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xscreensaver -no-splash
@xset s off
@xset -dpms
@xset s noblank
@/usr/bin/chromium-browser https://localhost/top --enable-experimental-web-platform-features
EOF
)
APT_MIRRORS=$(cat << EOF
http://ftp.jaist.ac.jp/raspbian/
http://ftp.tsukuba.wide.ad.jp/Linux/raspbian/raspbian/
http://ftp.yz.yamagata-u.ac.jp/pub/linux/raspbian/raspbian/
http://raspbian.raspberrypi.org/raspbian/
EOF
)
APT_SOURCES_LIST=$(cat << EOF
deb mirror+file:/etc/apt/mirrors.txt buster main contrib non-free rpi
EOF
)
CONFIG_MIMEAPP=$(cat << EOF
[Added Associations]
application/javascript=code.desktop;
text/plain=code.desktop

[Default Applications]
application/javascript=code.desktop;
text/plain=code.desktop
EOF
)
APACHE_000_DEFAULT=$(cat << EOF
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /home/pi/Desktop/gc

        ErrorLog \\\${APACHE_LOG_DIR}/error.log
        CustomLog \\\${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
)
APACHE_APACHE2=$(cat << EOF
DefaultRuntimeDir \\\${APACHE_RUN_DIR}
PidFile \\\${APACHE_PID_FILE}
Timeout 300
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5

User \\\${APACHE_RUN_USER}
Group \\\${APACHE_RUN_GROUP}

HostnameLookups Off

ErrorLog \\\${APACHE_LOG_DIR}/error.log
LogLevel warn

IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf
Include ports.conf

<Directory />
        Options FollowSymLinks
        AllowOverride None
        Require all denied
</Directory>

<Directory /usr/share>
        AllowOverride None
        Require all granted
</Directory>

<Directory /var/www/>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
</Directory>

<Directory /home/pi/Desktop/gc>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
</Directory>

AccessFileName .htaccess

<FilesMatch \"^\.ht\">
        Require all denied
</FilesMatch>

LogFormat \"%v:%p %h %l %u %t \\\\\"%r\\\\\" %>s %O \\\\\"%{Referer}i\\\\\" \\\\\"%{User-Agent}i\\\\\"\" vhost_combined
LogFormat \"%h %l %u %t \\\\\"%r\\\\\" %>s %O \\\\\"%{Referer}i\\\\\" \\\\\"%{User-Agent}i\\\\\"\" combined
LogFormat \"%h %l %u %t \\\\\"%r\\\\\" %>s %O\" common
LogFormat \"%{Referer}i -> %U\" referer
LogFormat \"%{User-agent}i\" agent

IncludeOptional conf-enabled/*.conf
IncludeOptional sites-enabled/*.conf
EOF
)
APACHE_VHOST_SSL=$(cat << EOF
<IfModule mod_ssl.c>
        <VirtualHost _default_:443>
                ServerAdmin webmaster@localhost

                DocumentRoot /home/pi/Desktop/gc

                ErrorLog \\\${APACHE_LOG_DIR}/error.log
                CustomLog \\\${APACHE_LOG_DIR}/access.log combined

                SSLEngine on
                SSLCertificateFile        /home/pi/_gc/srv/crt/server.crt
                SSLCertificateKeyFile /home/pi/_gc/srv/crt/server.key

                <FilesMatch \"\.(cgi|shtml|phtml|php)\$\">
                                SSLOptions +StdEnvVars
                </FilesMatch>
                <Directory /usr/lib/cgi-bin>
                                SSLOptions +StdEnvVars
                </Directory>
        </VirtualHost>
</IfModule>
EOF
)
# ------------ 定義箇所ここまで --------------

# メイン処理
# 一時的にスリープを無効
sudo xset s off
sudo xset -dpms
sudo xset s noblank
# スリープを無効
grep 'consoleblank=0' /boot/cmdline.txt
if [ $? -ge 1 ]; then
    sudo sed '1s/$/ consoleblank=0/' /boot/cmdline.txt |\
        sudo tee /tmp/cmdline && sudo cat /tmp/cmdline |\
        sudo tee /boot/cmdline.txt && sudo rm -f /tmp/cmdline
fi

if [ ! -f /etc/xdg/lxsession/LXDE-pi/autostart.orig ]; then
    sudo cp /etc/xdg/lxsession/LXDE-pi/autostart /etc/xdg/lxsession/LXDE-pi/autostart.orig
fi
sudo sh -c "echo \"${XDG_AUTOSTART}\" > /etc/xdg/lxsession/LXDE-pi/autostart"

# aptをmirrorで指定
sudo sh -c "echo \"${APT_MIRRORS}\" > /etc/apt/mirrors.txt"
if [ ! -f /etc/apt/sources.list.orig ]; then
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.orig
fi
sudo sh -c "echo \"${APT_SOURCES_LIST}\" > /etc/apt/sources.list"
sudo apt-get update

# upgradeを保留に変更
sudo apt-mark hold raspberrypi-ui-mods
# 必要な項目をインストール
sudo apt-get install at-spi2-core

# update
sudo apt-get -y update
sudo apt-get -y upgrade

# raspiはupgrade失敗しやすいので念の為2回
sudo apt-get -y update
sudo apt-get -y upgrade

# 各種ツールをインストール
sudo apt-get -y install ttf-kochi-gothic fonts-noto uim uim-mozc nodejs npm apache2 vim emacs libnss3-tools
# インストール失敗しやすいので2回
sudo apt-get -y install ttf-kochi-gothic fonts-noto uim uim-mozc nodejs npm apache2 vim emacs libnss3-tools
sudo apt-get -y autoremove

# VS code のインストール
wget -O /tmp/code.deb "${VSCODE_DEB}"
sudo apt install -y /tmp/code.deb


# 日本語設定
# デフォルトの設定が en_GB.UTF-8 になっている
sudo sed 's/#\sen_GB\.UTF-8\sUTF-8/en_GB\.UTF-8 UTF-8/g' /etc/locale.gen |\
    sudo tee /tmp/locale && sudo cat /tmp/locale |\
    sudo tee /etc/locale.gen && sudo rm -f /tmp/locale
sudo sed 's/#\sja_JP\.EUC-JP\sEUC-JP/ja_JP\.EUC-JP EUC-JP/g' /etc/locale.gen  |\
    sudo tee /tmp/locale && sudo cat /tmp/locale |\
    sudo tee /etc/locale.gen && sudo rm -f /tmp/locale
sudo sed 's/#\sja_JP\.UTF-8\sUTF-8/ja_JP\.UTF-8 UTF-8/g' /etc/locale.gen  |\
    sudo tee /tmp/locale && sudo cat /tmp/locale |\
    sudo tee /etc/locale.gen && sudo rm -f /tmp/locale
sudo locale-gen ja_JP.UTF-8
sudo update-locale LANG=ja_JP.UTF-8

# 時間設定
sudo raspi-config nonint do_change_timezone Asia/Tokyo

# キーボード設定
sudo raspi-config nonint do_configure_keyboard jp

# Wi-Fi設定
sudo raspi-config nonint do_wifi_country JP

# node.jsのインストール
sudo npm install n -g
sudo n ${NODE_VERSION}
PATH=$PATH
sudo npm i eslint prettier -g

# VS code extension
/usr/share/code/bin/code --install-extension dbaeumer.vscode-eslint
/usr/share/code/bin/code --install-extension esbenp.prettier-vscode

# .js .pyのデフォルトをVS codeに
echo "${CONFIG_MIMEAPP}" > ${HOME}/.config/mimeapps.list

# カメラを有効化
sudo raspi-config nonint do_camera 0
grep 'bcm2835-v4l2' /etc/modprobe.d/bcm2835-v4l2.conf
if [ $? -ge 1 ]; then
    echo 'options bcm2835-v4l2 gst_v4l2src_is_broken=1' | sudo tee -a /etc/modprobe.d/bcm2835-v4l2.conf
fi
grep 'bcm2835-v4l2' /etc/modules-load.d/modules.conf
if [ $? -ge 1 ]; then
    echo 'bcm2835-v4l2' | sudo tee -a /etc/modules-load.d/modules.conf
fi

# I2Cを有効化
sudo raspi-config nonint do_i2c 0

# _gc設定
cd ${HOME}
if [ ! -f ${HOME}/_gc.zip ]; then
    wget ${CHIRIMEN__GC_ZIP}
fi
if [ ! -d ${HOME}/_gc/ ]; then
    unzip ./_gc.zip
fi
cd ${HOME}/_gc/srv
npm i
sudo npm i forever -g
cd ${HOME}
crontab -l > /tmp/tmp_crontab
grep "${HOME}/_gc/srv/startup.sh" /tmp/tmp_crontab
if [ $? = 1 ]; then
    echo "@reboot sudo -u pi ${HOME}/_gc/srv/startup.sh" | crontab
fi
ln -s ${HOME}/_gc/srv/reset.sh ${HOME}/Desktop/reset.sh
mkdir ${HOME}/.config/chromium/
mkdir ${HOME}/.config/chromium/Default/
cp ${HOME}/_gc/bookmark/Bookmarks ${HOME}/.config/chromium/Default/Bookmarks
pcmanfm --set-wallpaper ${HOME}/_gc/wallpaper/wallpaper-720P.png


# gc設定
chromium-browser &
cd ${HOME}
if [ ! -f ${HOME}/gc.zip ]; then
    wget ${CHIRIMEN_GC_ZIP}
fi
# chromiumの起動待ちダウンロード
if [ ! -f ${HOME}/arduino-${ARDUINO_VERSION}-linuxarm.tar.xz ]; then
    wget ${ARDUINO_SOUCE}
fi
if [ ! -d ${HOME}/Desktop/gc/ ]; then
    unzip ./gc.zip -d ${HOME}/Desktop
fi
# chromiumの起動待ち
sleep 120s

# Apache設定
if [ ! -f /etc/apache2/sites-available/000-default.conf.orig ]; then
    sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.orig
fi
sudo sh -c "echo \"${APACHE_000_DEFAULT}\" > /etc/apache2/sites-available/000-default.conf"
if [ ! -f /etc/apache2/apache2.conf.orig ]; then
    sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.orig
fi
sudo sh -c "echo \"${APACHE_APACHE2}\" > /etc/apache2/apache2.conf"

sudo sh -c "echo \"${APACHE_VHOST_SSL}\" > /etc/apache2/sites-available/vhost-ssl.conf"

sudo a2ensite vhost-ssl
sudo a2enmod ssl
sudo systemctl restart apache2
grep -- '--enable-experimental-web-platform-features' /usr/share/raspi-ui-overrides/applications/lxde-x-www-browser.desktop
if [ $? = 1 ]; then
    sudo sed 's/Exec=\/usr\/bin\/x-www-browser\s%u/Exec=\/usr\/bin\/x-www-browser --enable-experimental-web-platform-features %u/g' /usr/share/raspi-ui-overrides/applications/lxde-x-www-browser.desktop |\
        sudo tee /tmp/xbrowser && sudo cat /tmp/xbrowser |\
        sudo tee /usr/share/raspi-ui-overrides/applications/lxde-x-www-browser.desktop && sudo rm -f /tmp/xbrowser
fi
grep -- '--enable-experimental-web-platform-features' /usr/share/applications/chromium-browser.desktop
if [ $? = 1 ]; then
    sudo sed 's/Exec=chromium-browser/Exec=chromium-browser --enable-experimental-web-platform-features/g' /usr/share/applications/chromium-browser.desktop |\
        sudo tee /tmp/chbrowser && sudo cat /tmp/chbrowser |\
        sudo tee /usr/share/applications/chromium-browser.desktop && sudo rm -f /tmp/chbrowser
fi

# 証明書追加
certfile="${HOME}/_gc/srv/crt/ca.crt"
certname="org-TripArts"

for certDB in $(find ~/ -name "cert9.db")
do
    certdir=$(dirname ${certDB});
    certutil -A -n "${certname}" -t "TCu,Cu,Tu" -i ${certfile} -d sql:${certdir}
done


# Arduino IDE 追加
cd ${HOME}
mkdir ${HOME}/Applications/
if [ ! -d ${HOME}/Applications/arduino-${ARDUINO_VERSION}/ ]; then
    tar xvf arduino-${ARDUINO_VERSION}-linuxarm.tar.xz
    mv arduino-${ARDUINO_VERSION} ${HOME}/Applications/
fi
cd ${HOME}/Applications/
ln -s arduino-${ARDUINO_VERSION} arduino
cd ${HOME}/Applications/arduino/
./install.sh
rm -f ${HOME}/arduino-${ARDUINO_VERSION}-linuxarm.tar.xz
cd ${HOME}

# upgradeを保留を解除
sudo apt-mark auto raspberrypi-ui-mods
# 上をアップグレード
sudo apt-get -y upgrade


####
# 最後にダイアログをOKにしてrebootして完了
####

sudo reboot
