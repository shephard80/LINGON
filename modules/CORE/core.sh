#!/bin/bash
## Author: Sebastian Mueller, shephard@orbitxp.com
## Released under GNU License v3
######################################################
## Core functions that are shared among other scripts are to be put here
##
######################################################
## This is the script engine
import_config() {
	## Read config from $1 and put it onto $2
	## $1 = filename to read
	## $2 = filename to output
	if [ -f "$1" ]; then
		if [[ "$1" == /* ]]; then
			$(cat /dev/null > "$2")
			if [ ! -f "$2" ]; then
				echo "Destination file does not exist: $2";
				exit 0;
			fi
			while read -r line; do
				echo "$line" >> "$2"
			done < "$1"
			log_event "Writing configuration from '$1' to file: $2" "ok"
		else
			log_event "File not found: $1" "failed"
			exit 0;
		fi
	else
		echo "Source file '$1' does not exist!";
		exit 0;
	fi
}

find_file() {
	## Takes name as input and returns absolute path if file is returned. Otherwise return error.
	## $1 = filename
	## $2 = path to search
	if [ -n "$2" ]; then
		local FFP="$2"
	else
		local FFP="$DIR"
	fi

	local SR="$(find $FFP -name $1 2>/dev/null)"

	if [ -n "$SR" ]; then
		echo "$SR"
	fi
}

find_string_in_file() {
	## Takes a string $1 and tries to find it in file $2. Returns 0 if string is found
	## $1 = String to be found
	## $2 = File to be searched
	if $(grep -Fqx "$1" "$2"); then
		return 0;
	else
		return 1;
	fi
}

replace_string() {
	## Update a string in a configuration file if string $2 is not found.
	## $1 = original string to find
	## $2 = new string to update
	## $3 = file
	if $(find_string_in_file "$2" "$3"); then
		log_event "String '$2' in file $3 already exists" "info"
	else
#		echo "$1" | sed -r -e 's/[]|$*.^|[]/\\&/g'
#		echo "$2" | sed -r -e 's/[|&]/\\&/g'
		local ESCOLD=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<< "$1")
		local ESCNEW=$(sed 's/[&/\]/\\&/g' <<< "$2")
#		sed -r -i "s|$1|$2|g" "$3"
		$(sed -i.bak -r 's/'"$ESCOLD"'/'"$ESCNEW"'/g' "$3")
		if $(find_string_in_file "$1" "$3"); then
			log_event "Unable to update string '$1' in file $3" "failed"
			exit 0;
		else
			log_event "String(s) '$1' => '$ESCNEW' in file $3 are successfully updated" "ok"
		fi
		rm "$3.bak"
	fi
}

add_line() {
	## Add a line in a configuration file before or after $1 line.
	## $1 = original line to find
	## $2 = new line to add
	## $3 = file
	## $4 = 1==add line above, 2==add line below (default)

	if $(find_string_in_file "$2" "$3"); then
		log_event "String '$2' in file $3 already exists" "info"
	else
		local ESCOLD=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<< "$1")
		local ESCNEW=$(sed 's/[&/\]/\\&/g' <<< "$2")

		if [ -z "$4" ] || [ "$4" == "2" ]
		then
			local PLACE="below"
			sed -i.bak "/$ESCOLD/ a\
			$ESCNEW" "$3"
		else
			local PLACE="above"
			sed -i.bak "/$ESCOLD/ i\
			$ESCNEW" "$3"
		fi
		if $(find_string_in_file "$2" "$3")
		then
			log_event "Successfully added new line '$2' $PLACE '$1' in file $3" "ok"
		else
			log_event "Unable to add line '$2' $PLACE '$1' in file '$3'" "failed"
			exit 0;
		fi
		$(rm -f $3.bak)
	fi
}

replace_line() {
	## Update a line in a configuration file if string $1 is found.
	## $1 = original string to find
	## $2 = new string to update
	## $3 = file
	if $(find_string_in_file "$2" "$3"); then
		log_event "String '$2' in file $3 already exists" "info"
	else
		local ESCOLD=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<< "$1")
		local ESCNEW=$(sed 's/[&/\]/\\&/g' <<< "$2")
		$(sed -i.bak '/'"$ESCOLD"'/ c\'"$ESCNEW" "$3")

		if $(find_string_in_file "$2" "$3")
		then
			log_event "Lines(s) with string '$1' => '$2' in file $3 are successfully updated" "ok"
		else
			log_event "Unable to update line '$1' in file '$3'" "failed"
			exit 0;
		fi
		$(rm -f $3.bak)
	fi
}

recurse_dir() {
	## Loop through Modules directory and find modules to install
	## $1 = Path to search eg /home/user
	## $2 = File ending eg .sh, .exe
	local DIR_COUNT=0
	local FILE_COUNT=0

	for i in $(find $1 -name *.$2);
	do
		((FILE_COUNT++))
		load_file $i
	done
}

load_file() {
	log_event "=================================================" "info"
	log_event "Loading file $1" "info"
	source "$1"
	log_event "Done loading file $1" "info"
}

######################################################
## OS related functions
check_dist() {
	## Try to determine what distribution we are on and echo it as a string. Otherwise log error and exit.
	local DIST_ID=`cat /etc/*-release* | grep '^ID=' | sed 's/ID=//'`
	if [ $? = 0 ]
	then
		echo $DIST_ID
	else
		log_event "Unable to determine what distribution this is: "$? "error"
	fi
}

check_dist_version() {
	## Try to determine what distribution version we are on and echo it as a string. Otherwise log error and exit.
	local VERSION_ID=`cat /etc/*-release* | grep '^VERSION_ID=' | sed 's/VERSION_ID=//' | tr -d '"'`
	if [ $? = 0 ]
	then
		echo $VERSION_ID
	else
		log_event "Unable to determine what distribution version this is: "$? "error"
	fi
}

load_dist_config() {
	## Find out what distribution we are on
	local DIST_ID=$(check_dist)
	local VERSION_ID=$(check_dist_version)

	## Find the distribution config file
	local DIST_CONFIG=$(find_file $DIST_ID$VERSION_ID".sh")

	## Source the configuration specific for this distribution
	log_event "Loading configuration for $DIST_ID version $VERSION_ID" "info"
	log_event "Using configuration file: $DIST_CONFIG" "info"
	source $DIST_CONFIG
}

######################################################
## Logging related functions

log_event() {
	## Logs an event to console or file
	## $1 = Text string to log_event
	## $2 = Status (ok,fail,warn,info)
	local INSTALL_LOG=$DIR"/log/install-"$CURRENT_DATE".log"

	## Clear logfile only the first time this function is called
	if [ -z "$LOG_INT" ]
	then
		## Create and clear log file
		echo -e "" > $INSTALL_LOG
		LOG_INT="yes"
	fi

	## Colors in script
	#Black        0;30     Dark Gray     1;30
	#Blue         0;34     Light Blue    1;34
	#Green        0;32     Light Green   1;32
	#Cyan         0;36     Light Cyan    1;36
	#Red          0;31     Light Red     1;31
	#Purple       0;35     Light Purple  1;35
	#Brown/Orange 0;33     Yellow        1;33
	#Light Gray   0;37     White         1;37

	GREEN='\e[0;32m'
	RED='\e[0;31m'
	YELLOW='\e[1;33m'
	CYAN='\e[0;36m'
	NOCOLOR='\e[0m'
	OK="[ ${GREEN}ok${NOCOLOR} ]"
	FAILED="[ ${RED}failed${NOCOLOR} ]"
	WARN="[ ${YELLOW}warn${NOCOLOR} ]"
	INFO="[ ${CYAN}info${NOCOLOR} ]"
	ERROR="[ ${RED}error${NOCOLOR} ]"

	case "$2" in
		ok)
			STATUS="$OK"
		;;
		fail)
			STATUS="$FAILED"
		;;
		warn)
			STATUS="$WARN"
		;;
		info)
			STATUS="$INFO"
		;;
		*)
			STATUS="$ERROR"
		;;
	esac
	echo -e $STATUS" "$1"\n"
	echo -e "$(date +"$DATE_FORMAT") $1\n" >> $INSTALL_LOG
	if [ "$2" == "fail" ]; then
		exit 0;
	fi
}

#######################################################
## E-mail message related functions
send_email() {

	## Confirm that Heirloom mailx is present
	install_pkg "heirloom-mailx"

	## Loop through attachments to be added to the email
#	EMAIL_ATTACHEMENT="-a "$INSTALL_LOG
#	for i in "${EMAIL_ATTACHEMENTS[@]}"
#	do
#		EMAIL_ATTACHEMENT="$EMAIL_ATTACHEMENT -a $i"
#	done

	## Create email body header
	EMAIL_BODY="This is the result of the server installation. Se the attached files.\n\n"
	EMAIL_BODY="$EMAIL_BODY Connect to this host with the following data. \n"
	EMAIL_BODY="$EMAIL_BODY IP: ${HOST_IPV4}\n"
	EMAIL_BODY="$EMAIL_BODY DNS: ${HOSTNAME}\n\n"

	## Add system parameters that have been added by modules
#	for index in $(!MODULE_PARAMETERS)
#	do
#		EMAIL_BODY="$EMAIL_BODY $index: ${MODULE_PARAMETERS[$index]}\n"
#	done

	## Add email body footer
	EMAIL_BODY="$EMAIL_BODY \n"
	EMAIL_BODY="$EMAIL_BODY Regards,\n"
	EMAIL_BODY="$EMAIL_BODY Your script\n"
	echo -e "$EMAIL_BODY" | mailx -v -s "Report of installation on $FQDN" -S smtp-use-starttls -S ssl-verify=ignore -S smtp-auth=login -S smtp=smtp://"$HOST_IPV4":587 -S from="$ADMIN_EMAIL" -S smtp-auth-user="$SMTP_AUTH_USER" -S smtp-auth-password="$SMTP_AUTH_PASSWD" "$ADMIN_EMAIL"
}

## Declare variables
DATE_FORMAT="%Y-%m-%d %T"
CURRENT_DATE=$(date +%Y%m%d)
log_event "Setting date to: "$CURRENT_DATE "info"

## Set local host IP (LAN IP)
declare HOST_IPV4=$(echo $(hostname -I) | cut -f2 -d " ")
if [ -z $HOST_IPV4 ]
then
	log_event "Unable to determine host IP!" "failed"
	exit 0;
else
	log_event "Setting host IPv4 to: $HOST_IPV4" "ok"
fi

## Set remote host IP (WAN IP)
declare WAN_IPV4=$(wget -q -O - checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//' | xargs)
if [ -z $WAN_IPV4 ]
then
	log_event "Unable to determine WAN IP!" "failed"
	exit 0;
else
	log_event "Setting WAN IPv4 to: $WAN_IPV4" "ok"
fi

## When this script is loaded run the following functions
load_dist_config
