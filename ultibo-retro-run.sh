sudo mv /boot/kernel7.img /boot/kernel7_l.img
sudo mv /boot/config.txt /boot/config_l.txt
sudo mv /boot/config_u.txt /boot/config.txt
sudo cp /home/pi/ultibo-retro-gui/kernel7.img /boot/kernel7.img
sudo cp /home/pi/ultibo-retro-gui/kernel7.img /boot/ultibo/GUI.u
sudo date +"%H %M %S" >/boot/now.txt
sudo shutdown -r now
