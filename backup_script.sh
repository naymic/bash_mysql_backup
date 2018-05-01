#!/bin/bash

#Declare database input file
DB_FILE=$1

function getValue(){
 echo $(cat "$DB_FILE" | grep -i "$1=" | awk -F "=" '{print $2}'  )
}


#Get Script startime
START_TIME=`date +%s`


#Declare static variable
HOST="$( getValue host)"
HOSTNAME="$( getValue hostname)"
USER="$( getValue username)"
PW="$( getValue password)"
ROOT_BAK="$(getValue backup_root)${HOSTNAME}/"
DATE=`date '+%Y-%m-%d_%H:%M:%S'`

echo "Start backup for ${HOST} with ${USER}"

#Fetch databases into array
QUERY=$(mysql -u$USER -p$PW -h$HOST -e "use mysql;SELECT Db FROM db;" 2>&1 | grep -v "Warning: Using a password")
DATABASES=($(for i in $QUERY; do echo $i |sed 's/\\\\\_/_/g' ; done));

#Check if host exist in backup root
if [ ! -d "${ROOT_BAK}" ]
then
    mkdir "${ROOT_BAK}"
fi

#Backup all databases
for i in ${DATABASES[@]}
do
    echo "Start backup for $i database:"
    #Check if backup directory exists
    if [ ! -d "$ROOT_BAK$i" ]
    then
        mkdir "$ROOT_BAK$i"
    fi
    DUMPFILE="${ROOT_BAK}${i}/${HOSTNAME}_${i}_${DATE}.sql.gz"
    (mysqldump -u$USER -p$PW -h$HOST $i 2>&1 | grep -v "Warning: Using a password") | gzip | pv -W > "${DUMPFILE}"

done

#Get 
END_TIME=`date +%s`
RUNTIME=$((END_TIME-START_TIME))
echo "Backup of $HOSTNAME ($HOST) finished in $RUNTIME seconds"
