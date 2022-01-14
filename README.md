# pi4-lamp
LAMP setup script for raspberry pi 4

NOT Complete.

Install LAMP:
https://www.tal.org/tutorials/raspberrypi_php_apache

Install MySQL:
sudo apt install -y mariadb-server
sudo mysql -u root "SET PASSWORD FOR 'root'@localhost = PASSWORD('1qaz2wsx');FLUSH PRIVILEGES;";

https://serverfault.com/questions/783527/non-interactive-silent-install-of-mysql-5-7-on-ubuntu-16-04-lts

Install Composer:
https://lindevs.com/install-composer-on-raspberry-pi/

bash ./install.sh

TODO:
    sudo apt update -y && sudo apt upgrade -y;
    Expand Filesystem.
    Enable SSH.
    Set Wifi.
    install Git.
    Localize keyboard & timezone.
    Add Coloring to console.
    Ask for Mysql Root PW.
    Run clean up and delete this script/directory.
    test localhost?
    Restart after setup.
