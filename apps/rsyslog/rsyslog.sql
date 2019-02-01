--
-- Table structure for table `SystemEvents`
--
DROP TABLE IF EXISTS `SystemEvents` ;
CREATE TABLE `SystemEvents` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `CustomerID` bigint(20) DEFAULT NULL,
  `ReceivedAt` datetime DEFAULT NULL,
  `DeviceReportedTime` datetime DEFAULT NULL,
  `Facility` smallint(6) DEFAULT NULL,
  `Priority` smallint(6) DEFAULT NULL,
  `FromHost` varchar(60) DEFAULT NULL,
  `Message` text,
  `NTSeverity` int(11) DEFAULT NULL,
  `Importance` int(11) DEFAULT NULL,
  `EventSource` varchar(60) DEFAULT NULL,
  `EventUser` varchar(60) DEFAULT NULL,
  `EventCategory` int(11) DEFAULT NULL,
  `EventID` int(11) DEFAULT NULL,
  `EventBinaryData` text,
  `MaxAvailable` int(11) DEFAULT NULL,
  `CurrUsage` int(11) DEFAULT NULL,
  `MinUsage` int(11) DEFAULT NULL,
  `MaxUsage` int(11) DEFAULT NULL,
  `InfoUnitID` int(11) DEFAULT NULL,
  `SysLogTag` varchar(60) DEFAULT NULL,
  `EventLogType` varchar(60) DEFAULT NULL,
  `GenericFileName` varchar(60) DEFAULT NULL,
  `SystemID` int(11) DEFAULT NULL,
  `Checksum` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

--
-- Table structure for table `SystemEventsProperties`
--
DROP TABLE IF EXISTS `SystemEventsProperties` ;

CREATE TABLE `SystemEventsProperties` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `SystemEventID` int(11) DEFAULT NULL,
  `ParamName` varchar(255) DEFAULT NULL,
  `ParamValue` text,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Create procedure to clean DB after 7 days
--
DROP PROCEDURE IF EXISTS `cleanRsyslog` ;

DELIMITER //

CREATE PROCEDURE `cleanRsyslog` ()
BEGIN
	DELETE FROM rsyslog.SystemEvents WHERE ReceivedAt < date_add(current_date, interval -7 day);
END//

DELIMITER ;


--
-- Create event to run procedure every 1 day
--
DROP EVENT IF EXISTS `cleanRsyslogEvent` ;
CREATE EVENT `cleanRsyslogEvent`
    ON SCHEDULE EVERY 1 DAY
    DO
      CALL cleanRsyslog();

--
-- Activate event_scheduler
--
SET GLOBAL event_scheduler = ON;
