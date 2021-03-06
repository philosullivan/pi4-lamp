#!/bin/bash
	#export DEBIAN_FRONTEND=noninteractive;

# Variables #
	#HOSTNAME=$(hostname);
	HOSTNAME=$(cat /etc/hostname | tr -d " \t\n\r");
	CHANGE_HOSTNAME="n";
	CHANGE_ROOT_PASSWORD="n";
	WEB_DIRECTORY='/var/www/html';
	LOG_DATE=`date +%m_%d_%Y`;
	LOG_FILE="$HOME/logs/${LOG_DATE}.log";
	CPU_INFO="/proc/cpuinfo";
	MSG_NP="This device is most likley not a Raspberry Pi";

	# Make sure running on a pi #
	if [ ! -e /home/pi ]; then
    	error_exit "${MSG_NP}";
	else 
		# Set Raspberry Pi specific variables #
		SERIAL=$(sed -n 's/^Serial\s*: 0*//p' ${CPU_INFO});
		MODEL=$(sed -n 's/^Model\s*: 0*//p' ${CPU_INFO});
		HARDWARE=$(sed -n 's/^Hardware\s*: 0*//p' ${CPU_INFO});
		REVISION=$(sed -n 's/^Revision\s*: 0*//p' ${CPU_INFO});
	fi

	# Supported PHP Versions will need regular updating#
	# https://www.php.net/supported-versions.php
	PHP_VERSIONS=(
		"7.4"
		"8.0"
		"8.1"
		"Quit"
	);

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

	# #
	log "INFO Gathering System config";

	# Select PHP Version to Install. #
	PS3="Select the version of PHP to install: "
	select PHP_VERSION in ${PHP_VERSIONS[@]}
	do
		# Quit #
		if [ $PHP_VERSION == "Quit" ]; then
			error_exit "NO PHP VERSION SELECTED";
		fi
		# Invalid option selected #
		if [[ ! " ${PHP_VERSIONS[*]} " =~ " ${PHP_VERSION} " ]]; then
			error_exit "INVALID PHP VERSION SELECTED";
		fi
		echo "Selected PHP VERSION: ${PHP_VERSION}";
		break
	done

	# Hostname #
	# https://github.com/westonruter/raspberry-pi-stuff/blob/master/raspi-hostname.sh
	read -p "Do you wish to change your hostname, this currently is '${HOSTNAME}'? (y/n)" -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]
	then
		log "INFO CHANGE HOST NAME: NO";
	else
		log "INFO CHANGE HOST NAME: YES";
		CHANGE_HOSTNAME="y";
	fi

	# Get CHANGE_HOSTNAME and set it to lowercase #
	# log "INFO CHANGE_HOSTNAME: ${CHANGE_HOSTNAME,,}";
	if [[ $CHANGE_HOSTNAME == "y" ]]
	then
		log "INFO Ask for new host name:";
		read -p "Enter New Hostname: " NEW_HOSTNAME
		log "INFO NEW HOSTNAME: ${NEW_HOSTNAME}";
		# raspberrypi
		# NEW_HOSTNAME=raspberrypi-$(cat /proc/cpuinfo | grep -E "^Serial" | sed "s/.*: 0*//");
		echo $NEW_HOSTNAME | sudo tee /etc/hostname > /dev/null
		sudo sed -i "s/127.0.1.1.*$HOSTNAME\$/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
	fi

	# Root password #
	# https://tutorials-raspberrypi.com/raspberry-pi-default-login-password/
	read -p "Do you wish to change your root password ? (y/n)" -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]
	then
		log "INFO CHANGE ROOT_PASSWORD: NO";
	else
		log "INFO CHANGE ROOT_PASSWORD: YES";
		CHANGE_ROOT_PASSWORD="y";
	fi
	
	# Get CHANGE_ROOT_PASSWORD and set it to lowercase #
	#log "INFO CHANGE_ROOT_PASSWORD: ${CHANGE_ROOT_PASSWORD,,}";
	if [[ $CHANGE_ROOT_PASSWORD == "y" ]]
	then
		passwd
	fi

	# System Info #
	if test -f "$CPU_INFO"; then
		log "INFO SERIAL Number: ${SERIAL}";
		log "INFO MODEL Number: ${MODEL}";
		log "INFO HARDWARE: ${HARDWARE}";
		log "INFO REVISION: ${REVISION}";
		
		if [[ $CHANGE_HOSTNAME == "y" ]]
		then
			log "INFO CHANGE_HOSTNAME: ${$CHANGE_HOSTNAME}";
			log "INFO ORIGINAL_HOSTNAME: ${HOSTNAME}";
			log "INFO NEW_HOSTNAME: ${NEW_HOSTNAME}";
		else
			log "INFO HOSTNAME: ${HOSTNAME}";
		fi

		log "INFO PHP_VERSION: ${PHP_VERSION}";

		if [[ $CHANGE_ROOT_PASSWORD == "y" ]]
		then
			log "INFO CHANGE_ROOT_PASSWORD: ${CHANGE_ROOT_PASSWORD}";
		fi

	else
		error_exit "${MSG_NP}";
	fi

	# Install Apps/Software #

	# PHP Repository #
	PHP=$(php -r 'echo PHP_VERSION;');
	if [ -z "${PHP}" ]
	then
	   log "ERROR PHP is not installed";
	   log "INFO Setting PHP Repository";

	   wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -

	   echo "deb https://packages.sury.org/php/ buster main" | sudo tee /etc/apt/sources.list.d/php${PHP_VERSION}.list

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

	   sudo apt install -y php${PHP_VERSION}-cli php${PHP_VERSION}-fpm \
	   php${PHP_VERSION}-opcache php${PHP_VERSION}-curl php${PHP_VERSION}-mbstring \
	   php${PHP_VERSION}-pgsql php${PHP_VERSION}-zip php${PHP_VERSION}-xml php${PHP_VERSION}-gd;

	   log "INFO Enabling PHP-FPM";

	   sudo a2enmod proxy_fcgi;
	   sudo a2enconf php${PHP_VERSION}-fpm;

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
		log "INFO Watch for Prompts";

		sleep 2s;

		sudo mysql_secure_installation

		log "INFO MYSQL Installation Complete";

	else
		log "INFO MySQL: ${DB}";
	fi

	# Set permissions #
	# https://www.internalpointers.com/post/right-folder-permission-website
	log "INFO Setting Permissions";

	log "INFO Setting user pi as owner";
	sudo chown -R pi ${WEB_DIRECTORY};

	log "INFO Setting webserver as group owner";
	sudo chgrp -R www-data ${WEB_DIRECTORY};

	log "INFO Allowing owner to read, write and execute scripts";
	sudo chmod -R 750 ${WEB_DIRECTORY};

	log "INFO New files/folders inherit parent permissions";
	sudo chmod g+s ${WEB_DIRECTORY};

	log "INFO Creating phpinfo script";
	echo "<?php phpinfo(); phpinfo(INFO_MODULES);?>" > "${WEB_DIRECTORY}/index.php";

	log "INFO Removing default index.html file";
	rm "${WEB_DIRECTORY}/index.html";

	# Check all is good #
	log "INFO Running System Check";

	# Cleanup #
	log "INFO Running Cleanup";

	# End Script #
	log "INFO Script Complete";

	# Reboot #
	

exit 0;
