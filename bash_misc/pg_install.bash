#!/bin/bash

# exporting http/https proxy maybe needed or modify /etc/environment :
# export http_proxy="$SOME_URL"
# export https_proxy="$SOME_URL"
# script was designed to run in Centos7

# check for root/sudo

if (( $EUID != 0 )); then
	echo "Please run this script as root/sudo!"
   	exit 1
fi

# check for correct argument
envir=$( tr '[:upper:]' '[:lower:]' <<< "$1" )
	case $envir in
        dev)
                echo "Creating $envir database"
                ;;
        test)
                echo "Creating $envir database"
                ;;
        prod)
                echo "Creating $envir database"
                ;;
        *)
       	    	echo "Database server creation script, please choose the environment option:"
            	echo "Usage: $0 {dev|test|prod}"
		exit 1
		;;
	esac

# adding prerequisits
# version lock for PostgreSQL packages
yum install -y yum-plugin-versionlock epel-release openssl

# checking for network connection or proxy issues
curl -fsS https://www.google.com > /dev/null
	case $? in
	0)
		echo ""
		echo "Network seems ok, continuing with install"
		echo ""
		sleep 1
		;;
	*)
		echo ""
		echo "Please check network and proxy settings!"
		echo ""
		sleep 1
		exit 1
		;;
	esac

# --- start functions ---

# simple password generator
func_passgen() {
	< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${1:-12};
	echo;
}

# postgresql package version lock helper
func_pg_version_lock() {
	action=$1
	case $action in
	lock)
		for pkg in $(rpm -qa | sort -n | grep "postgres*")
        	do
	        	yum versionlock $pkg
        	done
	;;
	unlock)
                        yum versionlock delete "postgres*"
	;;
	esac
}

func_minor_update() {
        pgfullver=$1
        pgmajorver=$2
	pgsysinitname=$(systemctl --no-legend list-unit-files  postgres\* | cut -d ' ' -f 1)
	echo ""
	echo "Stopping Postgresql $pgfullver"
	echo ""
	systemctl stop $pgsysinitname
	sleep 1
	yum -y install postgresql$pgmajorver-server-$pgfullver postgresql$pgmajorver-contrib-$pgfullver
	echo ""
	echo "Postgresql $pgfullver installed"
	echo "Restarting..."
	echo ""
	sleep 3
	systemctl restart $pgsysinitname
}

func_install() {
	pgfullver=$1
	pgmajorver=$2
	echo ""
        echo "Starting clean install of Postgresql $pgfullver"
	echo ""
	sleep 1
	echo ""
	echo "Adding PostgreSQL official yum repository"
	echo ""
	sleep 1
	rempath="https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/" # currently universal for all versions
	filename="pgdg-redhat-repo-latest.noarch.rpm"
	curl -s $rempath/$filename -o /tmp/$filename

	yum -y install /tmp/$filename
	unset filename
	
	echo ""	
	echo "Installing Postgresql $pgfullver"
	echo ""
	sleep 1
	yum -y install postgresql$pgmajorver-server-$pgfullver postgresql$pgmajorver-contrib-$pgfullver

	echo ""	
	echo "Opening firewall"
	echo ""
	firewall-cmd --zone=public --add-port=5432/tcp --permanent
	firewall-cmd --reload

	echo ""	
	echo "Modifying standart installation settings according to specifics"
	echo ""
	sleep 1
        mkdir -p /data/postgres/$pgmajorver/pg_data
        mkdir -p /backup/pg_basebackup/current/wal_archive
        mkdir /applic
        chown -R postgres:postgres /backup
        chown -R postgres:postgres /data
        usermod -d /home/postgres -m -s /bin/bash postgres

# ------------- creating and modifying the files --------------------

	echo ""
	echo "Adding user postgres to limited sudoers group"
	echo ""
	cat <<EOF > /etc/sudoers.d/postgres
Cmnd_Alias PG_ADMINS = /bin/systemctl status postgresql*, /bin/systemctl start postgresql*, /bin/systemctl stop postgresql*, /bin/systemctl restart postgresql*, /bin/systemctl reload postgresql*
%postgres ALL=(ALL) NOPASSWD: PG_ADMINS
EOF

# ------------- creating and modifying the files
	echo ""
	echo "Creating .pgpass"
	echo ""
	cat <<EOF > /home/postgres/.pgpass
#hostname:port:database:username:password
localhost:5432:*:postgres:$pgpass
EOF
	chmod 0600 /home/postgres/.pgpass

# ------------- creating .bashrc
	echo ""
	echo "Creating .bashrc"
	echo ""
	cat <<EOF > /home/postgres/.bashrc
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
EOF

# ------------- creating .bash_profile
	echo ""
	echo "Creating .bash_profile"
	echo ""
	cat <<EOF > /home/postgres/.bash_profile
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

export PATH=/usr/pgsql-$pgmajorver/bin:$PATH
export PGDATA=/data/postgres/$pgmajorver/pg_data
EOF

# ------------- creating .psqlrc
	echo ""
	echo "Creating .psqlrc"
	echo ""
	cat <<EOF > /home/postgres/.psqlrc
\set PROMPT1 '%[%033[1m%]%M %n@%/%R%[%033[0m%]%# '
EOF

# ------------- end creating and modifying the files ----------------
	echo ""
	echo "Adding custom PGDATA to the system"
	echo ""

        chown -R postgres:postgres /home/postgres
	# this folder needs to be recreated because we moved it to /home/postgres in previous steps
	mkdir -p /var/lib/pgsql/$pgmajorver
	chown -R postgres:postgres /var/lib/pgsql

	mkdir -p /etc/systemd/system/postgresql-$pgmajorver.service.d
	cat <<EOF > /etc/systemd/system/postgresql-$pgmajorver.service.d/override.conf
[Service]
Environment=PGDATA=/data/postgres/$pgmajorver/pg_data/
EOF
	systemctl daemon-reload
	
	echo ""
	echo "If this is new installation then database init is needed"
	echo ""
	sleep 1
        /usr/pgsql-$pgmajorver/bin/postgresql-$pgmajorver-setup initdb

        pgsysinitname=$(systemctl --no-legend list-unit-files  postgres\* | cut -d ' ' -f 1)

	echo ""
        echo "Enabling PostgreSQL service"
	echo ""
        systemctl enable $pgsysinitname

	echo ""
	echo "Restarting PostgreSQL server"
	echo ""
        systemctl restart $pgsysinitname
	sleep 3

	echo ""
	echo "Modifing pg_hba.conf and adding primary interface netmask"
	echo ""
	# primary iface netmask can be wrong in some cases
	prim_netmask=$(ip route | grep $(ip route | grep default | awk '{ print $5 }') | grep -v "default" | awk '/scope/ { print $1 }')
	su - postgres -c "psql -h /tmp -U postgres -d postgres << EOF
	create table hba (lines text);
	insert into hba (lines) values ('local   all             all                                     trust');
	insert into hba (lines) values ('host    all             all             127.0.0.1/32            scram-sha-256');
	insert into hba (lines) values ('host    all             all             ::1/128                 scram-sha-256');
	insert into hba (lines) values ('hostssl    all             all             $prim_netmask            scram-sha-256');
	insert into hba (lines) values('local   replication     all                                     peer');
	insert into hba (lines) values ('host    replication     all             127.0.0.1/32            scram-sha-256');
	insert into hba (lines) values ('host    replication     all             ::1/128                 scram-sha-256');
	copy hba to program 'cat > /data/postgres/$pgmajorver/pg_data/pg_hba.conf';
	drop table hba;
EOF
"
	echo ""
	echo "Reloading PostgreSQL configuration"
	echo ""
        systemctl reload $pgsysinitname
	sleep 1

	# version lock for PostgreSQL packages
	echo ""
	echo "Locking package update for Postgresql $pgsupversion"
	echo ""
	sleep 1
	func_pg_version_lock lock
}

# --- end func_install

func_ssl_configuration() {
	pgfullver=$1
	echo ""
	echo "Generating SSL certificates for PostgreSQL $pgfullver and starting server"
	echo ""
	sleep 1
	hostkey="/etc/ssl/certs/$HOSTNAME.key"
	hostcrt="/etc/ssl/certs/$HOSTNAME.crt"

	openssl req -new -newkey rsa:4096 -days 1095 -nodes -x509 -subj "/C=EE/L=Tartu/O=TEAM_NAME/CN=$HOSTNAME" -keyout $hostkey  -out $hostcrt
	chown postgres:postgres $hostkey
	chmod 0400 $hostkey
	chown postgres:postgres $hostcrt
	chmod 0400 $hostcrt

	pgsysinitname=$(systemctl --no-legend list-unit-files  postgres\* | cut -d ' ' -f 1)

	systemctl start $pgsysinitname
        
	su - postgres -c "psql -h /tmp -U postgres -d postgres << EOF
	alter system set listen_addresses = '*';
	alter system set ssl='on';
	alter system set ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL';
	alter system set ssl_prefer_server_ciphers = 'on';
	alter system set ssl_cert_file = '$hostcrt';
	alter system set ssl_key_file = '$hostkey';
EOF
"
}

# main configuration function, same in all environments
func_main_engine_configuration() {
	totalmem=`grep MemTotal /proc/meminfo | awk '{print $2}'`
        shared_buffers=$((totalmem / 1024 / 4))
        effective_cache=$((totalmem * 2/3/1024))
        pgpass=$(func_passgen)
	pgsysinitname=$(systemctl --no-legend list-unit-files  postgres\* | cut -d ' ' -f 1)

	su - postgres -c "psql -h /tmp -U postgres -d postgres << EOF
	alter system set shared_buffers = '$shared_buffers MB';
	alter system set effective_cache_size = '$effective_cache MB';
	alter user postgres with login;
	alter user postgres with password '$pgpass';
EOF
"
        systemctl restart $pgsysinitname
        echo "PostgreSQL version $1 installed"
        echo ""
        echo "Please note user "postgres" password which is: $pgpass"
        echo ""
}

# PROD environment configuration function
func_prod_engine_configuration() {

	# just in case check that file exists, if not, then must apply all configs manualy
	confsql="/tmp/configure_postgres/*$envir.sql"
 
	if [ ! -f $confsql ]
	then
		echo ""
		echo "Configuration SQL was not found in path: $confsql !"
		echo "Script can continue, but engine will be left unconfigured"
		echo ""
		sleep 3
		exit 0
	fi
	pgsysinitname=$(systemctl --no-legend list-unit-files  postgres\* | cut -d ' ' -f 1)
	su - postgres -c "psql -h /tmp -U postgres -d postgres -f $confsql << EOF
EOF
"
        systemctl restart $pgsysinitname
}

# TEST environment configuration function
func_test_engine_configuration() {

	# just in case check that file exists, if not, then must apply all configs manualy
	confsql="/tmp/configure_postgres/*$envir.sql"
 
	if [ ! -f $confsql ]
	then
		echo ""
		echo "Configuration SQL was not found in path: $confsql !"
		echo "Script can continue, but engine will be left unconfigured"
		echo ""
		sleep 3
		exit 0
	fi
	pgsysinitname=$(systemctl --no-legend list-unit-files  postgres\* | cut -d ' ' -f 1)
	su - postgres -c "psql -h /tmp -U postgres -d postgres -f $confsql << EOF
EOF
"
        systemctl restart $pgsysinitname

}

# DEV environment configuration function
func_dev_engine_configuration() {

	# just in case check that file exists, if not, then must apply all configs manualy
	confsql="/tmp/configure_postgres/*$envir.sql"
 
	if [ ! -f $confsql ]
	then
		echo ""
		echo "Configuration SQL was not found in path: $confsql !"
		echo "Script can continue, but engine will be left unconfigured"
		echo ""
		sleep 5
		exit 0
	fi
	pgsysinitname=$(systemctl --no-legend list-unit-files  postgres\* | cut -d ' ' -f 1)
	su - postgres -c "psql -h /tmp -U postgres -d postgres -f $confsql << EOF
EOF
"
        systemctl restart $pgsysinitname
}

# --- end functions ---

# even if file downloading brakes, then configuration will be applied with defaults and message will be displayed by the function
echo ""
echo "Getting latest configurations for PostgreSQL"
echo ""

filename="configure_postgres_linux.tar"
curl -s https://$SOME_URL/$filename -o /tmp/$filename
tar -xpf /tmp/$filename -C /tmp/

# checking for possible previous versions
sysresult=$(systemctl list-unit-files | grep postgres)

# Getting latest supported PostgreSQL version major and minor numbers.
pgsupversion=`curl -s https://$SOME_URL/postgresql12-latest`
pgsupmajor=`echo $pgsupversion | awk -F \. {'print $1'}`
pgsupminor=`echo $pgsupversion | awk -F \. {'print $2'}`
# --
pgfoundversion=$(su - postgres -c "psql --version" | tail -c 5)
pgfoundmajor=`echo $pgfoundversion | awk -F \. {'print $1'}`
pgfoundminor=`echo $pgfoundversion | awk -F \. {'print $2'}`

if [[ $sysresult ]]; then
                if [[ $pgfoundmajor -eq $pgsupmajor ]] && [[ $pgfoundminor -eq $pgsupminor ]]; then
                                echo ""
                                echo "Postgresql version $pgfoundversion already installed, terminating script"
                                echo ""
                                sleep 1
                                exit 1
                else
                        if [[ $pgfoundmajor -eq $pgsupmajor ]] && [[ $pgfoundminor -lt $pgsupminor ]]; then
                                read -r -p "Found a Postgresql version $pgfoundversion, but current newest supported version is $pgsupversion . Do you want to perform a minor upgrade? [y/n] " response
                                if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
                                then
                                        echo ""
                                        echo "Starting the minor upgrade"
                                        echo ""
                                        sleep 1
                                        # removing version lock for previous version
                                        echo ""
                                        echo "Removing version lock for previous Postgresql version $pgfoundversion"
                                        echo ""
                                        func_pg_version_lock unlock
					# update packages
                                        func_minor_update $pgsupversion $pgsupmajor
                                        # adding version lock for the updated PostgreSQL packages
                                        echo ""
                                        echo "Locking package update for Postgresql new version $pgsupversion"
                                        echo ""
					sleep 1
					func_pg_version_lock lock
					exit 0
                                else
                                        echo "terminating the script"
                                        exit 1
                                fi
                        else
                                echo ""
                                echo "Found a Postgresql version $pgfoundversion, but currently supported version is $pgsupversion . Downgrade or major version upgrade must be performed manually"
                                echo ""
                                sleep 1
				exit 1
                        fi
                fi
fi

func_install $pgsupversion $pgsupmajor

case $envir in
	prod)      
		func_prod_engine_configuration
		func_ssl_configuration $pgsupversion
		func_main_engine_configuration
		echo ""
		echo "Postgresql $pgsupversion $envir database succesfully installed!"
		echo ""
		sleep 3
		exit 0
	;;
	test)
		func_test_engine_configuration
		func_ssl_configuration $pgsupversion
		func_main_engine_configuration
		echo ""
		echo "Postgresql $pgsupversion $envir database succesfully installed!"
		echo ""
		sleep 3
		exit 0
	;; 
	dev)      
		func_dev_engine_configuration
		func_ssl_configuration $pgsupversion
		func_main_engine_configuration
		echo ""
		echo "Postgresql $pgsupversion $envir database succesfully installed!"
		echo ""
		sleep 3
		exit 0
;;
esac

