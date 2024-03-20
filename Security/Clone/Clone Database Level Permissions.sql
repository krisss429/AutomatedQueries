sp_MSforeachdb '
USE ?

SET NOCOUNT ON
DECLARE @OldUser sysname, @NewUser sysname,@NewLoginName sysname = NULL,@dbName nvarchar(128)

SET @OldUser = ''dev_hsisouser'' --The user or role from which to copy the permissions from
SET @NewUser = ''dev_hsisouser1''  --The user or role to which to copy the permissions to
SET @NewLoginName = ''dev_hsisouser1'' --NEW LOGIN NAME

SELECT  ''USE'' + SPACE(1) + QUOTENAME("?") + CHAR(13) + ''GO'' + CHAR(13) +  ''SET XACT_ABORT ON'' AS  "--Database Context"

IF (ISNULL(@NewLoginName, '''') <> '''')

		IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @newUser)

            SELECT 
                ''CREATE USER '' + QUOTENAME(@NewUser) + '' FOR LOGIN ''
				 + QUOTENAME(@NewLoginName) 
				 --+ CASE WHEN ISNULL(default_schema_name, '''') <> '''' THEN '' WITH DEFAULT_SCHEMA = '' + QUOTENAME(dp.default_schema_name)
     --                   ELSE ''''
     --               END 
					AS "--Create_User_Script"
            FROM sys.database_principals dp
            INNER JOIN sys.server_principals sp ON dp.sid = sp.sid
            WHERE dp.name = @OldUser


--SELECT  ''--Cloning permissions from'' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ''to'' + SPACE(1) + QUOTENAME(@NewUser) AS "--Comment"

SELECT  CASE WHEN perm.state <> ''W'' THEN perm.state_desc ELSE ''GRANT'' END
    + SPACE(1) + perm.permission_name + SPACE(1)
    + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(@NewUser) COLLATE database_default
    + CASE WHEN perm.state <> ''W'' THEN SPACE(0) ELSE SPACE(1) + ''WITH GRANT OPTION'' END AS ''--Database Level Permissions''
FROM    sys.database_permissions AS perm
    INNER JOIN
    sys.database_principals AS usr
    ON perm.grantee_principal_id = usr.principal_id
WHERE   usr.name = @OldUser
AND perm.major_id = 0
ORDER BY perm.permission_name ASC, perm.state_desc ASC
'