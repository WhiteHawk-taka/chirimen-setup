#!/bin/bash
# 軽量化
sudo apt-get -y purge wolfram-engine
sudo apt-get -y purge minecraft-pi
sudo apt-get -y remove --purge libreoffice*
sudo apt-get -y clean
sudo apt-get -y autoremove

sudo apt-get -y update
sudo apt-get -y upgrade

# raspiはupgrade失敗しやすいので念の為2回
sudo apt-get -y update
sudo apt-get -y upgrade

# 各種ツールをインストール
sudo apt-get -y install ttf-kochi-gothic fonts-noto uim uim-mozc nodejs npm apache2 vim emacs

# ディスプレイ解像度設定
echo 'hdmi_force_hotplug=1 hdmi_group=2 hdmi_mode=85 hdmi_drive=2' | sudo tee -a /boot/config.txt

# 日本語設定
sudo sed 's/#\sen_GB\.UTF-8\sUTF-8/en_GB\.UTF-8 UTF-8/g' /etc/locale.gen | sudo tee /etc/locale.gen
sudo sed 's/#\sja_JP\.EUC-JP\sEUC-JP/ja_JP\.EUC-JP EUC-JP/g' /etc/locale.gen | sudo tee /etc/locale.gen
sudo sed 's/#\sja_JP\.UTF-8\sUTF-8/ja_JP\.UTF-8 UTF-8/g' /etc/locale.gen | sudo tee /etc/locale.gen
sudo locale-gen ja_JP.UTF-8
sudo update-locale LANG=ja_JP.UTF-8

# 時間設定
sudo raspi-config nonint do_change_timezone Japan

# キーボード設定
sudo raspi-config nonint do_configure_keyboard jp

# パスワードの変更
echo 'pi:rasp' | sudo chpasswd

# node.jsのインストール
sudo npm cache clean
sudo npm install n -g
sudo n 8.10.0

# カメラを有効化
sudo raspi-config nonint do_camera 0
echo 'options bcm2835-v4l2 gst_v4l2src_is_broken=1' | sudo tee -a /etc/modprobe.d/bcm2835-v4l2.conf echo 'bcm2835-v4l2' | sudo tee -a /etc/modules-load.d/modules.conf

# I2Cを有効化
sudo raspi-config nonint do_i2c 0

# _gc設定
cd /home/pi/
wget https://rawgit.com/chirimen-oh/chirimen-raspi3/master/release/env/_gc.zip
unzip ./_gc.zip
cd /home/pi/_gc/srv
npm i
sudo npm i forever -g
cd /home/pi/
echo "@reboot sudo -u pi /home/pi/_gc/srv/startup.sh" | crontab
ln -s /home/pi/_gc/srv/reset.sh /home/pi/Desktop/reset.sh
sudo sed 's/wallpaper=.*\n/wallpaper=\/home\/pi\/_gc\/wallpaper\/wallpaper-720p.png/g' /etc/lightdm/pi-greeter.conf | sudo tee /etc/lightdm/pi-greeter.conf
sudo sed 's/wallpaper=.*\n/wallpaper=\/home\/pi\/_gc\/wallpaper\/wallpaper-720p.png/g' /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf | sudo tee /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
mv /home/pi/chirimen-setup/Bookmarks /home/pi/.config/chromium/Default/Bookmarks

# gc設定
sudo sed 's/\/var\/www\/html/\/home\/pi\/Desktop\/gc/g' /etc/apache2/sites-available/000-default.conf | sudo tee /etc/apache2/sites-available/000-default.conf
sudo sed 's/\/var\/www\//\/home\/pi\/Desktop\/gc/g' /etc/apache2/apache2.conf | sudo tee /etc/apache2/apache2.conf
cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/vhost-ssl.conf
echo 'SSLCertificateFile /home/pi/_gc/srv/crt/server.crt SSLCertificateKeyFile /home/pi/_gc/srv/crt/server.key' | sudo tee -a /etc/apache2/sites-available/vhost-ssl.conf
sudo a2ensite vhost-ssl
sudo a2enmod ssl
sudo systemctl restart apache2
echo '@/usr/bin/chromium-browser https://localhost/top' >> /home/pi/.config/lxsession/LXDE-pi/autostart