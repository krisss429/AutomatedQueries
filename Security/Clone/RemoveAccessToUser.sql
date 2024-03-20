------------------------------------------------------------------------------------------------------------------------------------------------------------
SET NOCOUNT ON
DECLARE @OldUser sysname, --The user or role from which to copy the permissions from
        @dbName NVARCHAR(128)
SET @OldUser = 'uat_hsisoq218' --The user or role from which to copy the permissions from

SELECT '--REVOKING PERMISSIONS OF' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ' --SERVER_LEVEL(Whole Instance)'

SELECT 'REVOKE' + ' ' + permission_name + ' ' + 'FROM' + ' ' + @OldUser
FROM sys.server_permissions AS p
    JOIN sys.server_principals AS l
        ON p.grantee_principal_id = l.principal_id
WHERE l.name = @OldUser
      AND p.permission_name <> 'CONNECT SQL'
GO

------------------------------------------------------------------------------------------------------------------------------------------------------------
SET NOCOUNT ON
DECLARE @OldUser sysname, --The user or role from which to copy the permissions from
        @dbName NVARCHAR(128),
        @sql NVARCHAR(MAX),
        @msg NVARCHAR(MAX)

SET @OldUser = 'uat_hsisoq218' --The user or role from which to copy the permissions from

SELECT '--REVOKING PERMISSIONS OF' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ' --SERVER_LEVEL'
BEGIN
    SET @sql
        = N' 
		SELECT ''ALTER SERVER ROLE ['' + role.name + ''] DROP MEMBER ['' + @OldUser + '']'' AS "--Server_Level_Permissions"
		FROM sys.server_role_members  
		JOIN sys.server_principals AS role  
		ON sys.server_role_members.role_principal_id = role.principal_id  
		JOIN sys.server_principals AS member  
		ON sys.server_role_members.member_principal_id = member.principal_id
		WHERE   member.name = @OldUser'

    EXEC sp_executesql @sql, N'@OldUser sysname', @OldUser = @OldUser

END
GO
------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @OldUser sysname
SET @OldUser = 'uat_hsisoq218'
SELECT '--REVOKING PERMISSIONS OF' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ' --DATABASE ROLES'
GO
sp_MSforeachdb '
USE ?

SET NOCOUNT ON
DECLARE @OldUser sysname, --The user or role from which to copy the permissions from
        @dbName NVARCHAR(128)

SET @OldUser = ''uat_hsisoq218'' --The user or role from which to copy the permissions from


SELECT  ''USE'' + SPACE(1) + QUOTENAME("?") AS "--Database Context"

SELECT  ''EXEC sp_droprolemember @rolename =''
    + SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''''''') + '', @membername ='' + SPACE(1) + QUOTENAME(@OldUser, '''''''') AS "--Role Memberships"
FROM    sys.database_role_members AS rm
WHERE   USER_NAME(rm.member_principal_id) = @OldUser
ORDER BY rm.role_principal_id ASC;
'
GO
------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @OldUser sysname
SET @OldUser = 'uat_hsisoq218'
SELECT '--REVOKING PERMISSIONS OF' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ' --OBJECT LEVEL PERMISSIONS'
GO

sp_MSforeachdb '
USE ?

SET NOCOUNT ON
DECLARE @OldUser sysname, --The user or role from which to copy the permissions from
        @dbName NVARCHAR(128)

SET @OldUser = ''uat_hsisoq218'' --The user or role from which to copy the permissions from


SELECT  ''USE'' + SPACE(1) + QUOTENAME("?") AS "--Database Context"

SELECT  ''REVOKE''
    + SPACE(1) + perm.permission_name + SPACE(1) + ''ON '' + QUOTENAME(USER_NAME(obj.schema_id)) + ''.'' + QUOTENAME(obj.name)
    + CASE WHEN cl.column_id IS NULL THEN SPACE(0) ELSE ''('' + QUOTENAME(cl.name) + '')'' END
    + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(@OldUser) COLLATE database_default
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
------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @OldUser sysname
SET @OldUser = 'uat_hsisoq218'
SELECT '--REVOKING PERMISSIONS OF' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ' --PERMISSIONS_ON_KEYS_CERTS'
GO

sp_MSforeachdb '
USE ?

SET NOCOUNT ON
DECLARE @OldUser sysname, --The user or role from which to copy the permissions from
        @dbName NVARCHAR(128)

SET @OldUser = ''uat_hsisoq218'' --The user or role from which to copy the permissions from

SELECT  ''USE'' + SPACE(1) + QUOTENAME("?") AS "--Database Context"


--SELECT  ''--Cloning permissions from'' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ''to'' + SPACE(1) + QUOTENAME(@OldUser) AS "--Comment"

select 
      ''REVOKE '' + p.permission_name + '' ON '' + 
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
      + QUOTENAME(@OldUser) COLLATE database_default  as ''--Permission on keys''
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
GO
------------------------------------------------------------------------------------------------------------------------------------------------------------