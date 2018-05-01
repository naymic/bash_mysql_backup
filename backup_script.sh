#!/bin/bash

#Get config input file
CONFIG_FILE=$1

function getConfigValue(){
 echo $(cat "$CONFIG_FILE" | grep -i "$1=" | awk -F "=" '{print $2}'  )
}

#Get Script startime
START_TIME=`date +%s`

#Declare static variable
HOST="$( getConfigValue host)"
HOSTNAME="$( getConfigValue hostname)"
USER="$( getConfigValue username)"
PW="$( getConfigValue password)"
ROOT_BAK="$(getConfigValue backup_root)${HOSTNAME}/"
DATE=`date '+%Y-%m-%d_%H:%M:%S'`

#Start backup
echo "Start backup for ${HOST} with ${USER}"

#Discover databases
QUERY=$(mysql -u$USER -p$PW -h$HOST -e "use mysql;SELECT Db FROM db;" 2>&1 | grep -v "Warning: Using a password")
DATABASES=($(for i in $QUERY; do echo $i |sed 's/\\\\\_/_/g' ; done));

#Check host folder
if [ ! -d "${ROOT_BAK}" ]
then
    mkdir "${ROOT_BAK}"
fi

#Backup databases
for i in ${DATABASES[@]}
do
    echo "Start backup for $i database:"
    #Check database folder
    if [ ! -d "$ROOT_BAK$i" ]
    then
        mkdir "$ROOT_BAK$i"
    fi
    DUMPFILE="${ROOT_BAK}${i}/${HOSTNAME}_${i}_${DATE}.sql.gz"
    (mysqldump -u$USER -p$PW -h$HOST $i 2>&1 | grep -v "Warning: Using a password") | gzip | pv -W > "${DUMPFILE}"

done

#Discover backup runtime
END_TIME=`date +%s`
RUNTIME=$((END_TIME-START_TIME))
echo "Backup of ${HOSTNAME} (${HOST}) finished in ${RUNTIME} seconds"
