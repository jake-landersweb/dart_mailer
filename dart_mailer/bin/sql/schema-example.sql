CREATE USER IF NOT EXISTS 'user'@'%' IDENTIFIED BY 'pass';
GRANT ALL ON *.* TO 'user'@'%';

flush privileges;

CREATE DATABASE IF NOT EXISTS db;

USE db;

CREATE TABLE IF NOT EXISTS tbl(
    id VARCHAR(100) PRIMARY KEY,
    subject VARCHAR(255) NOT NULL,
    body LONGTEXT NOT NULL,
    recipient MEDIUMTEXT NOT NULL,
    cc MEDIUMTEXT NOT NULL,
    bcc MEDIUMTEXT NOT NULL,
    host VARCHAR(100) NOT NULL,
    port INT NOT NULL,
    username VARCHAR(100) NOT NULL,
    password MEDIUMTEXT NOT NULL,
    created BIGINT NOT NULL,
    sentDate BIGINT,
    sentStatus INT NOT NULL DEFAULT 0,
    sendDate BIGINT,
    salt MEDIUMTEXT NOT NULL,
    sendName VARCHAR(255),
    tags MEDIUMTEXT,
) ENGINE=INNODB;

GRANT ALL PRIVILEGES ON mailer.* TO 'user'@'%' WITH GRANT OPTION;

flush privileges;