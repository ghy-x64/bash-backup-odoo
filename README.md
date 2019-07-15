# bash-backup-odoo
- This script backups odoo database, modules folder, /var/lib/odoo folder.
- It protects database file with a password using 7zip package by recompressing it with a password.
- Transfer backups to a remote FTP server.
- Remove local backups.
- Variables to update:
<pre>
FTP_SERVER=XXX.XXX.XXX.XXX
FTP_USER=username
FTP_PASSWORD="ftp_password"
ADMIN_PASSWORD="admin_db_password"
FILE_PASSWORD="zip_password"
BCK_FOLDER=/odoo/backups
LOG=/root/backup.log
</pre>
 
