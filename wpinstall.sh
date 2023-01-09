#!/bin/bash
echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
echo "LANG=en_US.utf-8" >> /etc/environment
echo "LC_ALL=en_US.utf-8" >> /etc/environment
sudo service sshd restart

sudo yum install -y httpd
sudo amazon-linux-extras install php7.4
sudo systemctl restart httpd.service
sudo systemctl enable httpd.service

wget https://wordpress.org/latest.zip
sudo unzip latest.zip
cp -a wordpress/* /var/www/html/
sudo cp -a wordpress/* /var/www/html/
sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i 's/database_name_here/${DB_NAME}/g' /var/www/html/wp-config.php
sed -i 's/username_here/${DB_USER}/g' /var/www/html/wp-config.php
sed -i 's/password_here/${DB_PASSWORD}/g' /var/www/html/wp-config.php
sed -i 's/localhost/${DBHOST}/g' /var/www/html/wp-config.php
sudo chown -R apache.apache /var/www/html/*

sudo systemctl restart httpd.service
