
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
GRANT ALL PRIVILEGES ON *.* TO root IDENTIFIED BY '${DB_ROOT_PASS}';

CREATE DATABASE IF NOT EXISTS mailserver;

GRANT SELECT ON mailserver.* TO postfix IDENTIFIED BY '${DB_POSTFIX_PASS}';
GRANT SELECT ON mailserver.* TO dovecot IDENTIFIED BY '${DB_DOVECOT_PASS}';

CREATE DATABASE IF NOT EXISTS roundcube;
GRANT ALL PRIVILEGES ON roundcube.* TO roundcube IDENTIFIED BY '${DB_ROUNDCUBE_PASS}';

USE mailserver;
CREATE TABLE IF NOT EXISTS domains (
    id          int(11) NOT NULL auto_increment,
    domain      varchar(50) NOT NULL UNIQUE,
    selector    varchar(63) NOT NULL,
    dkim_key    text NOT NULL UNIQUE,
  
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS users (
    id          int(11) NOT NULL auto_increment,
    domain_id   int(11) NOT NULL,
    email       varchar(100) NOT NULL UNIQUE,
    password    varchar(106) NOT NULL,
    quota       int unsigned DEFAULT '5120',
    enabled     boolean DEFAULT '1',
  
    PRIMARY KEY (id),
    FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS aliases (
    id          int(11) NOT NULL auto_increment,
    user_id     int(11) NOT NULL,
    alias       varchar(100) NOT NULL UNIQUE,
  
    PRIMARY KEY (id),
    FOREIGN KEY (user_id)   REFERENCES users(id)   ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS mailsync (
    id          int(11) NOT NULL auto_increment,
    user_id     int(11) NOT NULL,
    username    varchar(50) NOT NULL,
    password    varchar(50) NOT NULL,
    host        varchar(50) NOT NULL,
    ssl_type    ENUM('None', 'STARTTLS', 'IMAPS') NOT NULL,
    mappings    varchar(100),

    PRIMARY KEY (id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DELIMITER $$

-- This procedure creates a domain and a postmaster for that domain with the defined password
CREATE OR REPLACE DEFINER='root'@'localhost' 
PROCEDURE CreateDomain(new_domain varchar(50), hostname varchar(50), dkey TEXT) 
MODIFIES SQL DATA 
BEGIN 
    INSERT INTO mailserver.domains (domain, selector, dkim_key) VALUES (new_domain, hostname, dkey); 

    INSERT INTO mailserver.aliases (user_id, alias) 
        VALUES (1, CONCAT('postmaster', '@', new_domain)); 
END;$$

-- This procedure creates a new user with defined password and adds a wildcard alias
CREATE OR REPLACE DEFINER='root'@'localhost' 
PROCEDURE CreateUser(username varchar(50), password varchar(50), user_domain varchar(50)) MODIFIES SQL DATA 
BEGIN 
    SELECT id FROM mailserver.domains WHERE domain = user_domain INTO @domain_id;
    
    INSERT INTO mailserver.users (domain_id, email, password) 
        VALUES (@domain_id, CONCAT(username, '@', user_domain), 
        ENCRYPT(password, CONCAT('$6$', SUBSTRING(SHA(RAND()), -16)))); 

    SELECT id FROM mailserver.users WHERE email = CONCAT(username, '@', user_domain) INTO @user_id;
    
    INSERT INTO mailserver.aliases (user_id, alias) 
        VALUES (@user_id, CONCAT('^', username, '\\..*@', user_domain, '$')); 
END;$$

-- This procedure retrieves users email from an alias list
CREATE OR REPLACE DEFINER='root'@'localhost' 
PROCEDURE GetEmailFromAlias(source varchar(50)) READS SQL DATA 
BEGIN
    SELECT user_id, COUNT(*) FROM mailserver.aliases 
        WHERE source REGEXP alias AND SUBSTRING(alias, 1, 1) != '@'
        INTO @uid, @count;
    
    IF @count = 1 THEN
        SELECT email FROM mailserver.users WHERE id = @uid; 
    END IF;
END;$$

-- This procedure updates the user password
CREATE OR REPLACE DEFINER='root'@'localhost'
PROCEDURE UpdatePassword(username varchar(50), new_pass varchar(50), old_pass varchar(50)) MODIFIES SQL DATA
BEGIN
    SELECT SUBSTRING(password,1,19) FROM mailserver.users where email = username INTO @salt;
    UPDATE mailserver.users SET password = ENCRYPT(new_pass, CONCAT('$6$', SUBSTRING(SHA(RAND()), -16))) 
        WHERE email = username AND password = ENCRYPT(old_pass, @salt);
END;$$

DELIMITER ;

GRANT EXECUTE ON PROCEDURE mailserver.GetEmailFromAlias TO postfix;
GRANT EXECUTE ON PROCEDURE mailserver.UpdatePassword TO roundcube;
FLUSH PRIVILEGES;

-- Create postmaster user
INSERT IGNORE INTO mailserver.domains (domain, selector, dkim_key) VALUES ('master', '', '');
INSERT IGNORE INTO mailserver.users (domain_id, email, password) 
    VALUES (1, 'postmaster\@master', ENCRYPT('${POSTMASTER_PASS}', CONCAT('$6$', SUBSTRING(SHA(RAND()), -16))));
