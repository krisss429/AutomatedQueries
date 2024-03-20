sp_MSforeachdb '
USE ?

SET NOCOUNT ON
DECLARE @OldUser sysname, @NewUser sysname,@NewLoginName sysname = NULL,@dbName nvarchar(128)

SET @OldUser = ''dev_hsisouser'' --The user or role from which to copy the permissions from
SET @NewUser = ''dev_hsisouser1''  --The user or role to which to copy the permissions to
SET @NewLoginName = ''dev_hsisouser1'' --NEW LOGIN NAME

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