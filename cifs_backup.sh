#!/bin/bash
# Author: Komsan Kamsamur <maprangzth@hotmail.com>
# Date: 2017-05-09
# 
####################################################

##### PATH OF SCRIPT RUNNING
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

####################################################

CONF_PATH=/home/backup/config
 RAW_PATH=/home/backup/rawlog

[ -d ${CONF_PATH} ] || mkdir -p ${CONF_PATH}
[ -d ${RAW_PATH} ]  || mkdir -p ${RAW_PATH}

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
