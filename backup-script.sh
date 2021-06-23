#!/bin/bash
#Odoo 8
FTP_SERVER=XXX.XXX.XXX.XXX
FTP_USER=username
FTP_PASSWORD="ftp_password"
ADMIN_PASSWORD="admin_db_password"
FILE_PASSWORD="zip_file_password"

BCK_FOLDER=/odoo/backups
LOG=/root/backup.log
TIMESTAMP=`date +%Y-%m-%d_%H-%M-%S`
MODULE_PATH=/usr/lib/python2.7/dist-packages/openerp/addons
BACKUP_MODULE_FILE=/odoo/backups/modules-${TIMESTAMP}.tar.gz
DATA_FOLDER=/var/lib/odoo
DATA_FOLDER_FILE=/odoo/backups/data-${TIMESTAMP}.tar.gz
ODOO_DATABASES="SYS"

RECIPIENT=monitoring@xxxx.com
SENDER="backup@xxxx.com"
SUBJECT="Backup Odoo"

NDAYS=28

# work out our cutoff date
MM=`date --date="$NDAYS days ago" +%b`
DD=`date --date="$NDAYS days ago" +%d`

#Archive data and odoo folder
#tar -czvf ${BACKUP_MODULE_FILE} ${MODULE_PATH} 
#tar -czvf ${DATA_FOLDER_FILE} ${DATA_FOLDER} 

#Backup DB
for DB in ${ODOO_DATABASES}
do
echo "Backup Odoo database ${DB}"
curl -X POST \
    -F "backup_pwd=${ADMIN_PASSWORD}" \
    -F "backup_db=${DB}" \
    -F "backup_format=zip" \
    -F "token=" \
    -o ${BCK_FOLDER}/${DB}.${TIMESTAMP}.zip \
    http://localhost:8069/web/database/backup
echo "Download complete"
echo "Protect backup file"
7z a -p${FILE_PASSWORD} -y ${BCK_FOLDER}/${DB}.${TIMESTAMP}.zip.7z ${BCK_FOLDER}/${DB}.${TIMESTAMP}.zip > ${LOG}
echo "Complete"
echo "Test backup file"
7z t -p${FILE_PASSWORD} -y ${BCK_FOLDER}/${DB}.${TIMESTAMP}.zip.7z >> ${LOG}
echo "Test complete"
echo "Remove tmp file"
rm -rf ${BCK_FOLDER}/${DB}.${TIMESTAMP}.zip >> ${LOG}
#find ${BCK_FOLDER}/ -type f -mtime +1 -name "*.zip*" -delete >> ${LOG}
done

echo "Uploading file"
#Send to FTP server
ftp -ivn ${FTP_SERVER} << SCRIPTEND >> ${LOG}
user ${FTP_USER} ${FTP_PASSWORD}
bin
bin
prompt
prompt
lcd ${BCK_FOLDER}
mput *
put 
bye
SCRIPTEND
echo "Upload complete"

echo "Remove local file"
rm -f ${BCK_FOLDER}/${DB}.${TIMESTAMP}.zip.7z
#rm -rf ${BACKUP_MODULE_FILE}
#rm -rf ${DATA_FOLDER_FILE}
echo "Local file deleted"

echo Removing files older than $MM $DD

# get directory listing from remote source
listing=`ftp -i -n ${FTP_SERVER} <<EOMYF
user ${FTP_USER} ${FTP_PASSWORD}
bin
bin
ls
quit
EOMYF
`
lista=( $listing )


# loop over our files
for ((FNO=0; FNO<${#lista[@]}; FNO+=9));do
  # month (element 5), day (element 6) and filename (element 8)
  # echo Date ${lista[`expr $FNO+5`]} ${lista[`expr $FNO+6`]}          File: ${lista[`expr $FNO+8`]}

  # check the date stamp
  if [ "${lista[`expr $FNO+5`]}" = "$MM" ];
  then
    if [[ $DD == 0* ]]; then DD="${DD:1}"; else DD=$DD; fi
    if [[ ${lista[`expr $FNO+6`]} -lt $DD ]];
    then
      # Remove this file
      echo "Removing ${lista[`expr $FNO+8`]}"
      ftp -i -n ${FTP_SERVER} <<EOMYF2 
      user ${FTP_USER} ${FTP_PASSWORD}
      bin
      bin
      delete ${lista[`expr $FNO+8`]}
      quit
EOMYF2


    fi
  fi
done

echo "Send email notification"
mail -r ${SENDER} -s $SUBJECT ${RECIPIENT} < ${LOG}
echo "Backup complete"



