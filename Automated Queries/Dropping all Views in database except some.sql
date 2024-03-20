USE
HomesiteWeb_TEST
GO


SET NOCOUNT ON 

-- 1 - Variable declaration 
DECLARE @fileList TABLE (SchemaName varchar(100),ViewName VARCHAR(5000)) 
DECLARE @lastFullBackup NVARCHAR(500) 
DECLARE @lastDiffBackup NVARCHAR(500) 
DECLARE @ViewName VARCHAR(5000)
DECLARE @SchemaName VARCHAR(100)
DECLARE @cmd VARCHAR(5000)



INSERT INTO @fileList(SchemaName,ViewName) 
SELECT s.name,T.name FROM  sys.views T
JOIN sys.schemas S ON S.schema_id = T.schema_id
WHERE t.type = 'V'

------WHERE t.name NOT IN ('ECommerceExperienceLog','ECommerceLog','HS_iQuoteWebLog','HS_Servicelog','HS_SESSION_EXPERIENCE')

SELECT * FROM @fileList ORDER BY ViewName

-- 5 - check for log backups 
DECLARE TableNames CURSOR FOR  
   SELECT ViewName  
   FROM @fileList ORDER BY ViewName


OPEN TableNames  

-- Loop through all the files for the database  
FETCH NEXT FROM TableNames INTO @ViewName
  

WHILE @@FETCH_STATUS = 0  
BEGIN  
   SET @cmd = 'DROP VIEW ' + '['+(SELECT SchemaName FROM @fileList WHERE ViewName=@ViewName)+']' + '.'+ '['+@ViewName+']'    
   PRINT @cmd 
   FETCH NEXT FROM TableNames INTO @ViewName
END 

CLOSE TableNames  
DEALLOCATE TableNames  

