DECLARE @strSQL nvarchar(2000),
@dbname nvarchar(256)
IF OBJECT_ID('tempdb..#DBUsers') IS NOT NULL DROP TABLE #DBUsers
CREATE table #DBUsers 
(
DBname varchar (256),  
LoginName varchar(100),  
DBUserName varchar(100),           
[DBRole] varchar (100),     
PrincipalType  varchar(100), 
PermissionName  varchar(100) ,
ObjectType varchar(50),  
Objectname varchar(100), 
Columnname varchar(100)
)  
DECLARE listdbs Cursor
FOR
SELECT name from master.dbo.sysdatabases
--WHERE  name not in ('master', 'model', 'msdb', 'tempdb')
OPEN listdbs
FETCH next
     FROM  listdbs into @dbname    
     WHILE @@fetch_status = 0
     BEGIN   
     SELECT @strSQL =                      
    '
     Use ['+ @dbname+'] ;
     SELECT 
      DB_name()
     ,sp.name 
     ,dp.name    
     ,dp2.name
     ,dp.type_desc
     ,perm.permission_name
     , objectType = case perm.class
             WHEN 1 THEN obj.type_desc
                      ELSE perm.class_desc
     END
     ,objectName = case perm.class
              when 1 then Object_name(perm.major_id)
                    when 3 then schem.name 
                             when 4 then imp.name
     END
                     , col.name
     FROM
     sys.database_role_members drm
     RIGHT JOIN  sys.database_principals dp
     on dp.principal_id = drm.member_principal_id
     LEFT JOIN sys.database_principals dp2
     on dp2.principal_id = drm.role_principal_id
     FULL JOIN sys.server_principals sp 
     ON dp.[sid] = sp.[sid] 
     LEFT JOIN sys.database_permissions perm 
     ON perm.[grantee_principal_id] = dp.[principal_id]
     LEFT JOIN sys.columns col 
     ON col.[object_id] = perm.major_id 
     AND col.[column_id] = perm.[minor_id] 
     LEFT JOIN sys.objects obj 
     ON perm.[major_id] = obj.[object_id] 
     LEFT JOIN sys.schemas schem 
     ON schem.[schema_id] = perm.[major_id] 
     LEFT JOIN sys.database_principals imp 
     ON imp.[principal_id] = perm.[major_id] 
     WHERE dp.name not in (''sys'' , ''information_schema'' , ''guest'', ''public'')
     ORDER by sp.name
    '
    INSERT into #DBUsers
    EXEC (@strSQL)
    FETCH NEXT
    FROM listdbs into @dbname
    END
    CLOSE listdbs
    DEALLOCATE listdbs
    
	SELECT * from #DBUsers WHERE LoginName IN ('admin_tool_Q218','Prod_hsisoQ218','Prod_hsdmbQ218','Prod_hswebQ218','Prod_ServiceInfoQ218','prod_tuQ218','HrzBatchLinkQ218') ORDER BY LoginName
	SELECT * from #DBUsers WHERE LoginName IN ('admin_tool_Q217','Prod_hsisoQ217','Prod_hsdmbQ217','Prod_hswebQ217','Prod_ServiceInfoQ217','prod_tuQ217','HrzBatchLinkQ217') ORDER BY LoginName

