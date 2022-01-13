#!/usr/bin/bash

# Variables #
    export DEBIAN_FRONTEND=noninteractive;

    LOG_DATE=`date +%m_%d_%Y`;
    LOG_FILE="${LOG_DATE}.log";
    CPU_INFO="/proc/cpuinfo";
    MSG_NP="This device is most likley not a Raspberry Pi"

# Functions #

    # Generic logging function #
    log() {
        # Make log file if it doesn't exist #
        if [ ! -f "$LOG_FILE" ]; then
            sudo touch $LOG_FILE;
        fi

        # Is the message empty, just add empty line to log #
        if [ -z "$1" ] 
        then 
            MSG="";
        else
            TS=$(date -u);
            # Timestamp, Log Message #
            MSG="$TS - $1";
        fi

        # Print message to log file #
        echo "$MSG" | sudo tee -a $LOG_FILE;
    }

    # Install app, pass app as arg $ #
    install_app(){
        log "INFO System Update Started";
        sudo apt update;
        log "INFO System Update Complete";

        log "INFO Install Application: $1";
        sudo apt install $1 -y;
        log "INFO Installation of $1 Finished";
    }

    # Ask to start install #
    # read -p "This script will install a LAMP server, do you wish to continue? (Y/N): " confirm && [ $confirm == [yY] || $confirm == [yY][eE][sS] ] || exit 1;
    # log "INFO ${confirm}";

    # #
    log "INFO Script Started";

    # System Info #
    if test -f "$CPU_INFO"; then
        # Set Raspberry Pi specific variables #
        SERIAL=$(sed -n 's/^Serial\s*: 0*//p' /proc/cpuinfo);
        MODEL=$(sed -n 's/^Model\s*: 0*//p' /proc/cpuinfo);
        HARDWARE=$(sed -n 's/^Hardware\s*: 0*//p' /proc/cpuinfo);
        REVISION=$(sed -n 's/^Revision\s*: 0*//p' /proc/cpuinfo);

        log "INFO SERIAL Number: ${SERIAL}";
        log "INFO MODEL Number: ${MODEL}";
        log "INFO HARDWARE: ${HARDWARE}";
        log "INFO REVISION: ${REVISION}";
    else 
        log "ERROR ${MSG_NP}";
        exit 0;
    fi

    # Apps/Software #

    # PHP Repository #
    PHP=$(php -r 'echo PHP_VERSION;');
    if [ -z "${PHP}" ]
    then
       log "ERROR PHP is not installed";
       sleep 2s;
       log "INFO Setting PHP Repository";

       wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -

       echo "deb https://packages.sury.org/php/ buster main" | sudo tee /etc/apt/sources.list.d/php7.list

       sudo apt update

    else
        log "INFO PHP Repository: ${PHP} Setup";
    fi

    # APACHE #
    APACHE=$(apache2 -v);
    if [ -z "${APACHE}" ]
    then
       log "ERROR APACHE is not installed";
       sleep 2s;
       log "INFO Installing APACHE";

       sudo apt install -y apache2 libapache2-mod-fcgid;

    else
        log "INFO APACHE: ${APACHE} Installed";
    fi

    # PHP #
    PHP=$(php -r 'echo PHP_VERSION;');
    if [ -z "${PHP}" ]
    then
       log "ERROR PHP is not installed";
       sleep 2s;
       log "INFO Installing PHP";
       sleep 2s;

       sudo apt install -y php7.3-cli php7.3-fpm \
       php7.3-opcache php7.3-curl php7.3-mbstring \
       php7.3-pgsql php7.3-zip php7.3-xml php7.3-gd;

       log "INFO Enabling PHP-FPM";
       sleep 2s;
    
       sudo a2enmod proxy_fcgi;
       sudo a2enconf php7.3-fpm;

       log "INFO Reloading Apache2";
       sudo systemctl reload apache2;

    else
        log "INFO PHP: ${PHP} Installed";
    fi

    # MYSQL #
    DB=$(mysql --version|awk '{ print $5 }'|awk -F\, '{ print $1 }');
    if [ -z "${DB}" ]
    then
       log "ERROR MySQL is not installed";
       sleep 2s;
       log "INFO MySQL APT Repository";
       sleep 2s;



    else
        log "INFO MySQL: ${DB}";
    fi
    
    # Composer #
    COMPOSER=$(composer --version);
    if [ -z "${COMPOSER}" ]
    then
       log "ERROR COMPOSER is not installed";
       sleep 2s;
       log "INFO Installing Composer";

       wget -O composer-setup.php https://getcomposer.org/installer

       sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer

       sleep 2s;
       log "INFO Removeing Composer setup files";
       rm -rf composer-setup.php

    else
        log "INFO COMPOSER: ${COMPOSER} Installed";
    fi
    



# Expand File System #
# sudo raspi-config --expand-rootfs
 
exit 0;
