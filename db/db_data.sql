SET @domain_name = "<DOMAIN_NAME>";
SET @ipv4 = "<WAN_IPV4>";
SET @password = "<SYS_ROOT_PASS>";
SET @hostname = "<HOSTNAME>";

SET @dateToday = (SELECT CURDATE() AS date);
SET @dateOneYear = (SELECT CURDATE() + INTERVAL 1 YEAR AS date);
SET @octetPartOne = (SELECT SUBSTRING_INDEX(@ipv4,'.',2) AS part1);
SET @octetPartTwo = (SELECT SUBSTRING_INDEX(@ipv4,'.',-2) AS part2);
SET @octetOne = (SELECT SUBSTRING_INDEX(@octetPartOne,'.',1) AS octOne);
SET @octetTwo = (SELECT SUBSTRING_INDEX(@octetPartOne,'.',-1) AS octTwo);
SET @octetThree = (SELECT SUBSTRING_INDEX(@octetPartTwo,'.',1) AS octThree);
SET @octetFour = (SELECT SUBSTRING_INDEX(@octetPartTwo,'.',-1) AS octFour);

SELECT @salt := FLOOR(RAND() * 0xFFFFFFFF) AS salt;

INSERT INTO `contact_data` (`username`, `password`, `salt`, `firstname`, `lastname`, `organization`, `orgnr`, `userType`, `address1`, `address2`, `city`, `zip`, `country`, `phone`, `fax`, `email`) VALUES
(CONCAT('admin@', @domain_name), SHA2(CONCAT(@password, @salt), 256), @salt, 'Admin', 'Admin', '<ORG_NAME>', '00000000-0000', '0', '<ORG_ADDRESS>', NULL, '<ORG_CITY>', '<ORG_ZIP>', '<ORG_COUNTRY>', '<ORG_TEL>', NULL, '<ADMIN_EMAIL>');

SET @salt = NULL;

SET @contact_id = LAST_INSERT_ID();

INSERT INTO `nameserver_data` (`nameserver`, `ip`) VALUES
(CONCAT('ns1.', @domain_name), @ipv4),
(CONCAT('ns2.', @domain_name), @ipv4);

INSERT INTO `domain_data` (`domain_name`, `registered_date`, `expiration_date`, `agent_contact`, `owner_contact`, `admin_contact`, `tech_contact`, `billing_contact`) VALUES
(@domain_name, @dateToday, @dateOneYear, NULL, @contact_id, @contact_id, @contact_id, @contact_id);

SET @domain_id = LAST_INSERT_ID();

INSERT INTO `domain_contacts` (`domain_data_id`, `contact_data_id`) VALUES
(@domain_id, @contact_id);

INSERT INTO `domain_nameserver` (`domain_data_id`, `nameserver`) VALUES
(@domain_id, CONCAT('ns1.', @domain_name)),
(@domain_id, CONCAT('ns2.', @domain_name));

INSERT INTO `pdns_records` (`domain_id`, `name`, `type`, `content`, `ttl`, `prio`) VALUES
(@domain_id, @domain_name, 'SOA', CONCAT('ns1.', @domain_name, ' admin@', @domain_name), 3600, NULL),
(@domain_id, @domain_name, 'NS', CONCAT('ns1.', @domain_name), 120, NULL),
(@domain_id, @domain_name, 'NS', CONCAT('ns2.', @domain_name), 120, NULL),
(@domain_id, 'www', 'CNAME', @domain_name, 120, NULL),
(@domain_id, 'ftp', 'CNAME', @domain_name, 120, NULL),
(@domain_id, @hostname, 'CNAME', @domain_name, 120, NULL),
(@domain_id, @domain_name, 'SPF', 'v=spf1 mx -all', NULL, NULL),
(@domain_id, @domain_name, 'TXT', 'v=spf1 mx -all', NULL, NULL),
(@domain_id, @domain_name, 'PTR', CONCAT(@octetOne,'-',@octetTwo,'-',@octetThree,'-',@octetFour,'-static.',@domain_name), 120, NULL),
(@domain_id, CONCAT(@octetOne,'-',@octetTwo,'-',@octetThree,'-',@octetFour,'-static.',@domain_name), 'A', @ipv4, 120, NULL),
(@domain_id, CONCAT('ns1.',@domain_name), 'A', @ipv4, 120, NULL),
(@domain_id, CONCAT('ns2.', @domain_name), 'A', @ipv4, 120, NULL),
(@domain_id, CONCAT('mail.', @domain_name), 'A', @ipv4, 120, NULL),
(@domain_id, @domain_name, 'A', @ipv4, 120, NULL),
(@domain_id, @domain_name, 'MX', CONCAT('mail.', @domain_name), 120, 10);

INSERT INTO `pdns_domainmetadata` (`domain_id`, `kind`, `content`) VALUES
(@domain_id, 'ALLOW-AXFR-FROM', 'AUTO-NS');
