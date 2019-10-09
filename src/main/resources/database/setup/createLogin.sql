BEGIN
    DECLARE
        userExists   NUMBER(1);
        userFullRoleExists NUMBER(1);
        userViewRoleExists NUMBER(1);
        oltpUserDeleteOnlyRoleExists NUMBER(1);
    BEGIN
	    SELECT COUNT(*) INTO userFullRoleExists
	    	FROM DBA_ROLES
	    	WHERE ROLE = '@flyway.placeholders.dataSource.users.full.role@';
	    	
	    IF (userFullRoleExists = 0)
        THEN
            EXECUTE IMMEDIATE 'CREATE ROLE @flyway.placeholders.dataSource.users.full.role@';
        END IF;
	
	    SELECT COUNT(*) INTO userViewRoleExists
	    	FROM DBA_ROLES
	    	WHERE ROLE = '@flyway.placeholders.dataSource.users.view.role@';
	    
	    IF (userViewRoleExists = 0)
        THEN
            EXECUTE IMMEDIATE 'CREATE ROLE @flyway.placeholders.dataSource.users.view.role@';
        END IF;
	
		SELECT COUNT(*) INTO oltpUserDeleteOnlyRoleExists
			FROM DBA_ROLES
			WHERE ROLE = '@flyway.placeholders.dataSource.users.delete_only.role@';

		IF (oltpUserDeleteOnlyRoleExists = 0)
		THEN
			EXECUTE IMMEDIATE 'CREATE ROLE @flyway.placeholders.dataSource.users.delete_only.role@';
        END IF;
	    	
        SELECT COUNT(*) INTO userExists
          FROM DBA_USERS
         WHERE UPPER(username) = UPPER('@dataSource.users.username@');

        IF (userExists = 0)
        THEN
            EXECUTE IMMEDIATE 'create user @dataSource.users.username@ identified by "@dataSource.users.password@" DEFAULT TABLESPACE OLTP_USER';
        END IF;

        SELECT COUNT(*) INTO userExists
          FROM DBA_USERS
         WHERE UPPER(username) = UPPER('@dataSource.users.username@');

        IF (userExists = 1)
        THEN
            EXECUTE IMMEDIATE 'grant create session,'
                             ||     'resource,'
			     ||     'create view,'
                             ||     'connect,'
                             ||     'create database link'
                             ||' to @dataSource.users.username@';

            EXECUTE IMMEDIATE 'alter user @dataSource.users.username@ quota unlimited on OLTP_USER';
            EXECUTE IMMEDIATE 'alter user @dataSource.users.username@ quota unlimited on OLTP_USER_ENCRYPTED';
        END IF;
    END;
END;
/
BEGIN
    DECLARE
        userExists   NUMBER(1);
    BEGIN
        IF ('@dataSource.users_se.username@' != '@dataSource.users.username@')
	    THEN
	        SELECT COUNT(*) INTO userExists
	          FROM DBA_USERS
	         WHERE UPPER(username) = UPPER('@dataSource.users_se.username@');
	         
	        IF (userExists = 0)
	        THEN
	            EXECUTE IMMEDIATE 'create user @dataSource.users_se.username@ identified by "@dataSource.users_se.password@" DEFAULT TABLESPACE OLTP_USER TEMPORARY TABLESPACE TEMP PROFILE DEFAULT ACCOUNT UNLOCK';
	        END IF;
	
	        SELECT COUNT(*) INTO userExists
	          FROM DBA_USERS
	         WHERE UPPER(username) = UPPER('@dataSource.users_se.username@');
	         
	        IF (userExists = 1)
	        THEN
	            EXECUTE IMMEDIATE 'GRANT @flyway.placeholders.dataSource.users.full.role@ TO @dataSource.users_se.username@';
	            EXECUTE IMMEDIATE 'GRANT connect TO @dataSource.users_se.username@';
	            EXECUTE IMMEDIATE 'GRANT RESOURCE TO @dataSource.users_se.username@';
	            EXECUTE IMMEDIATE 'alter user @dataSource.users_se.username@ DEFAULT ROLE @flyway.placeholders.dataSource.users.full.role@';
	            EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO @dataSource.users_se.username@';
	            EXECUTE IMMEDIATE 'alter user @dataSource.users_se.username@ quota unlimited on OLTP_USER';
                    EXECUTE IMMEDIATE 'alter user @dataSource.users.username@ quota unlimited on OLTP_USER_ENCRYPTED';
	        END IF;
		END IF;
    END;
END;    
