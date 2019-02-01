<?php

/* Local configuration for Roundcube Webmail */

// ----------------------------------
// SQL DATABASE
// ----------------------------------
// Database connection string (DSN) for read+write operations
// Format (compatible with PEAR MDB2): db_provider://user:password@host/database
// Currently supported db_providers: mysql, pgsql, sqlite, mssql or sqlsrv
// For examples see http://pear.php.net/manual/en/package.database.mdb2.intro-dsn.php
// NOTE: for SQLite use absolute path: 'sqlite:////full/path/to/sqlite.db?mode=0646'
$config['db_dsnw'] = 'mysql://roundcube:pass@localhost/roundcubemail';

// log driver:  'syslog' or 'file'.
$config['log_driver'] = 'syslog';

// ----------------------------------
// IMAP
// ----------------------------------
// The mail host chosen to perform the log-in.
// Leave blank to show a textbox at login, give a list of hosts
// to display a pulldown menu or set one host as string.
// To use SSL/TLS connection, enter hostname with prefix ssl:// or tls://
// Supported replacement variables:
// %n - hostname ($_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname $_SERVER['HTTP_HOST'] without the first part)
// %s - domain name after the '@' from e-mail address provided at login screen
// For example %n = mail.domain.tld, %t = domain.tld
// WARNING: After hostname change update of mail_host column in users table is
//          required to match old user data records with the new host.
$config['default_host'] = 'localhost';

// ----------------------------------
// SMTP
// ----------------------------------
// SMTP server host (for sending mails).
// To use SSL/TLS connection, enter hostname with prefix ssl:// or tls://
// If left blank, the PHP mail() function is used
// Supported replacement variables:
// %h - user's IMAP hostname
// %n - hostname ($_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname $_SERVER['HTTP_HOST'] without the first part)
// %z - IMAP domain (IMAP hostname without the first part)
// For example %n = mail.domain.tld, %t = domain.tld
$config['smtp_server'] = 'localhost';

// SMTP port (default is 25; use 587 for STARTTLS or 465 for the
// deprecated SSL over SMTP (aka SMTPS))
$config['smtp_port'] = 587;

// SMTP username (if required) if you use %u as the username Roundcube
// will use the current username for login
$config['smtp_user'] = '%u';

// SMTP password (if required) if you use %p as the password Roundcube
// will use the current user's password for login
$config['smtp_pass'] = '%p';

// provide an URL where a user can get support for this Roundcube installation
// PLEASE DO NOT LINK TO THE ROUNDCUBE.NET WEBSITE HERE!
$config['support_url'] = '';

// check client IP in session authorization
$config['ip_check'] = true;

// this key is used to encrypt the users imap password which is stored
// in the session record (and the client cookie if remember password is enabled).
// please provide a string of exactly 24 chars.
$config['des_key'] = '38acd07f0f09021f8b2b378a';

// Name your service. This is displayed on the login screen and in the window title
$config['product_name'] = 'Webmail';

// ----------------------------------
// PLUGINS
// ----------------------------------
// List of active plugins (in plugins/ directory)
$config['plugins'] = array('archive', 'attachment_reminder', 'autologon', 'database_attachments', 'emoticons', 'hide_blockquote', 'jqueryui', 'markasjunk', 'userinfo', 'virtuser_query');

// the default locale setting (leave empty for auto-detection)
// RFC1766 formatted language name like en_US, de_DE, de_CH, fr_FR, pt_BR
$config['language'] = 'en_US';

// save compose message every 300 seconds (5min)
$config['draft_autosave'] = 60;

// Set identities access level:
// 0 - many identities with possibility to edit all params
// 1 - many identities with possibility to edit all params but not email address
// 2 - one identity with possibility to edit all params
// 3 - one identity with possibility to edit all params but not email address
// 4 - one identity with possibility to edit only signature
$config['identities_level'] = 3;

// IMAP AUTH type (DIGEST-MD5, CRAM-MD5, LOGIN, PLAIN or null to use
// best server supported one)
$config['imap_auth_type'] = PLAIN;

// enforce connections over https
// with this option enabled, all non-secure connections will be redirected.
// set the port for the ssl connection as value of this option if it differs from the default 443
$config['force_https'] = true;

// Allow browser-autocompletion on login form.
// 0 - disabled, 1 - username and host only, 2 - username, host, password
$config['login_autocomplete'] = 2;

// When replying:
// -1 - don't cite the original message
// 0  - place cursor below the original message
// 1  - place cursor above original message (top posting)
$config['reply_mode'] = 1;
