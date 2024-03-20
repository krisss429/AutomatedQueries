USE ISO_Rating_Prod -- Change desired database name here
GO
SET NOCOUNT ON
GO
DECLARE updatestats CURSOR FOR
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
OPEN updatestats

DECLARE @tablename NVARCHAR(128)
DECLARE @Statement NVARCHAR(300)

FETCH NEXT FROM updatestats
INTO @tablename
WHILE (@@FETCH_STATUS = 0)
BEGIN
    PRINT N'--UPDATING STATISTICS ' + @tablename
    SET @Statement = N'UPDATE STATISTICS ' + @tablename + N'  WITH FULLSCAN'
    --EXEC sp_executesql @Statement
	PRINT @Statement
    FETCH NEXT FROM updatestats
    INTO @tablename
END

CLOSE updatestats
DEALLOCATE updatestats
GO
SET NOCOUNT OFF
GO