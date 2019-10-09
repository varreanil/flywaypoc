BEGIN
    DECLARE
        usernameExists NUMBER(1);
    BEGIN

        SELECT COUNT(*) INTO usernameExists
          FROM DBA_USERS
         WHERE UPPER(username) = UPPER('@dataSource.users.username@');

        IF (usernameExists = 1)
        THEN
        	-- drop the user
        	EXECUTE IMMEDIATE 'drop user @dataSource.users.username@ cascade';
        END IF;

        SELECT COUNT(*) INTO usernameExists
          FROM DBA_USERS
         WHERE UPPER(username) = UPPER('@dataSource.users_se.username@');

        IF (usernameExists = 1)
        THEN
        	-- drop the user
        	EXECUTE IMMEDIATE 'drop user @dataSource.users_se.username@ cascade';
        END IF;

    END;
END;
