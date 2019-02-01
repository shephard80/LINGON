#!/bin/bash
## Author: Sebastian Mueller, shephard@orbitxp.com
## Released under GNU License v3
##
## Install web-based apps
##
TEMP_DIR="/tmp"
WEB_DIR="/home/hosting/$DOMAIN_NAME/htdocs"
WEB_CACHE="/var/www"

downloadPkg() {
	## Use wget to download a package from the web
	## $1 = URL
	## $2 = Filename to save
	if [ -n "$2" ]
	then
		local WEB_STR="--max-redirect=5 --content-disposition -P $DOWNLOAD_DIR -c $1 -O $2"
	else
		local WEB_STR="--max-redirect=5 --content-disposition -P $DOWNLOAD_DIR -c $1"
	fi
	if ($(wget $WEB_STR)); then
		log_event "File successfully downloaded" "ok"
	else
		log_event "Unable to download file" "fail"
		exit 0;
	fi
}

getFileExtension() {
	## Extract the file extension from filename
	## $1 = Filename
	local FILENAME=$(basename "$1")
	local EXTENSION1="${FILENAME##*.}"
	local FILENAME="${FILENAME%.*}"
	local EXTENSION2="${FILENAME##*.}"
	if [ "$EXTENSION2" = "tar" ]; then
		local EXTENSION="$EXTENSION2.$EXTENSION1"
	else
		local EXTENSION="$EXTENSION1"
	fi
	echo "$EXTENSION"
}

extractPkg() {
	## $1 = Source to extract (file)
	## $2 = Package name (destination dir, eg, phpMyAdmin)
	if [ ! -d "$WEB_DIR/$2" ]; then
		if  $(mkdir -p "$WEB_DIR/$2")
		then
			if [ -d "$WEB_DIR/$2" ]; then
				log_event "Created dir $WEB_DIR/$2" "ok"
				setDirPermissions "$WEB_DIR/$2" "www-data:www-data" "644"
			else
				log_event "Unable to create dir $WEB_DIR/$2" "fail"
				exit 0;
			fi
		else
			log_event "Unable to create dir $WEB_DIR/$2" "fail"
			exit 0;
		fi
	fi
	
	case "$(getFileExtension "$1")" in
		"tar.gz")
			tar -zxf "$DOWNLOAD_DIR/$1" -C "$WEB_DIR/$2"
			log_event "Extracted $1 file into $WEB_DIR/$2" "info"
		;;
		"xz")
			tar -xJf "$DOWNLOAD_DIR/$1" -C "$WEB_DIR/$2"
			log_event "Extracted $1 file into $WEB_DIR/$2" "info"
		;;
		"tar.xz")
			tar -xJf "$DOWNLOAD_DIR/$1" -C "$WEB_DIR/$2"
			log_event "Extracted $1 file into $WEB_DIR/$2" "info"
		;;
		"tgz")
			tar -zxf "$DOWNLOAD_DIR/$1" -C "$WEB_DIR/$2"
			log_event "Extracted $1 file into $WEB_DIR/$2" "info"
		;;
		"tar.bz2")
			tar -xjf "$DOWNLOAD_DIR/$1" -C "$WEB_DIR/$2"
			log_event "Extracted $1 file into $WEB_DIR/$2" "info"
		;;
		"bz2")
			tar -xjf "$DOWNLOAD_DIR/$1" -C "$WEB_DIR/$2"
			log_event "Extracted $1 file into $WEB_DIR/$2" "info"
		;;
		"zip")
			unzip -o -q "$DOWNLOAD_DIR/$1" -d "$WEB_DIR/$2"
			log_event "Extracted $1 file into $WEB_DIR/$2" "info"
		;;
		*)
		log_event "Unable to determine file extension" "fail"
		exit 0;
	esac
}

setDirPermissions() {
	## Sets the directory permissions (chmod & chown)
	## $1 = Dir or file
	## $2 = owner:group
	## $3 = Mode (eg. 644, 755, ugoa)
	if chown "$2" -R "$1"
	then
		log_event "Successfully set ownership on $1" "ok"
	else
		log_event "Unable to set ownership $2 on $1" "failed"
		exit 0;
	fi
	
	if chmod "$3" -R "$1"
	then
		log_event "Successfully set mode on $1" "ok"
	else
		log_event "Unable to set file mode $3 on $1" "failed"
		exit 0;
	fi
}

getUserIDfromDir() {
	## $1 = Path to scan
	
	echo $(stat -c %u "$1")
}

getDomainIDfromDomain() {
	## $1 = Domainname
	
	echo $(mysql "$MYSQL_DB" -u "$MYSQL_USER" -p"$MYSQL_PASSWD" -e "SELECT domain_id FROM domain_data WHERE domain_name = '$1'" -B -N)
}

installWebPkg() {
	## $1 = Download URL
	## $2 = Package name
	## $3 = Filename to save

	DOWNLOAD_DIR="$TEMP_DIR/$2"
	$(mkdir -p "$DOWNLOAD_DIR")

	## Download the file
	downloadPkg "$1" "$3"
	
	## Find file that was just downloaded
	FILE="$(ls "$DOWNLOAD_DIR")"
	
	## Extract the package depending on file ending
	extractPkg "$FILE" "$2"
	
	## Empty temporary download dir
	$(rm -rf "$DOWNLOAD_DIR")
	log_event "Deleted file $DOWNLOAD_DIR" "info"
	
	## Set directory permissions
	setDirPermissions "$WEB_DIR/$2" "www-data:www-data" "755"
}