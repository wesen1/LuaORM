#!/bin/bash

apt-get update

apt-get install -y luarocks

# Install the project dependencies
echo "Installing project dependenices ..."
apt-get install -y lua-sql-mysql
luarocks install lua-resty-template


## Install MySQL
echo "Installing mariadb-server ..."
apt-get install -y mariadb-server

echo "Setting root user password ..."
mysql -u root -Bse "UPDATE \`mysql\`.\`user\` SET \`Password\` = PASSWORD('root') WHERE \`User\` = 'root';"

echo "Creating example database ..."
mysql -u root -Bse "CREATE DATABASE \`orm_test\`;"


# Configure remote database login with the "root" user
mysql -u root -Bse "
  UPDATE \`mysql\`.\`user\` SET \`Host\` = '%' WHERE \`User\` = 'root';
  UPDATE \`mysql\`.\`user\` SET \`plugin\` = '' WHERE \`User\` = 'root';
"

# Allow remote connection to the database by commenting out the line "bind-address = 127.0.0.1"
sed -i "/bind-address/s/^/#/" /etc/mysql/mariadb.conf.d/50-server.cnf

# Restart the database server to apply the new config
service mysql restart
