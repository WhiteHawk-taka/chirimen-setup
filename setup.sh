#!/bin/bash
sudo apt-get -y update
sudo apt-get -y upgrade

# raspiはupgrade失敗しやすいので念の為2回
sudo apt-get -y update
sudo apt-get -y upgrade

# 軽量化
sudo apt-get purge wolfram-engine
sudo apt-get remove --purge libreoffice*
sudo apt-get clean
sudo apt-get autoremove

# 各種ツールをインストール
sudo apt-get -y install ttf-kochi-gothic fonts-noto uim uim-mozc nodejs npm apache2 vim emacs display

# ディスプレイ解像度設定
echo 'hdmi_force_hotplug=1 hdmi_group=2 hdmi_mode=85 hdmi_drive=2' | sudo tee -a /boot/config.txt

# 日本語設定
sudo sed 's/#\sen_GB\.UTF-8\sUTF-8/en_GB\.UTF-8 UTF-8/g' /etc/locale.gen | sudo tee /etc/locale.gen
sudo sed 's/#\sja_JP\.EUC-JP\sEUC-JP/ja_JP\.EUC-JP EUC-JP/g' /etc/locale.gen | sudo tee /etc/locale.gen
sudo sed 's/#\sja_JP\.UTF-8\sUTF-8/ja_JP\.UTF-8 UTF-8/g' /etc/locale.gen | sudo tee /etc/locale.gen
sudo locale-gen ja_JP.UTF-8
sudo update-locale LANG=ja_JP.UTF-8

# パスワードの変更
echo 'pi:rasp' | chpasswd

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
sudo sed 's/wallpaper=.*\n/wallpaper=/home/pi/_gc/wallpaper/wallpaper-720p.png/g' /etc/lightdm/pi-greeter.conf | sudo tee /etc/lightdm/pi-greeter.conf
sudo sed 's/wallpaper=.*\n/wallpaper=/home/pi/_gc/wallpaper/wallpaper-720p.png/g' /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf | sudo tee /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
mv /home/pi/chirimen-setup/Bookmarks /home/pi/.config/chromium/Default/Bookmarks

