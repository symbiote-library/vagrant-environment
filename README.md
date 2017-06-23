> ## **IMPORTANT**

> This project is no longer actively maintained, however, if you're interested in adopting it, please let us know!

Silverstripe Vagrant Development Environment
===
This vagrant set up builds a simple LAMP server and installs a copy of Silverstripe into the Apache web root (```/var/www```) using composer.
The default ports for this box are:

| Guest | Host | Function                         |
|-------|------|----------------------------------|
| 80    | 8080 | http                             |
| 443   | 8443 | https with snake oil certificate |
| 3306  | 8006 | MySQL                            |

If you up a second Vagrant box with this config these ports will auto correct to 2201 - 2203, further boxes will continue to correct to 2204 and up.

Development Only
===
This Vagrant set up is for development use only it is deliberately in-secure and designed to be easy to access and work on with no consideration given to the security implications of this. Do not put this environment on any public network or use it for configuring external web servers.

For Windows
===
It is important to note that whilst you can build and boot up the virtual machine with just the stock command prompt, you will need MinGW (comes bundled with Git as Git Bash) or cygwin. Also backslashes are not standard delimiting characters in this environment, so when navigating to directories use a forward slash.

Install Process
===
This assumes you have Vagrant installed already.

 - Git Clone or download the ```Vagrantfile``` and ```ss_provision.sh``` files and place them in a directory you wish to work in

 - Open ```ss_provision.sh``` in a text editor and change:
    - ```SERVERADMIN="RENAME@EXAMPLE.COM"```
    - ```URL=""```

 - Open a Terminal/MinGW Terminal/Cygwin Terminal and navigate to the folder the ```Vagrantfile``` and ```ss_provision.sh``` are in

 - Run ```vagrant up``` wait will this completes and don't close the window after it has

 - After Vagrant finishes building the box you will have a ```www``` directory and a ```id_rsa.pub``` file in this directory

 - Open the ```www``` directory and modify ```build.xml``` [further info here](https://github.com/symbiote/silverstripe-base/wiki#creating-a-new-project-using-ozzy)

    - Edit the ```build.xml``` file and change the project name from rename-me to something more accurate

    - Copy the ```build/build.properties.sample``` file to ```build/build.properties```

    - Edit the ```composer.json``` and/or ```build/dependent-modules.default``` and add in any additional modules you may need [more info](https://github.com/symbiote/silverstripe-base/wiki#module-management)

 - Now in the Terminal/MinGW Terminal/Cygwin Terminal type ```vagrant ssh```

 - Vagrant will now log in the box for you via ssh

 - Navigate to the Apache web root by entering ```cd /var/www```

 - Run ```phing build``` to set up the SilverStripe

 - Open a browser and browse to ```http://localhost:8080``` and ```https://localhost:8443``` (these ports may be different if you have multiple boxes running see above)

 - The default Admin log in is user: admin and password: admin

Virtual Box Networking Issue
===
Vagrant current has a bug when set up with VirtualBox that causes issues with VirtualBox's internal networking solution. [More Info](https://github.com/mitchellh/vagrant/issues/3083)

The ```Vagrantfile``` has a hack to get around this at the top of the file. If you are currently using Host-Only Adapter with VirtualBox, when running ```vagrant up``` or ```vagrant reload``` VirtualBoxes DHCP server will be deleted and recreated. This will cause a network drop for any running VMs but they will recover connection again when Vagrant creates the DHCP server again.

## Xdebug

By default Xdebug is activated and configured for both Apache and CLI. To use it in most IDEs you will need to configure the project URL to ```http://localhost:8080``` and the Path Mapping as Remote: ```/var/www``` Local: ```path/to/vagrantbox/www```.

In Netbeans this is done in Project Properties > Run Configuration > Advanced... > Path Mapping

## Github and SSH

During the install process Vagrant generates a ssh key pair for the box and places the public key (id_rsa.pub) in your shared directory next to the ```www``` folder.
You can add this file to Github or other Git based repository to allow the box to push commits to your repository.

Alternatively if you have your own ssh key already the box is set up to support ssh agent forwarding.

## Included Programs

Included programs and PHP extensions:

 - apache2
 - php5
 - mysql
 - memcached
 - postgresql
 - postgresql-contrib
 - mailutils
 - iptables
 - rsync
 - curl
 - git
 - composer (installed at ```/vagrant/composer.phar```)

#### PHP Modules

 - pear
 - gd
 - mcrypt
 - mysql
 - curl
 - sqlite
 - pgsql
 - json
 - xdebug
 - memcached
 - tidy

#### And from PEAR

- phpunit/phpunit-3.7.32 note: As of Mar'14 SS doesn't support PHPUnit 4.0
- phpunit/PHPUnit_MockObject
- phpunit/PHP_CodeCoverage
- phpunit/PHP_Timer
- phing/phing
- phpdoc/phpDocumentor
- VersionControl_SVN
- VersionControl_Git
- PHP_CodeSniffer
- Services_Amazon_S3
- HTTP_Request2
- pdepend/PHP_Depend
- Archive_Tar
- phpmd/PHP_PMD