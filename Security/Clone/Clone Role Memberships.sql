sp_MSforeachdb '
USE ?

SET NOCOUNT ON
DECLARE @OldUser sysname, @NewUser sysname,@NewLoginName sysname = NULL,@dbName nvarchar(128)

SET @OldUser = ''dev_hsisouser'' --The user or role from which to copy the permissions from
SET @NewUser = ''dev_hsisouser1''  --The user or role to which to copy the permissions to
SET @NewLoginName = ''dev_hsisouser1'' --NEW LOGIN NAME

SELECT  ''USE'' + SPACE(1) + QUOTENAME("?") AS "--Database Context"


--SELECT  ''--Cloning permissions from'' + SPACE(1) + QUOTENAME(@OldUser) + SPACE(1) + ''to'' + SPACE(1) + QUOTENAME(@NewUser) AS "--Comment"

SELECT  ''EXEC sp_addrolemember @rolename =''
    + SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''''''') + '', @membername ='' + SPACE(1) + QUOTENAME(@NewUser, '''''''') AS "--Role Memberships"
FROM    sys.database_role_members AS rm
WHERE   USER_NAME(rm.member_principal_id) = @OldUser
ORDER BY rm.role_principal_id ASC;
'