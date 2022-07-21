#!/usr/bin/env bash

# Default variable values
mysql_root_pass="nokia3189"
mysql_user="root"
mysql_user_pass="nokia3189"
mysql_user_db="bs_sicap"

while getopts ":a:b:c:d:" opt; do
    case "${opt}" in
        a)
            mysql_root_pass="$OPTARG" ;;
        b)
            mysql_user="$OPTARG" ;;
        c)
            mysql_user_pass="$OPTARG" ;;
        d)
            mysql_user_db="$OPTARG" ;;
    esac
done

# Set timezone to your timezone
sudo unlink /etc/localtime
sudo ln -s /usr/share/zoneinfo/Europe/Bucharest /etc/localtime

sudo apt-get update >> /vagrant/build.log 2>&1

echo "-- Installing debianconf --"
sudo apt-get install -y debconf-utils >> /vagrant/build.log 2>&1

echo "-- Installing dirmngr --"
sudo apt-get install dirmngr >> /vagrant/build.log 2>&1

echo "-- Installing unzip --"
sudo apt-get install -y unzip >> /vagrant/build.log 2>&1

echo "-- Installing aptitude --"
sudo apt-get -y install aptitude >> /vagrant/build.log 2>&1

echo "-- Updating package lists --"
sudo aptitude update -y >> /vagrant/build.log 2>&1

#echo "-- Updating system --"
#//sudo aptitude safe-upgrade -y >> /vagrant/build.log 2>&1

echo "-- Uncommenting alias for ll --"
sed -i "s/#alias ll='.*'/alias ll='ls -al'/g" /home/vagrant/.bashrc

echo "-- Installing curl --"
sudo aptitude install -y curl >> /vagrant/build.log 2>&1

echo "-- Installing apt-transport-https --"
sudo aptitude install -y apt-transport-https >> /vagrant/build.log 2>&1

echo "-- Adding GPG key for sury repo --"
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg >> /vagrant/build.log 2>&1

echo "-- Adding PHP 7 packages repo --"
echo 'deb https://packages.sury.org/php/ stretch main' | sudo tee -a /etc/apt/sources.list >> /vagrant/build.log 2>&1

echo "-- Updating package lists again after adding sury --"
sudo aptitude update -y >> /vagrant/build.log 2>&1

echo "-- Installing Apache --"
sudo aptitude install -y apache2 >> /vagrant/build.log 2>&1

echo "-- Enabling mod rewrite --"
sudo a2enmod rewrite >> /vagrant/build.log 2>&1

echo "-- Configuring Apache --"
sudo sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

echo "-- Adding MySQL GPG key --"
wget -O /tmp/RPM-GPG-KEY-mysql https://repo.mysql.com/RPM-GPG-KEY-mysql >> /vagrant/build.log 2>&1
sudo apt-key add /tmp/RPM-GPG-KEY-mysql >> /vagrant/build.log 2>&1

echo "-- Adding MySQL repo --"
echo "deb http://repo.mysql.com/apt/debian/ stretch mysql-5.7" | sudo tee /etc/apt/sources.list.d/mysql.list >> /vagrant/build.log 2>&1

echo "-- Updating package lists after adding MySQL repo --"
sudo aptitude update -y >> /vagrant/build.log 2>&1

# Set mysql paramaters for install
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $mysql_root_pass"
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $mysql_root_pass"

# Set phpmyadmin paramaters for install
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean false"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-user string root'
sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-pass password $mysql_root_pass'
sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/app-pass password $mysql_root_pass'
sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/app-password-confirm password $mysql_root_pass'
sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/database-type select mysql'
sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/setup-password password $mysql_root_pass'
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/internal/skip-preseed boolean true"

echo "-- Installing MySQL server --"
sudo aptitude install -y mysql-server >> /vagrant/build.log 2>&1

echo "-- Creating alias for quick access to the MySQL (just type: db) --"
echo "alias db='mysql -u root -p$mysql_root_pass'" >> /home/vagrant/.bashrc

echo "-- Create mysql user and database --"
sudo mysql -u root -p$mysql_root_pass -e "CREATE DATABASE IF NOT EXISTS $mysql_user_db;" >> /vagrant/build.log 2>&1
sudo mysql -u root -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON $mysql_user_db.* TO '$mysql_user'@'%' IDENTIFIED BY '$mysql_user_pass';" >> /vagrant/build.log 2>&1
sudo mysql -u root -p$mysql_root_pass -e "FLUSH PRIVILEGES;" >> /vagrant/build.log 2>&1

echo "-- Installing PHP stuff --"
sudo aptitude install -y libapache2-mod-php5.6 php5.6 php5.6-dev php5.6-pdo php5.6-mysql php5.6-mbstring php5.6-xml php5.6-intl php5.6-tokenizer php5.6-gd php5.6-imagick php5.6-curl php5.6-zip >> /vagrant/build.log 2>&1

echo "-- Installing Xdebug --"
sudo aptitude install -y php5.6-xdebug >> /vagrant/build.log 2>&1

echo "-- Configuring xDebug (idekey = PHP_STORM) --"
sudo tee -a /etc/php/5.6/mods-available/xdebug.ini << END
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.remote_port=9001
xdebug.idekey=PHP_STORM
END

echo "-- Custom configure for PHP --"
sudo tee -a /etc/php/5.6/mods-available/custom.ini << END
error_reporting = E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED
display_errors = on
post_max_size = 100M
max_execution_time = 600
max_input_time = 600
upload_max_filesize = 100M

END
sudo ln -s /etc/php/5.6/mods-available/custom.ini /etc/php/5.6/apache2/conf.d/00-custom.ini  >> /vagrant/build.log 2>&1

echo "-- Installing phpmyadmin --"
#sudo aptitude install -q -y -f phpmyadmin >> /vagrant/build.log 2>&1
#sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf >> /vagrant/build.log 2>&1
#sudo a2enconf phpmyadmin.conf >> /vagrant/build.log 2>&1
wget https://files.phpmyadmin.net/phpMyAdmin/5.1.1/phpMyAdmin-5.1.1-all-languages.tar.xz >> /vagrant/build.log 2>&1
sudo tar xf phpMyAdmin-5.1.1-all-languages.tar.xz -C /usr/share >> /vagrant/build.log 2>&1
sudo mv /usr/share/phpMyAdmin-5.1.1-all-languages/ /usr/share/phpmyadmin >> /vagrant/build.log 2>&1
sudo mkdir -p /var/lib/phpmyadmin/tmp >> /vagrant/build.log 2>&1
sudo chown -R www-data:www-data /var/lib/phpmyadmin >> /vagrant/build.log 2>&1
sudo cp /vagrant/utility/config.inc.php  /usr/share/phpmyadmin >> /vagrant/build.log 2>&1
sudo cp /vagrant/utility/phpmyadmin.conf /etc/apache2/conf-enabled >> /vagrant/build.log 2>&1
sudo cp /vagrant/utility/my.cnf /etc/mysql/my.cnf >> /vagrant/build.log 2>&1
sudo a2enconf phpmyadmin.conf >> /vagrant/build.log 2>&1
sudo /etc/init.d/mysql restart >> /vagrant/build.log 2>&1
echo "-- Create mysql user and database --"
sudo mysql -u root -p$mysql_root_pass -e "CREATE DATABASE IF NOT EXISTS phpmyadmin DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >> /vagrant/build.log 2>&1
sudo mysql -u root -p$mysql_root_pass -e "GRANT ALL ON phpmyadmin.* TO 'phpmyadmin'@'%' IDENTIFIED BY '$mysql_user_pass';" >> /vagrant/build.log 2>&1
sudo mysql -u root -p$mysql_root_pass -e "FLUSH PRIVILEGES;" >> /vagrant/build.log 2>&1

sudo systemctl restart apache2 
echo "-- Installing PHPUnit --"
sudo wget https://phar.phpunit.de/phpunit.phar
sudo chmod +x phpunit.phar
sudo mv phpunit.phar /usr/bin/phpunit

echo "-- Restarting Apache --"
sudo /etc/init.d/apache2 restart >> /vagrant/build.log 2>&1

echo "-- Installing Git --"
sudo aptitude install -y git >> /vagrant/build.log 2>&1

echo "-- Installing Composer --"
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer >> /vagrant/build.log 2>&1
export COMPOSER_ALLOW_SUPERUSER=1;
echo "-- Installing Project --"
[[ ! -L /usr/local/ws-salud ]] && sudo ln -sf /usr/local/ws-salud /var/www/html >> /vagrant/build.log 2>&1
cd /usr/local/ws-salud
sudo composer install 

sudo chown -R www-data:www-data /usr/local/ws-salud >> /vagrant/build.log 2>&1
sudo cp /vagrant/utility/ws-salud.dev.conf /etc/apache2/sites-enabled >> /vagrant/build.log 2>&1
sudo a2ensite ws-salud.dev.conf >> /vagrant/build.log 2>&1

sudo systemctl restart apache2 >> /vagrant/build.log 2>&1