#!/bin/bash
echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
echo "LANG=en_US.utf-8" >> /etc/environment
echo "LC_ALL=en_US.utf-8" >> /etc/environment
sudo service sshd restart

sudo yum install -y mariadb-server
sudo systemctl restart mariadb.service
sudo systemctl enable mariadb.service

#mysql_secure installation
mysql -u root <<EOF
UPDATE mysql.user SET Password=PASSWORD('hash123') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF

sudo systemctl restart mariadb.service
sudo mysql -u root -phash123 -e "create database ${DB_NAME};"
sudo mysql -u root -phash123 -e "create user '${DB_USER}'@'%' identified by '${DB_PASSWORD}';"
sudo mysql -u root -phash123 -e "grant all privileges on ${DB_NAME}.* to '${DB_USER}'@'%';"
sudo mysql -u root -phash123 -e "FLUSH PRIVILEGES;"
sudo systemctl restart mariadb.service
