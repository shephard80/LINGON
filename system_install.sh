#!/bin/bash
## Author: Sebastian Mueller, shephard@orbitxp.com
## Released under GNU License v3

## General Settings
USERNAME="shephard"
DC_0="se"
DC_1="2web"
DOMAIN_NAME="$DC_1.$DC_0"
HOSTNAME="nod01"
ORG_NAME="2web"
ORG_UNIT="Hosting"
ORG_ADDRESS="Alpvägen 10"
ORG_COUNTRY="SE"
ORG_ZIP="168 65"
ORG_CITY="Bromma"
ORG_TEL="08-1234567"
ADMIN_EMAIL="admin@$DOMAIN_NAME"
ADMIN_PASS="GardetArStort2017"

## Privileged system users
SYS_ROOT_PASS="$ADMIN_PASS"
MYSQL_ROOT_PASS="$ADMIN_PASS"

## SQL settings
MYSQL_USER="hosting_sql"
MYSQL_PASSWD="$ADMIN_PASS"
MYSQL_DB="hosting"
MYSQL_HOST="localhost"

## SMTP authnetication username and password for message to send after script completes
SMTP_AUTH_USER="$ADMIN_EMAIL"
SMTP_AUTH_PASSWD="$ADMIN_PASS"

#####################################################
## DO NOT EDIT BEYOND THIS POINT !!!
#####################################################

FQDN="$HOSTNAME.$DOMAIN_NAME"

## Find out where the script is and set $DIR to an absolute value
DIR=$( cd "$( dirname "$0" )" && pwd )

## Load system core
source $DIR/modules/CORE/core.sh

## Load modules
load_file $DIR/modules/WEB/web.sh
load_file $DIR/modules/PKI/pki.sh
load_file $DIR/modules/SQL/sql.sh

## Install applications
recurse_dir "$DIR/apps/" "cfg"

## Install web based applications
recurse_dir "$DIR/web/" "cfg"

## Create system users
create_user "$USERNAME" "$ADMIN_PASS"
change_root_pw "$SYS_ROOT_PASS"

## If everything is installed without error. Send an email with passwords and SSL certificates
send_email

## Display message at end of script
echo -e "REMEMBER!!!!"
echo -e "1. Change DNS PTR at GleSYS to ($WAN_IPV4 -> $DOMAIN_NAME)"
echo -e "2. Update registrar with DNS DS data in order to make DNSSEC work. Hint: pdnssec show-zone $DOMAIN_NAME"
