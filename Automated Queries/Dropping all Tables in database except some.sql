USE
HomesiteWeb_TEST
GO


SET NOCOUNT ON 

-- 1 - Variable declaration 
DECLARE @fileList TABLE (SchemaName varchar(100),TableName VARCHAR(5000)) 
DECLARE @lastFullBackup NVARCHAR(500) 
DECLARE @lastDiffBackup NVARCHAR(500) 
DECLARE @Tablename VARCHAR(5000)
DECLARE @SchemaName VARCHAR(100)
DECLARE @cmd VARCHAR(5000)



INSERT INTO @fileList(SchemaName,TableName) 
SELECT s.name,T.name FROM  sys.tables T
JOIN sys.schemas S ON S.schema_id = T.schema_id
WHERE t.name NOT IN ('ECommerceExperienceLog','ECommerceLog','HS_iQuoteWebLog','HS_Servicelog','HS_SESSION_EXPERIENCE')

SELECT * FROM @fileList ORDER BY TableName

-- 5 - check for log backups 
DECLARE TableNames CURSOR FOR  
   SELECT TableName  
   FROM @fileList ORDER BY TableName

   --AND backupFile > @lastFullBackup 

OPEN TableNames  

-- Loop through all the files for the database  
FETCH NEXT FROM TableNames INTO @Tablename
  

WHILE @@FETCH_STATUS = 0  
BEGIN  
   SET @cmd = 'DROP Table ' + '['+(SELECT SchemaName FROM @fileList WHERE TableName=@Tablename)+']' + '.'+ '['+@Tablename+']'    
   PRINT @cmd 
   FETCH NEXT FROM TableNames INTO @Tablename
END 

CLOSE TableNames  
DEALLOCATE TableNames  

-- 6 - put database in a useable state 
SET @cmd = 'RESTORE DATABASE ' + @dbName + ' WITH RECOVERY' 
PRINT @cmd