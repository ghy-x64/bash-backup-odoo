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

#Archive data and odoo folder
tar -czvf ${BACKUP_MODULE_FILE} ${MODULE_PATH}
tar -czvf ${DATA_FOLDER_FILE} ${DATA_FOLDER}

#Backup DB
for DB in ${ODOO_DATABASES}
do
curl -X POST \
    -F "backup_pwd=${ADMIN_PASSWORD}" \
    -F "backup_db=${DB}" \
    -F "backup_format=zip" \
    -F "token=" \
    -o ${BCK_FOLDER}/${DB}.${TIMESTAMP}.zip \
    http://localhost:8069/web/database/backup
7z a -p${FILE_PASSWORD} -y ${BCK_FOLDER}/${DB}.${TIMESTAMP}.zip.7z ${BCK_FOLDER}/${DB}.${TIMESTAMP}.zip > ${LOG}
7z t -p${FILE_PASSWORD} -y ${BCK_FOLDER}/${DB}.${TIMESTAMP}.zip.7z >> ${LOG}
rm -rf ${BCK_FOLDER}/${DB}.${TIMESTAMP}.zip >> ${LOG}
find ${BCK_FOLDER}/ -type f -mtime +1 -name "${DB}.*.zip*" -delete >> ${LOG}
done

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

rm -rf ${BACKUP_MODULE_FILE}
rm -rf ${DATA_FOLDER_FILE}

mail -r ${SENDER} -s $SUBJECT ${RECIPIENT} < ${LOG}

