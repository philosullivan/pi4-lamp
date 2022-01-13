#!/usr/bin/bash
    export DEBIAN_FRONTEND=noninteractive;

# Variables #   
    LOG_DATE=`date +%m_%d_%Y`;
    LOG_FILE="$HOME/logs/${LOG_DATE}.log";
    CPU_INFO="/proc/cpuinfo";
    MSG_NP="This device is most likley not a Raspberry Pi";

# Functions #

    # Generic logging function #
    log() {
        # Make log file if it doesn't exist #
        if [ ! -f "$LOG_FILE" ]; then
            #sudo touch $LOG_FILE;
            sudo mkdir -p "$HOME/logs/" && sudo touch "${LOG_FILE}";
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

        # Add a delay #
        sleep 1s;

        # Print message to log file #
        echo "$MSG" | sudo tee -a $LOG_FILE;
    }

    # Exit on fatal error #
    error_exit() {
        log "ERROR $1";
        log "ERROR SCRIPT WILL NOW EXIT";
        exit 1;
    }

    # Start Script #
    log "INFO Script Started";

    # Try and ping the  outside world #
    wget -q --spider http://google.com

    # Eval Internet access #
    if [ $? -eq 0 ]; then
        log "INFO INTERNET ACCESS: SUCCESS";
    else
        error_exit "NO INTERNET ACCESS, PLEASE SETUP AN INTERNET CONNECTION";
    fi

    # Load options from .env file #
    if [ -f .env ]
    then
        log "INFO ENV_FILE: FOUND";
        export $(cat .env | grep -v '#' | awk '/=/ {print $1}');

        log "INFO ENV_PHP_VER: ${ENV_PHP_VER}";
        log "INFO ENV_MYSQL_ROOT_PASSWORD: ${ENV_MYSQL_ROOT_PASSWORD}";
        log "INFO ENV_MYSQL_USER_NAME: ${ENV_MYSQL_USER_NAME}";
        log "INFO ENV_MYSQL_USER_PW: ${ENV_MYSQL_USER_PW}";
        log "INFO ENV_HOSTNAME: ${ENV_HOSTNAME}";

        # Eval ENV Variables. #
        
    else 
        error_exit "ENV_FILE: NOT FOUND";
    fi

    # System Info #
    if test -f "$CPU_INFO"; then
        # Set Raspberry Pi specific variables #
        SERIAL=$(sed -n 's/^Serial\s*: 0*//p' /proc/cpuinfo);
        MODEL=$(sed -n 's/^Model\s*: 0*//p' /proc/cpuinfo);
        HARDWARE=$(sed -n 's/^Hardware\s*: 0*//p' /proc/cpuinfo);
        REVISION=$(sed -n 's/^Revision\s*: 0*//p' /proc/cpuinfo);
        HOSTNAME=$(hostname);

        log "INFO SERIAL Number: ${SERIAL}";
        log "INFO MODEL Number: ${MODEL}";
        log "INFO HARDWARE: ${HARDWARE}";
        log "INFO REVISION: ${REVISION}";
        log "INFO HOSTNAME: ${HOSTNAME}";
    else 
        error_exit "${MSG_NP}";
    fi

    # Install Apps/Software #

    # EXPECT #
    EXPECT=$(expect -v);
    if [ -z "${EXPECT}" ]
    then
       log "ERROR EXPECT is not installed";
       log "INFO Setting EXPECT";
       sudo apt update;
       sudo apt install -y expect;
    else
        log "INFO EXPECT: Installed";
    fi

    # PHP Repository #
    PHP=$(php -r 'echo PHP_VERSION;');
    if [ -z "${PHP}" ]
    then
       log "ERROR PHP is not installed";
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
       log "INFO Installing PHP";
       
       sudo apt update;

       sudo apt install -y php7.3-cli php7.3-fpm \
       php7.3-opcache php7.3-curl php7.3-mbstring \
       php7.3-pgsql php7.3-zip php7.3-xml php7.3-gd;

       log "INFO Enabling PHP-FPM";

       sudo a2enmod proxy_fcgi;
       sudo a2enconf php7.3-fpm;

       log "INFO Reloading Apache2";
       sudo systemctl reload apache2;

    else
        log "INFO PHP: ${PHP} Installed";
    fi

    # Composer #
    COMPOSER=$(composer --version);
    if [ -z "${COMPOSER}" ]
    then
       log "ERROR COMPOSER is not installed";
       log "INFO Installing Composer";

       wget -O composer-setup.php https://getcomposer.org/installer

       sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer

       log "INFO Removeing Composer setup files";
       rm -rf composer-setup.php
    else
        log "INFO COMPOSER: ${COMPOSER} Installed";
    fi

    # MYSQL #
    DB=$(mysql --version|awk '{ print $5 }'|awk -F\, '{ print $1 }');
    if [ -z "${DB}" ]
    then
       log "ERROR MySQL is not installed";
       log "INFO Installing MySQL";
       sudo apt update;
       sudo apt install -y mariadb-server;

        log "INFO Securing MySQL Install";

        log "INFO MySQL Changing root password";
        mysql -u root -e "SET PASSWORD FOR root@'localhost' = PASSWORD('${ENV_MYSQL_ROOT_PASSWORD}');FLUSH PRIVILEGES;"

        # log "INFO MySQL Deleting Test users";
        # sudo mysql -uroot -p${ENV_MYSQL_ROOT_PASSWORD} "DELETE FROM mysql.user WHERE User='';"

        # sudo mysql -uroot -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
        
        # log "INFO MySQL Deleting Test Databases";
        # sudo mysql -uroot -p${ENV_MYSQL_ROOT_PASSWORD} "DROP DATABASE test;DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';"

        # log "INFO MySQL Add User";
        # sudo mysql -u root -p${ENV_MYSQL_ROOT_PASSWORD} -e "CREATE USER '${ENV_MYSQL_USER_NAME}'@'localhost' IDENTIFIED BY '${ENV_MYSQL_USER_PW}';GRANT ALL PRIVILEGES ON *.* TO '${ENV_MYSQL_USER_NAME}'@'localhost';FLUSH PRIVILEGES;"

        log "INFO MYSQL Installation Complete";

    else
        log "INFO MySQL: ${DB}";
    fi
    
    # Check all is good #
    log "INFO Running System Check";

    # Cleanup #
    log "INFO Running Cleanup";
    
    # End Script #
    log "INFO Script Complete";

exit 0;
