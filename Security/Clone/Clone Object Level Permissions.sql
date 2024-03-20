sp_MSforeachdb '
USE ?

SET NOCOUNT ON
DECLARE @OldUser sysname, @NewUser sysname,@NewLoginName sysname = NULL,@dbName nvarchar(128)

SET @OldUser = ''dev_hsisouser'' --The user or role from which to copy the permissions from
SET @NewUser = ''dev_hsisouser1''  --The user or role to which to copy the permissions to
SET @NewLoginName = ''dev_hsisouser1'' --NEW LOGIN NAME

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