#!/bin/bash
#
#Movein script
##Actions
##
##Update packages
##Install SS requirements
##Setup proper Logrotation for silverstripe logs

# Move in to a new Ubuntu 13.10 server

##Set this to suit you options from here:
# http://php.net/timezones
TIMEZONE='Australia/Melbourne'

##Set a an email address for the server admin
SERVERADMIN="RENAME@EXAMPLE.COM"

##Set a URL for the site e.g vagrant-example.dev
URL="vagrant.dev"

#Other variables
UNIXDATE=`date +%s`
SITES_AVAILBLE=/etc/apache2/sites-available
APACHE_GROUP="www-data"

# Eject safely if there is no URL passed

if [ -z ${URL} ];
  then
    echo -n "Please add the URL (no protocol) as the first and only argument"
    exit 0
fi


# Force Apt to use your local mirror - this will override the original VM's config
cat << __EOF__ >  /etc/apt/sources.list
deb mirror://mirrors.ubuntu.com/mirrors.txt saucy main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt saucy-updates main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt saucy-backports main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt saucy-security main restricted universe multiverse
__EOF__

# update apt to make sure we have the most recent manifests
#
# TODO - Replace with PACKAGETOOL
#
apt-get -y update

# Set up postfix so it doesn't throw prompts and crash the install
#
# TODO Check this is in anyway logical
#
debconf-set-selections <<< "postfix postfix/mailname string $1"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix

# Set up mysql so it doesn't throw prompts and crash the install
#
# TODO work out a decent policy for setting this
#
debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'
apt-get -y install mysql-server

# Install the required tools
#
# TODO - Replace with PACKAGETOOL
#
apt-get -y install apache2 php5 php5-dev php5-gd php5-mcrypt php5-mysql php5-curl php5-sqlite mailutils iptables rsync php5-tidy curl php5-xdebug memcached php5-memcached postgresql postgresql-contrib php5-pgsql php5-json git


# Remove the index.html so it doesn't confuse composer/git later
rm /var/www/index.html

apt-get install php-pear
## need phing unit etc.
pear config-set preferred_state alpha
pear channel-discover components.ez.no
pear channel-discover pear.symfony-project.com
pear channel-discover pear.phing.info
pear channel-discover pear.phpmd.org
pear channel-discover pear.phpdoc.org
pear channel-discover pear.symfony.com
pear channel-discover pear.pdepend.org
pear channel-discover pear.symfony.com

# Instatlling PHPUnit v3.7 as SS currently currenty doesn't support 4.0
pear channel-discover pear.phpunit.de
pear install --alldeps phpunit/phpunit-3.7.32
##The deps just in case
pear install phpunit/PHPUnit_MockObject
pear install phpunit/PHP_CodeCoverage
pear install phpunit/PHP_Timer

pear install phing/phing
## And all of phing's optionals deps this should make using phing pretty seamless
pear install phpdoc/phpDocumentor
pear install VersionControl_SVN
pear install VersionControl_Git
pear install PHP_CodeSniffer
pear install Services_Amazon_S3 ## Maybe unnecessary
pear install HTTP_Request2 ## Canidate to be removed not really sure what it does
pear install pdepend/PHP_Depend
pear install Archive_Tar
pear install --alldeps phpmd/PHP_PMD

# Disable the default apache sites
#
a2dissite 000-default
a2dissite default-ssl
# Enable SSL
#
make-ssl-cert generate-default-snakeoil --force-overwrite
a2enmod ssl

# Enable rewrite
#
a2enmod rewrite
a2enmod headers

# Create the base apache configuration for the site
#
cat << __EOF__ > ${SITES_AVAILBLE}/${URL}.conf

<VirtualHost *:80>

  ServerName ${URL}
  ServerAdmin ${SERVERADMIN}
  CustomLog /var/log/apache2/vhosts.log vhost_combined

  DocumentRoot /var/www

  <Directory /var/www>
    AllowOverride All
  </Directory>

  <Directory />
    AllowOverride All
  </Directory>

</VirtualHost>
__EOF__

# Create the base SSL apache configuration for the site
#
cat << __EOF__ > ${SITES_AVAILBLE}/${URL}-ssl.conf
<IfModule mod_ssl.c>
  <VirtualHost _default_:443>

    ServerName ${URL}
    ServerAdmin ${SERVERADMIN}

    DocumentRoot /var/www

    <Directory /var/www>
      AllowOverride All
    </Directory>

    <Directory />
      AllowOverride All
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    SSLEngine on

    SSLCertificateFile  /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

    <FilesMatch "\.(cgi|shtml|phtml|php)$">
      SSLOptions +StdEnvVars
    </FilesMatch>
    <Directory /usr/lib/cgi-bin>
      SSLOptions +StdEnvVars
    </Directory>

    BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown

  </VirtualHost>
</IfModule>
__EOF__

# Enable the newly created site
#
a2ensite ${URL}
a2ensite ${URL}-ssl

# Swap Apache user to vagrant in the hope of fixing Phing -- it works :D
sed -i 's/export APACHE_RUN_USER=.*/export APACHE_RUN_USER=vagrant/' /etc/apache2/envvars

# Set the date value in php so we don't get scary errors.
sed -i "s@;date.timezone =@date.timezone = '${TIMEZONE}'@" /etc/php5/cli/php.ini
sed -i "s@;date.timezone =@date.timezone = '${TIMEZONE}'@" /etc/php5/apache2/php.ini

# Set PHP memory_limit to 256MB so tests don't hit the limit
sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php5/cli/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php5/apache2/php.ini

# Setup xdebug to work with the private network ip back to host
cat << __EOF__ >> /etc/php5/mods-available/xdebug.ini

xdebug.remote_enable=on
xdebug.remote_handler=dbgp
xdebug.remote_host=172.28.128.1
xdebug.remote_port=9000

__EOF__

#Apache work finish restart Apache
service apache2 restart

# Create the Silverstripe Log directory

if [ ! -e /var/log/silverstripe  ];
  then
    echo "Creating Silverstripe Log directory"
    /bin/mkdir /var/log/silverstripe
    /bin/chmod 770 /var/log/silverstripe
    /bin/chown vagrant.www-data /var/log/silverstripe
fi


# Silverstripe Log rotations
if [ ! -f /etc/logrotate.d/silverstripe ];
  then
  echo "Adding Silverstripe logrotation scripts"
cat << __EOF__ >  /etc/logrotate.d/silverstripe
/var/log/silverstripe/*.log {
  weekly
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  create 660 vagrant www-data
  sharedscripts
  postrotate
  endscript
}
__EOF__
fi

#Trying to generate a key pair for the vagrant user
if [ ! -f /home/vagrant/.ssh/vagrant_id_rsa ];
  then
  /bin/mkdir /home/vagrant/.ssh
  cd /home/vagrant/.ssh
  #Create a new key pair for vagrant
  ssh-keygen -q -t rsa -f /home/vagrant/.ssh/vagrant_id_rsa -N ""

  ## Copy out the  pub key so it's easy to add to github etc.
  cp /home/vagrant/.ssh/vagrant_id_rsa.pub /vagrant
  ##cp /home/vagrant/.ssh/vagrant_id_rsa /vagrant
fi

#composer
#
if [ ! -f /vagrant/composer.phar ]
  then
  cd /vagrant
  curl -sS https://getcomposer.org/installer | php

fi
