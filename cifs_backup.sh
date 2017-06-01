#!/bin/bash
# Author: Komsan Kamsamur <maprangzth@hotmail.com>
# Release Date: 2017-05-12
# 
####################################################

##### PATH OF SCRIPT RUNNING
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

####################################################

CONFIG_PATH=/home/backup/config
RAWLOG_PATH=/home/backup/rawlog

[ -d ${CONFIG_PATH} ] || mkdir -p ${CONFIG_PATH}
[ -d ${RAWLOG_PATH} ] || mkdir -p ${RAWLOG_PATH}

EXPORT_CONF="/etc/exports"
EXPORT_VALUE01="/home/backup/config *(rw,no_root_squash)"
EXPORT_VALUE02="/home/backup/rawlog *(rw,no_root_squash)"
CHECK_EXPORT01=$( grep -c "^/home/backup/config.*" ${EXPORT_CONF} )
CHECK_EXPORT02=$( grep -c "^/home/backup/rawlog.*" ${EXPORT_CONF} )

##### START BACKUP ORIGINAL EXPORT FILE
BACKUP_PATH=${SCRIPT_PATH}/backup_org_conf
[ -d ${BACKUP_PATH} ] || mkdir -p ${BACKUP_PATH}

BACKUP_NAME=${BACKUP_PATH}/$( basename ${EXPORT_CONF} ).org

if [ ! -f ${BACKUP_NAME} ]
then
    cp -p ${EXPORT_CONF} ${BACKUP_NAME}
fi
##### END BACKUP ORIGINAL EXPORT FILE

##### START ADD CONFIG TO EXPORT FILE
if [ ${CHECK_EXPORT01} -a ${CHECK_EXPORT02} -eq 0 ]
then
    echo ${EXPORT_VALUE01} > ${EXPORT_CONF}
    echo ${EXPORT_VALUE02} >> ${EXPORT_CONF}

    service nfs restart
fi
##### END ADD CONFIG TO EXPORT FILE

##### START CHECK cifs_backup.conf
BACKUP_CONF=${SCRIPT_PATH}/cifs_backup.conf

if [ ! -f ${BACKUP_CONF} ]
then
    touch ${BACKUP_CONF}
    echo "# TypeOfBackup,SourcePath,DestPath" > ${BACKUP_CONF}
fi

CONF_COUNT=$( egrep -v "^#|^$" ${BACKUP_CONF} | egrep -c "config|rawlog" )

if [ ${CONF_COUNT} -eq 0 ]
then
    echo "Config file is wrong, please check ${BACKUP_CONF}"
    echo "Script terminating..."
    exit;
fi
##### END CHECK cifs_backup.conf

##### START BACKUP CIFS
SRC_CONFIG=$( grep "config" ${BACKUP_CONF} | awk -F "," '{print $2}' )
SRC_RAWLOG=$( grep "rawlog" ${BACKUP_CONF} | awk -F "," '{print $2}' )

BASE_DST=/home/softnixlogger/users/admin/cifs/
DST_CONFIG=$( grep "config" ${BACKUP_CONF} | awk -F "," '{print $3}' )
DST_RAWLOG=$( grep "rawlog" ${BACKUP_CONF} | awk -F "," '{print $3}' )

function backupCIFS () {

    [[ "${1}" == "/" ]] && SRC="" || SRC=${1}
    [[ "${2}" == "/" ]] && DST="" || DST=${2}

    if [ -z "${SRC}" -o -z "${DST}" ]
    then
        echo "Source or Destination is not mountpoint on system."
    else
        CHK_SRC=$( /bin/mountpoint -q "${SRC}" )
        [[ $? -eq 0 ]] && REST_SRC=0 || REST_SRC=1

        CHK_DST=$( /bin/mountpoint -q "${BASE_DST}${DST}" )
        [[ $? -eq 0 ]] && REST_DST=0 || REST_DST=1

        if [ ${REST_SRC} -eq 1 -o ${REST_DST} -eq 1 ]
        then
            echo "Source or Destination is not mountpoint on system."
        else
            /usr/bin/rsync --remove-source-files -vzagtop ${SRC} ${BASE_DST}${DST}
        fi
    fi

}

# Backup Config
backupCIFS "${SRC_CONFIG}" "${BASE_DST}${DST_CONFIG}"
# Backup Rawlog
backupCIFS "${SRC_RAWLOG}" "${BASE_DST}${DST_RAWLOG}"

##### END BACKUP CIFS
