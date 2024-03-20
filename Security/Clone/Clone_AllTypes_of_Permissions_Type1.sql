SET NOCOUNT ON
DECLARE @OldUser sysname,             --The user or role from which to copy the permissions from
        @NewUser sysname,             --The user or role to which to copy the permissions to
        @NewLoginName sysname = NULL, --When a NewLogin name is provided, create user script will also gets created
        @dbName NVARCHAR(128),
        @sql NVARCHAR(MAX),
        @msg NVARCHAR(MAX)

SET @OldUser = 'dev_hsisouser' --The user or role from which to copy the permissions from
SET @NewUser = 'dev_hsisouser1' --The user or role to which to copy the permissions to
SET @NewLoginName = 'dev_hsisouser1' --NEW LOGIN NAME

SELECT '--CLONING PERMISSIONS FROM' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(@NewUser)
       + ' --SERVER_LEVEL'
BEGIN
    SET @sql
        = N' 
		SELECT ''ALTER SERVER ROLE ['' + role.name + ''] ADD MEMBER ['' + @NewUser + '']'' AS "--Server_Level_Permissions"
		FROM sys.server_role_members  
		JOIN sys.server_principals AS role  
		ON sys.server_role_members.role_principal_id = role.principal_id  
		JOIN sys.server_principals AS member  
		ON sys.server_role_members.member_principal_id = member.principal_id
		WHERE   member.name = @OldUser'

    EXEC sp_executesql @sql,
                       N'@OldUser sysname, @NewUser sysname',
                       @OldUser = @OldUser,
                       @NewUser = @NewUser
END
GO

sp_MSforeachdb '
USE ?

SET NOCOUNT ON
DECLARE @OldUser sysname, @NewUser sysname,@NewLoginName sysname = NULL,@dbName nvarchar(128)

SET @OldUser = ''dev_hsisouser'' --The user or role from which to copy the permissions from
SET @NewUser = ''dev_hsisouser1''  --The user or role to which to copy the permissions to
SET @NewLoginName = ''dev_hsisouser1'' --NEW LOGIN NAME

SELECT ''--CLONING PERMISSIONS FROM'' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(@NewUser) + '' --DATABASE_LEVEL("?")''


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
GO

sp_MSforeachdb '
USE ?

SET NOCOUNT ON
DECLARE @OldUser sysname, @NewUser sysname,@NewLoginName sysname = NULL,@dbName nvarchar(128)

SET @OldUser = ''dev_hsisouser'' --The user or role from which to copy the permissions from
SET @NewUser = ''dev_hsisouser1''  --The user or role to which to copy the permissions to
SET @NewLoginName = ''dev_hsisouser1'' --NEW LOGIN NAME

SELECT ''--CLONING PERMISSIONS FROM'' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(@NewUser) + '' --ROLE_MEMBERSHIP("?")''

SELECT  ''USE'' + SPACE(1) + QUOTENAME("?") AS "--Database Context"


--SELECT  ''--Cloning permissions from'' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ''to'' + SPACE(1) + QUOTENAME(@NewUser) AS "--Comment"

SELECT  ''EXEC sp_addrolemember @rolename =''
    + SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''''''') + '', @membername ='' + SPACE(1) + QUOTENAME(@NewUser, '''''''') AS "--Role Memberships"
FROM    sys.database_role_members AS rm
WHERE   USER_NAME(rm.member_principal_id) = @OldUser
ORDER BY rm.role_principal_id ASC;
'
GO

sp_MSforeachdb '
USE ?

SET NOCOUNT ON
DECLARE @OldUser sysname, @NewUser sysname,@NewLoginName sysname = NULL,@dbName nvarchar(128)

SET @OldUser = ''dev_hsisouser'' --The user or role from which to copy the permissions from
SET @NewUser = ''dev_hsisouser1''  --The user or role to which to copy the permissions to
SET @NewLoginName = ''dev_hsisouser1'' --NEW LOGIN NAME

SELECT ''--CLONING PERMISSIONS FROM'' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(@NewUser) + '' --OBJECT_LEVEL_PERMISSIONS("?")''

SELECT  ''USE'' + SPACE(1) + QUOTENAME("?") AS "--Database Context"


--SELECT  ''--Cloning permissions from'' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ''to'' + SPACE(1) + QUOTENAME(@NewUser) AS "--Comment"

SELECT  CASE WHEN perm.state <> ''W'' THEN perm.state_desc ELSE ''GRANT'' END
    + SPACE(1) + perm.permission_name + SPACE(1) + ''ON '' + QUOTENAME(USER_NAME(obj.schema_id)) + ''.'' + QUOTENAME(obj.name)
    + CASE WHEN cl.column_id IS NULL THEN SPACE(0) ELSE ''('' + QUOTENAME(cl.name) + '')'' END
    + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(@NewUser) COLLATE database_default
    + CASE WHEN perm.state <> ''W'' THEN SPACE(0) ELSE SPACE(1) + ''WITH GRANT OPTION'' END AS "--Object Level Permissions"
FROM    sys.database_permissions AS perm
    INNER JOIN
    sys.objects AS obj
    ON perm.major_id = obj.[object_id]
    INNER JOIN
    sys.database_principals AS usr
    ON perm.grantee_principal_id = usr.principal_id
    LEFT JOIN
    sys.columns AS cl
    ON cl.column_id = perm.minor_id AND cl.[object_id] = perm.major_id
WHERE   usr.name = @OldUser
ORDER BY perm.permission_name ASC, perm.state_desc ASC;'

GO

sp_MSforeachdb '
USE ?

SET NOCOUNT ON
DECLARE @OldUser sysname, @NewUser sysname,@NewLoginName sysname = NULL,@dbName nvarchar(128)

SET @OldUser = ''dev_hsisouser'' --The user or role from which to copy the permissions from
SET @NewUser = ''dev_hsisouser1''  --The user or role to which to copy the permissions to
SET @NewLoginName = ''dev_hsisouser1'' --NEW LOGIN NAME

SELECT ''--CLONING PERMISSIONS FROM'' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(@NewUser) + '' --PERMISSIONS_ON_KEYS_CERTS("?")''

SELECT  ''USE'' + SPACE(1) + QUOTENAME("?") AS "--Database Context"


--SELECT  ''--Cloning permissions from'' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ''to'' + SPACE(1) + QUOTENAME(@NewUser) AS "--Comment"

select 
      ''GRANT '' + p.permission_name + '' ON '' + 
      case 
            when p.class_desc = ''SYMMETRIC_KEYS'' then ''SYMMETRIC KEY''
            when p.class_desc = ''CERTIFICATE'' then ''CERTIFICATE''
      end 
      + ''::''
    --object_name(p.major_id) ObjectName, state_desc, k.name , p.major_id, c.name,
    + case 
            when p.class_desc = ''SYMMETRIC_KEYS'' then k.name
            when p.class_desc = ''CERTIFICATE'' then c.name
      end 
      + '' TO '' 
      + QUOTENAME(@NewUser) COLLATE database_default  as ''--Permission on keys''
from sys.database_permissions  p 
join sys.database_principals u
      on p.grantee_principal_id = u.principal_id
left join sys.symmetric_keys k
      on p.major_id = k.symmetric_key_id and p.class_desc = ''SYMMETRIC_KEYS''
left join sys.certificates c
      on p.major_id = c.certificate_id and p.class_desc = ''CERTIFICATE''
where class_desc in (''SYMMETRIC_KEYS'',''CERTIFICATE'')
and u.name = @OldUser
order by u.name
'