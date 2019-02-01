#!/bin/bash
## Author: Sebastian Mueller, shephard@orbitxp.com
## Released under GNU License v3
##
## Exports the following functions:
## check_sql_user
## check_sql_database
## create_sql_user
## create_sql_database
## set_sql_privileges
## import_sql_file
## install_sql

check_sql_database() {
	## Check if database $1 exists. If found echo "FOUND"
	## $1 = SQL database name
	while read Database; do
		if [ "$1" == "$Database" ]; then
			echo "FOUND"
		fi
	done < <(mysql -B -N -uroot -p"$MYSQL_ROOT_PASS" -h"$MYSQL_HOST" -e "SHOW DATABASES;")
}

check_sql_user() {
	## Check if user $1 $2 exists. If found echo "FOUND"
	## $1 = username
	## $2 = host
	local SQL="USE mysql; SELECT User FROM user WHERE Host=\"$2\";"
	while read User; do
		if [ "$1" == "$User" ]; then
			echo "FOUND"
		fi
	done < <(mysql -B -N -uroot -p"$MYSQL_ROOT_PASS" -h"$MYSQL_HOST" -e"$SQL")
}

create_sql_database() {	
	## Check if database $1 exists. Create an empty database with name $1 if it does not exist.
	## $1 = SQL database name
	if [ "$(check_sql_database $1)" == "FOUND" ]; then
		log_event "Database ($1) already exists" "warn"
	else
		local CREATE_DB="CREATE DATABASE $1;"
		echo "$CREATE_DB" | mysql -uroot -p"$MYSQL_ROOT_PASS" -h"$MYSQL_HOST"
		log_event "Creating database with command: $CREATE_DB" "info"
		
		if [ "$(check_sql_database $1)" == "FOUND" ]; then
			log_event "Database $1 successfully created" "ok"
		else
			log_event "Failed to create database $1" "failed"
			exit 0;
		fi
	fi
}

create_sql_user() {
	## Create $1 SQL user. If successfully then return boolean TRUE, otherwise FALSE
	## $1 = username
	## $2 = password
	## $3 = host
	## $4 = database
	## $5 = db privileges as string (eg. SELECT, INSERT)
	if [ "$(check_sql_user $1 $3)" == "FOUND" ]; then
		log_event "SQL user ($1) on $3 already exists" "warn"
	else
		local CREATE_USER="CREATE USER '$1'@'$3' IDENTIFIED BY '$2';"
		log_event "Creating SQL user with command: \"$CREATE_USER\"" "info"
		echo "$CREATE_USER" | mysql -uroot -p"$MYSQL_ROOT_PASS" -h"$MYSQL_HOST"
		set_sql_privileges "$1" "$3" "$4" "$5"
	fi
}

set_sql_privileges() {
	## Sets the rights to the database schema for a user.
	## $1 = user
	## $2 = host
	## $3 = db
	## $4 = privileges (eg. SELECT, INSERT. If empty = ALL)

	if [ "$(check_sql_user $1 $2)" == "FOUND" ]; then
		if [ -z "$4" ]; then
			local PRIV="ALL"
		else
			local PRIV="$4"
		fi
		local SQL_GRANT_USER="GRANT $PRIV ON $3.* TO '$1'@'$2';"
		log_event "Setting SQL user privileges with command: \"$SQL_GRANT_USER\"" "info"
		echo "$SQL_GRANT_USER" | mysql -uroot -p"$MYSQL_ROOT_PASS" -h"$MYSQL_HOST"
		echo "FLUSH PRIVILEGES" | mysql -uroot -p"$MYSQL_ROOT_PASS" -h"$MYSQL_HOST"

		log_event "SQL privileges \"$4\" on user \"$1\" set" "info"
	else
		log_event "Failed to set privileges \"$4\" for user \"$1\" on \"$3\"" "failed"
		exit 0;
	fi
}

import_sql_file() {
	## Import .sql file into SQL $2 database
	## $1 = SQL file
	## $2 = database to import into
	local SQL_FILE="$(find_file $1)"
	import_config "$SQL_FILE" "$SQL_FILE.new"
	
	if [ ! $(find_string_in_file "<DOMAIN_NAME>" "$SQL_FILE.new") ]
	then
		replace_string "<DOMAIN_NAME>" "$DOMAIN_NAME" "$SQL_FILE.new"
	fi
	if [ ! $(find_string_in_file "<ADMIN_EMAIL>" "$SQL_FILE.new") ]
	then
		replace_string "<ADMIN_EMAIL>" "$ADMIN_EMAIL" "$SQL_FILE.new"
	fi
	if [ ! $(find_string_in_file "<HOST_IPV4>" "$SQL_FILE.new") ]
	then
		replace_string "<HOST_IPV4>" "$HOST_IPV4" "$SQL_FILE.new"
	fi
	if [ ! $(find_string_in_file "<WAN_IPV4>" "$SQL_FILE.new") ]
	then
		replace_string "<WAN_IPV4>" "$WAN_IPV4" "$SQL_FILE.new"
	fi
	if [ ! $(find_string_in_file "<ORG_NAME>" "$SQL_FILE.new") ]
	then
		replace_string "<ORG_NAME>" "$ORG_NAME" "$SQL_FILE.new"
	fi
	if [ ! $(find_string_in_file "<ORG_ADDRESS>" "$SQL_FILE.new") ]
	then
		replace_string "<ORG_ADDRESS>" "$ORG_ADDRESS" "$SQL_FILE.new"
	fi
	if [ ! $(find_string_in_file "<ORG_CITY>" "$SQL_FILE.new") ]
	then
		replace_string "<ORG_CITY>" "$ORG_CITY" "$SQL_FILE.new"
	fi
	if [ ! $(find_string_in_file "<ORG_COUNTRY>" "$SQL_FILE.new") ]
	then
		replace_string "<ORG_COUNTRY>" "$ORG_COUNTRY" "$SQL_FILE.new"
	fi
	if [ ! $(find_string_in_file "<ORG_ZIP>" "$SQL_FILE.new") ]
	then
		replace_string "<ORG_ZIP>" "$ORG_ZIP" "$SQL_FILE.new"
	fi
	if [ ! $(find_string_in_file "<ORG_TEL>" "$SQL_FILE.new") ]
	then
		replace_string "<ORG_TEL>" "$ORG_TEL" "$SQL_FILE.new"
	fi
	if [ ! $(find_string_in_file "<SYS_ROOT_PASS>" "$SQL_FILE.new") ]
	then
		replace_string "<SYS_ROOT_PASS>" "$SYS_ROOT_PASS" "$SQL_FILE.new"
	fi
	if [ ! $(find_string_in_file "<SYS_SALT>" "$SQL_FILE.new") ]
	then
		replace_string "<SYS_SALT>" "$SYS_SALT" "$SQL_FILE.new"
	fi
	
	mysql -uroot -p"$MYSQL_ROOT_PASS" -h"$MYSQL_HOST" "$2" < "$SQL_FILE.new"

	if [ $? -eq 0 ]; then
		log_event "SQL file ($1) successfully imported into database: $2" "ok"
	else
		log_event "Unable to import SQL file: $1 into database $2" "fail"
		exit 0;
	fi
	rm -f "$SQL_FILE.new"
}

install_sql() {
	## Installs a SQL database (usually MySQL)
	source "$DIR/modules/SQL/MySQL/mysql.cfg"
}

install_sql
