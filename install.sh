#!/bin/bash
	#export DEBIAN_FRONTEND=noninteractive;

# Variables #
	HOSTNAME=$(hostname);
	CHANGE_HOSTNAME="n";
	LOG_DATE=`date +%m_%d_%Y`;
	LOG_FILE="$HOME/logs/${LOG_DATE}.log";
	CPU_INFO="/proc/cpuinfo";
	MSG_NP="This device is most likley not a Raspberry Pi";

	# Supported PHP Versions #
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

		# Check all is good #
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
	read -p "Do you wish to change your hostname, this currently is '${HOSTNAME}' ? " -n 1 -r
	echo    # (optional) move to a new line
	if [[ ! $REPLY =~ ^[Yy]$ ]]
	then
		log "INFO CHANGE HOST NAME: NO";
	else
		log "INFO CHANGE HOST NAME: YES";
		CHANGE_HOSTNAME="y";
	fi

	log "INFO CHANGE_HOSTNAME: ${CHANGE_HOSTNAME,,}";
	if [[ $CHANGE_HOSTNAME == "y" ]]
	then
		log "INFO Ask for new host name:";
		read -p "Enter New Hostname: " HOSTNAME
		log "INFO New hostname: ${HOSTNAME}";
	fi

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
		log "INFO HOSTNAME: ${HOSTNAME}";
		log "INFO PHP_VERSION: ${PHP_VERSION}";
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

		mysql_secure_installation

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
