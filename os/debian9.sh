#!/bin/bash
## Author: Sebastian Mueller, shephard@orbitxp.com
## Released under GNU License v3
##
## This library must produce the following functions:
##
## update_os
## update_os_settings
## update_repo
## update_resolv_file
## update_ca_certs
## pre_seed
## check_pkg
## install_pkg
## 

DEB_SOURCE_FILE="/etc/apt/sources.list"
if [ -e "/var/log/apt/history.log" ]; then
	LAST_APT_RUN=$(date -r "/var/log/apt/history.log" +%Y%m%d)
else
	LAST_APT_RUN=$(date -d "yesterday 12:30" +%Y%m%d)
	mkdir -p "/var/log/apt/"
	touch -d "$LAST_APT_RUN" "/var/log/apt/history.log"
fi

pre_seed() {
	## Pre-seed the values required for successful unattended install of package
	## If values already exist, skip writing. Otherwise add lines.
	## Use this format:
	## <owner>=$1 <question name>=$2 <question type>=$3 <value>=$4
	echo -e $1 $2 $3 $4 | debconf-set-selections
	if [ $? = 0 ];
	then
		log_event "Value $2 for $1 successfully pre-seeded..." "ok"
	else
		log_event "Unable $2 to pre-seed for "$1 "failed"
		exit
	fi
}

crontab_add() {
	## Adds a cronjob to crontab
	## $1 = Cronjob to add (string)
	## $2 = User whose crontab to edit. If not set defaults to "root"
	##
	## * * * * * command to be executed
	## - - - - -
	## | | | | |
	## | | | | ----- Day of week (0 - 7) (Sunday=0 or 7)
	## | | | ------- Month (1 - 12)
	## | | --------- Day of month (1 - 31)
	## | ----------- Hour (0 - 23)
	## ------------- Minute (0 - 59)
	##
	## Set $2 to root if string $2 is empty
	if [ -z "$2" ]
	then
		local USER="root"
	else
		local USER="$2"
	fi

	if($(crontab -u "$USER" -l > /tmp/job)); then
		## Echo new cronjob into cron file
		echo "$1" >> "/tmp/job"

		## Install new cron file
		if($(crontab -u "$USER" /tmp/job)); then
			log_event "Cronjob sucessfully added to crontab" "ok"
		else
			log_event "Unable to add new crontab!" "failed"
			exit 0;
		fi
		if($(rm -rf /tmp/job)); then
			log_event "Temporary crontab sucessfully removed" "ok"
		else
			log_event "Unable to delete temporary Cronjob in /tmp!" "failed"
			exit 0;
		fi

	else
		log_event "Unable to list crontab. Attempting to create a new one" "warn"
	fi
}

check_pkg() {
	## Check if a package is installed by calling dpkg-update. This should be a safe way
	## to check if a package is installed on Debian.
	## $1 = package_name
	if [ $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "install ok installed") -eq 1 ];
	then
		return 1 # Return if package is installed
	else
		return 0 # Return if package is NOT installed
	fi
}

install_pkg() {
## Checks if a package is installed. If not then install it :)
## Otherwise just print out that the package is already installed.
## $1 == Name of the package
## $2 == Dist to use "stable, jessie-backports, unstable, experimental"

	# Update system pkg list
	case $1 in
		update)
			# Update package list from repository
			echo "$(apt-get -o Debug::*::*=true update)"
			if [ $? -eq 0 ]
			then
				log_event "System package list is successfully updated..." "ok"
			else
				log_event "System package list update failed..." "fail"
				exit
			fi
			;;
		safe-upgrade)
			# Upgrade system packages
			echo "$(aptitude -vv -y safe-upgrade)"
			if [ $? -eq 0 ]
			then
				log_event "System is successfully upgraded..." "ok"
			else
				log_event "System upgrade failed..." "fail"
				exit
			fi
			;;
		*)
			## Install pkg $1
			if $(check_pkg $1); then
				if [[ "$1" == "aptitude" ]]; then
					log_event "Attempting to install \"$1\"" "info"
					echo "$(apt-get -V -y -f install aptitude)"
				else
					# Check if we got dist in package
					if [ -n "$2" ]; then
						local DIST="-t $2"
						log_event "Attempting to install \"$1\" with dist $2" "info"
						echo "$(aptitude -vv -y $DIST install "$1")"
					else
						log_event "Attempting to install \"$1\"" "info"
						echo "$(aptitude -vv -y install "$1")"
					fi
				fi

				if [ $? -eq 0 ]
				then
					log_event "$1 is successfully installed..." "ok"
				else
					log_event "$1 install failed..." "fail"
					exit
				fi
			else
				log_event "$1 is already installed. Skipping..." "warn"
			fi
	esac
}

create_user() {
	## Check if user $1 exists. If no then create the user. Otherwise just print out a message.
	## $1 = username
	## $2 = password
	if grep ^$1: /etc/passwd >/dev/null 2>&1; then
		log_event "User $1 already exists" "warn"
	else
		$(sudo -u root -p $SYS_ROOT_PASS "useradd $2 -m -s /bin/bash")
		$(sudo -u root -p $SYS_ROOT_PASS "echo '$1:$2' | chpasswd")

		if [ $? -eq 1 ];
		then
			log_event "Unable to create user: "$1 "failed"
		fi
	fi
}

change_root_pw() {
	## Change root password
	## $1 = password
	$("echo 'root:$1' | chpasswd")
	log_event "Changing root password" "info"
}

update_resolv_file() {
	## Updates /etc/resolv.conf in order to use local DNS and add extra information to this host
	local RESOLV_FILE="/etc/resolv.conf"
	echo -e "domain $DOMAIN_NAME" > "$RESOLV_FILE"
	echo -e "nameserver 129.16.1.53" >> "$RESOLV_FILE" # res1.chalmers.se
	echo -e "nameserver 129.16.2.53" >> "$RESOLV_FILE" # res2.chalmers.se
	echo -e "nameserver 8.8.8.8" >> "$RESOLV_FILE" # google-public-dns-a.google.com
	echo -e "nameserver 208.67.222.222" >> "$RESOLV_FILE" # resolver1.opendns.com
	echo -e "nameserver 208.67.222.220" >> "$RESOLV_FILE" # resolver3.opendns.com
	echo -e "nameserver $WAN_IPV4" >> "$RESOLV_FILE"
	echo -e "options rotate" >> "$RESOLV_FILE"
}
update_hosts_file() {
	## Updates /etc/hosts in order to register this host
	local HOSTS_FILE="/etc/hosts"
	echo -e "$HOST_IPV4 $FQDN $HOSTNAME" >> "$HOSTS_FILE"
}

update_certs() {
	## Updated CA certificates in OS. This is to make SSL
	## chains work if something has been changed.
	update-ca-certificates
}

update_os() {
	## Update os settings
	update_os_settings

	## Check if aptitude exists
	install_pkg "aptitude"

	## Install system tools
	install_pkg "debconf"

	## Install debconf-utils (used for "debconf-get-selections")
	install_pkg "debconf-utils"

	## Install debianutils
	install_pkg "debianutils"

	## Install sudo
	install_pkg "sudo"

	## Install package to get the fastest mirrors
	install_pkg "netselect-apt"

	## Check last update and update system if older than 1 day
	log_event "Comparing dates: $LAST_APT_RUN with $CURRENT_DATE" "info"
	if [ $LAST_APT_RUN -lt $CURRENT_DATE ]; then
		log_event "System was last updated $LAST_APT_RUN. Is now going to get updated." "info"

		## create /etc/apt/sources.list file
		echo -e $(netselect-apt stable -o "$DEB_SOURCE_FILE")
		if [ $? -eq 0 ];
		then
			log_event "Sucessfully selected the fastest mirror" "ok"
		else
			log_event "Unable to select mirror using netselect-apt" "fail"
		fi

		## Update sources.list file with new repos
		update_repo "deb http://ftp.se.debian.org/debian/ jessie main contrib"
		update_repo "deb-src http://ftp.se.debian.org/debian/ jessie main contrib"

		update_repo "deb http://ftp.se.debian.org/debian/ jessie-backports main contrib"
		update_repo "deb-src http://ftp.se.debian.org/debian/ jessie-backports main contrib"

		# Update mirrors and packages again
		install_pkg "update"

		# Upgrade system to make it up-to-date
		install_pkg "safe-upgrade"
	else
		log_event "System is already up-to-date." "info"
	fi
}

update_repo() {
	## Updates OS repo based on string $1. Also updates signing key if available.
	## $1 = URL string and extra info (eg. "stable", "-", "test")
	## $2 = URL to signing key for this repo

	## Uncomment any local file sources (eg. CDROM, DVD)
	$(sed -i 's/deb cdrom:/#deb cdrom:/g' "$DEB_SOURCE_FILE")

	## Append repo to Debian sources file
	log_event "Checking if repository \"$1\" already exists in file \"$DEB_SOURCE_FILE\"" "info"
	if $(find_string_in_file "$1" "$DEB_SOURCE_FILE"); then
		log_event "Repository \"$1\" already exists in $DEB_SOURCE_FILE" "warn"
	else
		echo -e "$1" >> "$DEB_SOURCE_FILE"
		log_event "Added new repository \"$1\" into $DEB_SOURCE_FILE" "info"

		## Add new repo package signing key to system
		if [ -n "$2" ]; then
			wget -q "$2" -O /tmp/-
			apt-key add /tmp/-
			rm -f /tmp/-
			log_event "Added signing key for new repo ($2)" "info"
		fi

		## Update package lists
		install_pkg "update"
	fi
}

update_os_settings() {
	## Pre-seed Debian specific settings
	pre_seed "dbconfig-common" "dbconfig-common/mysql/app-pass" "password" "$MYSQL_ROOT_PASS"
	pre_seed "dbconfig-common" "dbconfig-common/mysql/admin-pass" "password" "$MYSQL_ROOT_PASS"
	pre_seed "dbconfig-common" "dbconfig-common/mysql/admin-user" "string" "root"
	pre_seed "dbconfig-common" "dbconfig-common/password-confirm" "password" "$MYSQL_ROOT_PASS"
	pre_seed "dbconfig-common" "dbconfig-common/app-password-confirm" "password" "$MYSQL_ROOT_PASS"
	pre_seed "dbconfig-common" "dbconfig-common/dbconfig-upgrade" "boolean" "false"
	pre_seed "dbconfig-common" "dbconfig-common/dbconfig-install" "boolean" "false"
	pre_seed "dbconfig-common" "dbconfig-common/upgrade-backup" "boolean" "false"
#	pre_seed "d-i" "grub-installer/bootdev" "string" "/dev/sda"
	pre_seed "grub-pc" "grub-pc/install_devices" "string" "/dev/sda"
	pre_seed "d-i" "grub-installer/only_debian" "boolean" "true"

	## Update resolv.conf file
	update_resolv_file

	## Update hosts file
	update_hosts_file

	## Disable IPv6
	if [[ $(find_string_in_file "net.ipv6.conf.all.disable_ipv6 = 1" "/etc/sysctl.conf") != 0 ]]; then
		log_event "IPv6 is already disabled in /etc/sysctl.conf" "warn"
	else
		echo -e "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
		echo -e "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
		echo -e "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
		echo -e "net.ipv6.conf.eth0.disable_ipv6 = 1" >> /etc/sysctl.conf
		$(sysctl -p)

		if [[ $(find_string_in_file "net.ipv6.conf.all.disable_ipv6 = 1" "/etc/sysctl.conf") != 0 ]]; then
			log_event "IPv6 is disabled in /etc/sysctl.conf" "info"
		else
			log_event "Unable to disable IPv6 in /etc/sysctl.conf" "fail"
		fi
	fi
	# Update mirrors and packages again
	install_pkg "update"
}

## Update OS and apply patches to core before we start doing anything
update_os
