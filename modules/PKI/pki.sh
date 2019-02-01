#!/bin/bash
## Author: Sebastian Mueller, shephard@orbitxp.com
## Released under GNU License v3
##
## PKI infrastrucure
## All SSL based servers & email depend on this
## Based on: pki-tutorial.readthedocs.org
##
## Export the following functions:
## create_ca
## create_cert
## exportCertPEM
## exportCertP12
## exportCertDER
## exportCertRSA
##
SSL_DIR="/etc/ssl"
#SSL_DIR_CA=$SSL_DIR"/ca"
#SSL_DIR_CERT=$SSL_DIR"/certs/"
SSL_PASSKEY="abc123"
SSL_CA_DAYS=3650
SSL_START_DATE=$(date -d "1 day ago" +%Y%m%d%H%M%S)"Z"

#MODULE_PARAMETERS+=([SSL_CA_passkey]=$SSL_CA_PASSKEY [SSL_CA_validity_days]=$SSL_CA_DAYS)
#EMAIL_ATTACHEMENTS+=()

importFileCA() {
	## Imports CA .conf file into /etc/ssl/etc and replaces variables (eg. <DOMAIN_NAME>)
	## $1 = Type of CA (eg. root, signing, etc.)
	##
	## Note that a pre-configured openssl_*_CA.config file must exist before running this script
	## Also note that openssl_root_CA.config must contain [ *_ca_ext ] section
	local CONFIG_CA_DST=$SSL_DIR"/etc/$1-ca.conf"
	
	if [ -e "$CONFIG_CA_DST" ]; then
		log_event "$1 CA config file already exists: ($CONFIG_CA_DST)" "warn"
		rm -f "$CONFIG_CA_DST"
		if [ ! -e "$CONFIG_CA_DST" ]; then
			log_event "Sucessfully deleted old $1 CA config file: ($CONFIG_CA_DST)" "ok"
		fi
		importFileCA "$1"
	else
		local CONFIG_CA_SRC=$(find_file "openssl_$1_CA.conf")
		import_config "$CONFIG_CA_SRC" "$CONFIG_CA_DST"
		
		if [ -e "$CONFIG_CA_DST" ]; then
			log_event "$1 CA config file successfully imported: ($CONFIG_CA_DST)" "ok"
			
			if $(find_string_in_file "<SSL_DIR>" "$CONFIG_CA_DST")
			then
				log_event "Unable to find <SSL_DIR> string" "warn"
				exit 0;
			else
				replace_string "<SSL_DIR>" "$SSL_DIR" "$CONFIG_CA_DST"
			fi
			
			if $(find_string_in_file "<SSL_CA_DAYS>" "$CONFIG_CA_DST")
			then
				log_event "Unable to find <SSL_CA_DAYS> string" "warn"
				exit 0;
			else
				replace_string "<SSL_CA_DAYS>" "$SSL_CA_DAYS" "$CONFIG_CA_DST"
			fi
			
			if $(find_string_in_file "<SSL_PASSKEY>" "$CONFIG_CA_DST")
			then
				log_event "Unable to find <SSL_PASSKEY> string" "warn"
				exit 0;
			else
				replace_string "<SSL_PASSKEY>" "$SSL_PASSKEY" "$CONFIG_CA_DST"
			fi
		else
			log_event "Unable to create $1 CA file: $CONFIG_CA_DST" "fail"
			exit 0;
		fi
	fi
}

create_ca_crl() {
	## Create initial CRL (Certificate Revocation List)
	## $1 = Type of revocation list (root, signing, etc.)
	local CRL_FILE="$SSL_DIR/crl/$1-ca.crl"
	local CRL_CONF_FILE="$SSL_DIR/etc/$1-ca.conf"

	if [ ! -e "$CRL_FILE" ]; then
		$(openssl ca -gencrl -config $CRL_CONF_FILE -out $CRL_FILE)
		log_event "$1 CA CRL created" "info"
	else
		log_event "$1 CA CRL already exists: $CRL_FILE" "warn"
	fi
}

createDirStructure() {
	## Create SSL directories
	## $1 = Type of cert (eg. root, signing)
	local PRIVATE="$SSL_DIR/ca/$1-ca/private"
	if [ ! -d "$PRIVATE" ]; then
		$(mkdir -p "$PRIVATE")
		if [ -d "$PRIVATE" ]; then
			log_event "Successfully created dir: $PRIVATE" "ok"
		else
			log_event "Unable to create dir: $PRIVATE" "fail"
			exit 0;
		fi
	fi

	local DB="$SSL_DIR/ca/$1-ca/db"
	if [ ! -d "$DB" ]; then
		$(mkdir -p "$DB")
		if [ -d "$DB" ]; then
			log_event "Successfully created dir: $DB" "ok"
		else
			log_event "Unable to create dir: $DB" "fail"
			exit 0;
		fi
	fi

	local CRL="$SSL_DIR/crl"
	if [ ! -d "$CRL" ]; then
		$(mkdir -p "$CRL")
		if [ -d "$CRL" ]; then
			log_event "Successfully created dir: $CRL" "ok"
		else
			log_event "Unable to create dir: $CRL" "fail"
			exit 0;
		fi
	fi

	local CERTS="$SSL_DIR/certs"
	if [ ! -d "$CERTS" ]; then
		$(mkdir -p "$CERTS")
		if [ -d "$CERTS" ]; then
			log_event "Successfully created dir: $CERTS" "ok"
		else
			log_event "Unable to create dir: $CERTS" "fail"
			exit 0;
		fi
	fi

	local ETC="$SSL_DIR/etc"
	if [ ! -d "$ETC" ]; then
		$(mkdir -p "$ETC")
		if [ -d "$ETC" ]; then
			log_event "Successfully created dir: $ETC" "ok"
		else
			log_event "Unable to create dir: $ETC" "fail"
			exit 0;
		fi
	fi
}

createCADatabase() {
	## Create CA database
	## $1 = Type of CA cert (eg. root, signing)
	local BASE_DB="$SSL_DIR/ca/$1-ca/db/$1-ca.db"
	
	if [ ! -e "$BASE_DB" ]; then
		$(cp /dev/null "$BASE_DB")
		if [ -e "$BASE_DB" ]; then
			log_event "Created database: $BASE_DB" "ok"
		else
			log_event "Unable to create database: $BASE_DB" "fail"
			exit 0;
		fi
	fi
	
	local BASE_ATTR="$SSL_DIR/ca/$1-ca/db/$1-ca.db.attr"
	if [ ! -e "$BASE_ATTR" ]; then
		$(cp /dev/null "$BASE_ATTR")
		if [ -e "$BASE_ATTR" ]; then
			log_event "Created database: $BASE_ATTR" "ok"
		else
			log_event "Unable to create database: $BASE_ATTR" "fail"
			exit 0;
		fi
	fi
	
	local BASE_CRT="$SSL_DIR/ca/$1-ca/db/$1-ca.crt.srl"
	if [ ! -e "$BASE_CRT" ]; then
		$(echo 01 > "$BASE_CRT")
		if [ -e "$BASE_CRT" ]; then
			log_event "Created database: $BASE_CRT" "ok"
		else
			log_event "Unable to create database: $BASE_CRT" "fail"
			exit 0;
		fi
	fi
	
	local BASE_CRL="$SSL_DIR/ca/$1-ca/db/$1-ca.crl.srl"
	if [ ! -e "$BASE_CRL" ]; then
		$(echo 01 > "$BASE_CRL")
		if [ -e "$BASE_CRL" ]; then
			log_event "Created database: $BASE_CRL" "ok"
		else
			log_event "Unable to create database: $BASE_CRL" "fail"
			exit 0;
		fi
	fi
}

create_ca_request() {
	## Create CA (Certificate Authority) request
	## $1 = Type of CA (eg. root, signing)
	
	local CSR_FILE="$SSL_DIR/ca/$1-ca.csr"
	local KEY_FILE="$SSL_DIR/ca/$1-ca/private/$1-ca.key"
	
	if [ -e "$CSR_FILE" ]; then
		log_event "$1 CA request already exists" "warn"
		if $(rm -f "$CSR_FILE"); then
			log_event "Successfully deleted old $1 CA request file: ($CSR_FILE)" "info"
		else
			log_event "Unable to delete file: $CSR_FILE" "fail"
		fi
		if $(rm -f "$KEY_FILE"); then
			log_event "Successfully deleted old $1 CA key file: ($KEY_FILE)" "info"
		else
			log_event "Unable to delete file: $KEY_FILE" "fail"
		fi
		create_ca_request "$1"
	else
		log_event "$1 CA request does not exist. Attempting to create a new one." "ok"
		if [ "$1" != "root" ]; then
			if ! $(openssl req -new -nodes -config "$SSL_DIR/etc/$1-ca.conf" -out "$CSR_FILE" -keyout "$KEY_FILE"); then
				log_event "Unable to create $1 CA request or key: CSR=$CSR_FILE, KEY=$KEY_FILE" "fail"
			else
				if [ -e "$KEY_FILE" ]; then
					log_event "Private key for $1: $KEY_FILE" "ok"				
				else
					log_event "Private key for $1 not found: $KEY_FILE" "fail"
				fi
				if [ -e "$CSR_FILE" ]; then
					log_event "CSR for $1: $CSR_FILE" "ok"					
				else
					log_event "CSR for $1 not found: $CSR_FILE" "fail"
				fi
			fi
		fi
	fi
}

createCAChain() {
	## Create the CA chain to be included in other certs.
	## $1 = CA cert to be added
	
	local ROOT_FILE="/etc/ssl/ca/root-ca.crt"
	local INTERMEDIATE_FILE="/etc/ssl/ca/$1-ca.crt"
	local CHAIN_FILE="/etc/ssl/ca/ca-chain.crt"

	if [ -e "$CHAIN_FILE" ]; then
		if $(rm -rf "$CHAIN_FILE"); then
			log_event "CA chain file deleted: $CHAIN_FILE" "ok"
		else
			log_event "Unable to delete chain file: $CHAIN_FILE" "fail"
		fi
		createCAChain "$1"
	else
		if $(cat "$INTERMEDIATE_FILE" "$ROOT_FILE" > "$CHAIN_FILE"); then
			log_event "Added $INTERMEDIATE_FILE CA cert to CA chain: $CHAIN_FILE" "ok"
		else
			log_event "Unable to create CA chain file: $CHAIN_FILE" "fail"
		fi
	fi
}

createCertChain() {
	## Adds CA cert chain to certificate.
	## $1 = Certificate
	
	local CERT_FILE="/etc/ssl/certs/$1.crt"
	local CA_CHAIN_FILE="/etc/ssl/ca/ca-chain.crt"
	local CERT_CHAIN_FILE="/etc/ssl/certs/$1-chain.crt"

	if [ -e "$CA_CHAIN_FILE" ]; then
		if $(cat "$CERT_FILE" "$CA_CHAIN_FILE" > "$CERT_CHAIN_FILE"); then
			log_event "Added CA chain to $CERT_FILE into file: $CERT_CHAIN_FILE" "ok"
		fi
	else
		createCAChain "signing"
		createCertChain "$1"
	fi
}

signCA() {
	## Create CA (Certificate Authority) certificate
	## $1 = Type of CA cert
	local CERT_FILE=$SSL_DIR"/ca/$1-ca.crt"
	local CSR_FILE=$SSL_DIR"/ca/$1-ca.csr"
	local CONF_FILE=$SSL_DIR"/etc/$1-ca.conf"
	local KEY_FILE=$SSL_DIR"/ca/$1-ca/private/$1-ca.key"

	if [ ! -e "$CERT_FILE" ]; then
		if [ "$1" = "root" ]; then
			## Selfsign the Root CA certificate
			if $(openssl req -x509 -nodes -newkey rsa:2048 -config "$CONF_FILE" -keyout "$KEY_FILE" -out "$CERT_FILE" -extensions "$1_ca_ext"); then
				log_event "Created self-signed $1 CA certificate: $CERT_FILE" "ok"
			else
				log_event "Unable to create self-signed $1 CA certificate: $CERT_FILE" "fail"
			fi
		else
			## Sign the certificate using the settings in the root-ca.conf file
			if $(openssl ca -batch -config "$SSL_DIR/etc/root-ca.conf" -in "$CSR_FILE" -out "$CERT_FILE" -extensions "$1_ca_ext"); then
				log_event "Created $1 CA certificate: $CERT_FILE" "ok"
			else
				log_event "Unable to create $1 CA certificate: $CERT_FILE" "fail"
			fi
			createCAChain "$1"
		fi
	else
		log_event "$1 CA certificate already exits" "warn"
		rm -f "$CERT_FILE"
		if [ ! -e "$CERT_FILE" ]; then
			log_event "Successfully deleted old $1 CA certificate: ($CERT_FILE)" "ok"
		fi
		signCA "$1"
	fi
}

createRequest() {
	## Create SSL request
	## $1 = Type of signing (signing, root, etc.)
	## $2 = Name of the request
	local KEY_FILE=$SSL_DIR"/certs/$1.key"
	local CSR_FILE=$SSL_DIR"/certs/$1.csr"
	local CONF_FILE=$SSL_DIR"/etc/$2.conf"
	local SUB="/DC=$DC_0/DC=$DC_1/DC=$HOSTNAME/C=$ORG_COUNTRY/ST=VG/L=$ORG_CITY/O=$ORG_NAME/OU=$ORG_UNIT/CN=$1/emailAddress=$ADMIN_EMAIL"

	case "$2" in
		tls)
			## Set SAN (subjectAltName) DNS variable
			$(SET_VAR01="export SAN=DNS:"$FQDN)
		;;
	esac
	
	if [ -e "$CSR_FILE" ]; then
		log_event "$2 certificate request already exists: ($CSR_FILE)" "warn"
	else
		$(openssl req -newkey rsa:2048 -nodes -out "$CSR_FILE" -keyout "$KEY_FILE" -subj "$SUB" -days "$SSL_CA_DAYS")
		if [ -e "$CSR_FILE" ]; then
			log_event "Created $2 certificate request: ($CSR_FILE)" "ok"
		else
			log_event "Unable to create $2 certificate request: $REQ_FILE" "fail"
		fi
		if [ -e "$KEY_FILE" ]; then
			log_event "Created $2 certificate key: ($KEY_FILE)" "ok"
			
			## Convert key into PKCS#1 format
			exportKeyRSA $1
		else
			log_event "Unable to create $2 certificate key: $KEY_FILE" "fail"
		fi
	fi
}

signRequest() {
	## Sign the SSL certificate
	## $1 = Certificate name
	## $2 = Type of cert
	local CERT_FILE="$SSL_DIR/certs/$1.crt"
	local CSR_FILE="$SSL_DIR/certs/$1.csr"
	local CONF_FILE="$SSL_DIR/etc/signing-ca.conf"

	case "$2" in
		email)
			local EXTENSIONS="email_ext"
		;;
		tls)
			local EXTENSIONS="server_ext"
		;;
	esac
	
	if [ -e "$CERT_FILE" ]; then
		log_event "$1 certificate already exists: ($CERT_FILE)" "info"
		if $(rm -f "$CERT_FILE"); then
			log_event "Deleted cert file: $CERT_FILE" "ok"
			signRequest "$1" "$2"
		else
			log_event "Unable to delete file:  $CERT_FILE" "fail"
		fi
	else
		if ! $(openssl x509 -req -in "$CSR_FILE" -CA /etc/ssl/ca/signing-ca.crt -CAkey /etc/ssl/ca/signing-ca/private/signing-ca.key -out "$CERT_FILE" -set_serial 01); then
			log_event "Unable to create new $1 certificate: $CERT_FILE" "fail"
		else
			log_event "$1 certificate successfully created: ($CERT_FILE)" "ok"
		fi
	fi
	
	## Add certificate chain
	createCertChain "$1"

	## Verify the certificates
	if [ "$(openssl verify -CAfile /etc/ssl/ca/ca-chain.crt $SSL_DIR/certs/$1-chain.crt)" == "$SSL_DIR/certs/$1-chain.crt: OK" ]; then
		log_event "Created, signed and verified $1 certificate: ($SSL_DIR/certs/$1-chain.crt)" "ok"
	else
		log_event "Unable to verify $SSL_DIR/certs/$1-chain.crt" "fail"
	fi
}

importFileCSR() {
	## Imports CSR .conf file into /etc/ssl/etc and replaces variables <DOMAIN_NAME>
	## $1 = SSL CSR config (eg. tls, email, etc.)
	local CONFIG_CSR_DST=$SSL_DIR"/etc/$1.conf"
	
	if [ -e "$CONFIG_CSR_DST" ]; then
		log_event "$1 CSR config file already exists: ($CONFIG_CSR_DST)" "warn"
		rm -f "$CONFIG_CSR_DST"
		if [ ! -e "$CONFIG_CSR_DST" ]; then
			log_event "Sucessfully deleted old $1 CSR config file: ($CONFIG_CSR_DST)" "ok"
		fi
		importFileCSR "$1"
	else
		local CONFIG_CSR_SRC=$(find_file "openssl_$1_CSR.conf")
		import_config "$CONFIG_CSR_SRC" "$CONFIG_CSR_DST"
		
		if [ -e "$CONFIG_CSR_DST" ]; then
			log_event "$1 CSR config file successfully imported: ($CONFIG_CSR_DST)" "ok"
			
			if $(find_string_in_file "<DOMAIN_NAME>" "$CONFIG_CSR_DST")
			then
				replace_string "<DOMAIN_NAME>" "$DOMAIN_NAME" "$CONFIG_CSR_DST"
			fi
			
			if $(find_string_in_file "<ADMIN_EMAIL>" "$CONFIG_CSR_DST")
			then
				replace_string "<ADMIN_EMAIL>" "$ADMIN_EMAIL" "$CONFIG_CSR_DST"
			fi
			
			if $(find_string_in_file "<SSL_DIR>" "$CONFIG_CSR_DST")
			then
				replace_string "<SSL_DIR>" "$SSL_DIR" "$CONFIG_CSR_DST"
			fi
			
			if $(find_string_in_file "<SSL_CA_DAYS>" "$CONFIG_CSR_DST")
			then
				replace_string "<SSL_CA_DAYS>" "$SSL_CA_DAYS" "$CONFIG_CSR_DST"
			fi
			
		else
			log_event "Unable to create $1 CSR file: $CONFIG_CSR_DST" "fail"
			exit 0;
		fi
	fi
}

setFilePermissions() {
	## Ownership of file so that only owner can read and execute
	## $1 = File with absolute path

	$(chmod o+rx $1)
	$(chmod g-rwx $1)
	$(chmod a-rwx $1)
	log_event "Changed permissions on file ($1) to only read and execute for owner" "info"
}

addKeyToCert(){
	## Adds the private key to the certificate
	## $1 = Name of the service (eg. mysql-server)
	local KEY_FILE="$SSL_DIR/certs/$1.key"
	local CERT_FILE="$SSL_DIR/certs/$1.crt"
	
	if [ ! -e "$CERT_FILE" ]; then
		log_event "Unable to find PEM certificate: $CERT_FILE" "fail"
		exit 0;
	else
		if [ ! -e "$KEY_FILE" ]; then
			log_event "Unable to find key file: $KEY_FILE" "fail"
			exit 0;
		else
			cat "$KEY_FILE" >> "$CERT_FILE"
			log_event "Added key file ($KEY_FILE) to certificate: $CERT_FILE" "ok"
			setFilePermissions "$CERT_FILE"
		fi
	fi
}

exportCertDER() {
	## Exports a DER certificate to be published
	## $1 = Name of service
	local CERT_FILE=$SSL_DIR"/certs/$1.crt"
	local DER_FILE=$SSL_DIR"/certs/$1.der"
	
	if [ -e "$DER_FILE" ]; then
		log_event "DER file already exists: $DER_FILE" "warn"
	else
		if [ ! -e "$CERT_FILE" ]; then
			log_event "Unable to find certificate file: $CERT_FILE" "fail"
			exit 0;
		fi

		## Export DER file
		$(openssl x509 -in "$CERT_FILE" -out "$DER_FILE" -outform der)

		if [ -e "$DER_FILE" ]; then
			log_event "Successfully exported certificate into DER format: $DER_FILE" "ok"
		else
			log_event "Unable to export certificate into DER format: $DER_FILE" "fail"
			exit 0;
		fi
	fi
}

exportCertPEM() {
	## Exports key and certificate into a PEM file
	## $1 = Name of service
	local KEY_FILE=$SSL_DIR"/certs/$1.key"
	local CERT_FILE=$SSL_DIR"/certs/$1.crt"
	local PEM_FILE=$SSL_DIR"/certs/$1.pem"
	
	if [ -e "$PEM_FILE" ]; then
		log_event "PEM file already exists: $PEM_FILE" "warn"
	else
		if [ ! -e "$KEY_FILE" ]; then
			log_event "Key file not found: $KEY_FILE" "fail"
			exit 0;
		fi	
		if [ ! -e "$CERT_FILE" ]; then
			log_event "Certificate file not found: $CERT_FILE" "fail"
			exit 0;
		fi

		## Create PEM chain
		cat "$KEY_FILE" "$CERT_FILE" > "$PEM_FILE"
		
		if [ -e "$PEM_FILE" ]; then
			log_event "Successfully exported certificate into PEM format: $PEM_FILE" "ok"
		else
			log_event "Unable to export certificate into PEM format: $PEM_FILE" "fail"
			exit 0;
		fi
	fi
}

exportKeyRSA() {
	## Exports key into RSA compatible file
	## $1 = Input file
	local KEY_FILE=$SSL_DIR"/certs/$1.key"

	if $(openssl rsa -in "$KEY_FILE" -out "$KEY_FILE")
	then
		log_event "Successfully exported key into PKCS#1 format: $KEY_FILE" "ok"
	else
		log_event "Unable to export key into PKCS#1 format: $KEY_FILE" "fail"
		exit 0;
	fi
}

exportCertP12() {
	## Exports a PEM into a PKCS12 (.p12) cert
	## $1 = Service name
	local IN_PEM=$SSL_DIR"/certs/$1.pem"
	local IN_KEY=$SSL_DIR"/certs/$1.key"
	local OUT_P12=$SSL_DIR"/certs/$1.p12"

	if [ -e "$OUT_P12" ]; then
		log_event "P12 file already exists: $OUT_P12" "warn"
	else
		if [ ! -e "$IN_KEY" ]; then
			log_event "Key file not found: $IN_KEY" "fail"
			exit 0;
		fi
		if [ ! -e "$IN_PEM" ]; then
			log_event "PEM file not found: $IN_PEM" "fail"
			exit 0;
		fi
		
		## Create pkcs12 file
		$(openssl pkcs12 -export -in $IN_PEM -inkey $IN_KEY -out $OUT_P12 -name $1 -password pass:$SSL_PASSKEY)

		if [ -e "$OUT_P12" ]; then
			log_event "Successfully exported certificate into PKCS12 format: $OUT_P12" "ok"
		else
			log_event "Unable to export certificate into PKCS12 format: $OUT_P12" "fail"
			exit 0;
		fi
	fi
}

create_ca() {
	###########################################
	## Create CA (Certificate Authority)
	## $1 = type of CA (root, signing, etc.)

	createDirStructure $1
	createCADatabase $1
	importFileCA $1
	create_ca_request $1
	signCA $1
}

createCertificate() {
	## Creates a SSL certificate for server use in PEM format. Requires that the PKI infrastructure is already present.
	## Takes the following argument:
	## $1 = Name of the service (eg. mysql-server)

#	EMAIL_ATTACHEMENTS+=($SSL_PEM)
	importFileCSR "tls"
	createRequest "$1" "tls"
	signRequest "$1" "tls"
	addKeyToCert "$1"
}

## Install OpenSSL binary
install_pkg openssl

## Create CA certs
create_ca "root"
create_ca "signing"
update_certs