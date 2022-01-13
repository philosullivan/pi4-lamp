#!/usr/bin/bash

    # TODO #
    #! Expand Filesystem.
    #! Enable SSH.
    #! install Git.
    #! Set Wifi.
    #! Localize keyboard & timezone.
    # sudo apt update.

# Variables #
    # Log setup #
    LOG_DATE=`date +%m_%d_%Y`;
    LOG_FILE="${LOG_DATE}.log";

    # Apps/Software to look for #
    PHP=$(php -r 'echo PHP_VERSION;');
    DB=$(mysql --version|awk '{ print $5 }'|awk -F\, '{ print $1 }');
    GIT=$(git --version);
    COMPOSER=$(composer --version);
    CPU_INFO="/proc/cpuinfo";

    # Messages #
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
    # PHP #
    if [ -z "${PHP}" ]
    then
       log "ERROR PHP is not installed";
    else
        log "INFO PHP: ${PHP}";
    fi

    # MYSQL #
    if [ -z "${DB}" ]
    then
       log "ERROR MySQL is not installed";
    else
        log "INFO MySQL: ${DB}";
    fi

    # GIT #
    if [ -z "${GIT}" ]
    then
       log "ERROR GIT is not installed";
    else
        log "INFO GIT: ${GIT}";
    fi
    
    # Composer #
    if [ -z "${COMPOSER}" ]
    then
       log "ERROR COMPOSER is not installed";
    else
        log "INFO COMPOSER: ${COMPOSER}";
    fi
    



# Expand File System #
# sudo raspi-config --expand-rootfs
 
exit 0;