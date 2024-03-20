USE
HomesiteWeb_TEST
GO


SET NOCOUNT ON 

-- 1 - Variable declaration 
DECLARE @fileList TABLE (SchemaName varchar(100),ProcName VARCHAR(5000)) 
DECLARE @lastFullBackup NVARCHAR(500) 
DECLARE @lastDiffBackup NVARCHAR(500) 
DECLARE @ProcName VARCHAR(5000)
DECLARE @SchemaName VARCHAR(100)
DECLARE @cmd VARCHAR(5000)



INSERT INTO @fileList(SchemaName,ProcName) 
SELECT s.name,T.name FROM  sys.Objects T
JOIN sys.schemas S ON S.schema_id = T.schema_id
WHERE t.type = 'p'
------WHERE t.name NOT IN ('ECommerceExperienceLog','ECommerceLog','HS_iQuoteWebLog','HS_Servicelog','HS_SESSION_EXPERIENCE')

SELECT * FROM @fileList ORDER BY ProcName

-- 5 - check for log backups 
DECLARE TableNames CURSOR FOR  
   SELECT ProcName  
   FROM @fileList ORDER BY ProcName


OPEN TableNames  

-- Loop through all the files for the database  
FETCH NEXT FROM TableNames INTO @ProcName
  

WHILE @@FETCH_STATUS = 0  
BEGIN  
   SET @cmd = 'DROP PROCEDURE ' + '['+(SELECT SchemaName FROM @fileList WHERE ProcName=@ProcName)+']' + '.'+ '['+@ProcName+']'    
   PRINT @cmd 
   FETCH NEXT FROM TableNames INTO @ProcName
END 

CLOSE TableNames  
DEALLOCATE TableNames  

