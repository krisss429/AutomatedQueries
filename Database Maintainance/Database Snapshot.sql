Declare @SnapshotName varchar(255)
DECLARE @exec_sql VARCHAR(MAX)

Select @SnapshotName = DB_NAME()


-- get logical file names
SELECT name, physical_name
INTO #FileNames
FROM sys.database_files
WHERE type = 0 --rows data, no ldf

SELECT @exec_sql = 'CREATE DATABASE ' + @SnapshotName+'_SS' + ' ON ' 
SELECT @exec_sql = @exec_sql + CHAR(13) + CHAR(10) + 
		'(NAME =' + QUOTENAME(Name) 
		+ ', FILENAME = ''' + physical_name + '.snap''),' 
FROM #FileNames

SELECT @exec_sql = LEFT(@exec_sql,len(@exec_sql)-1) + CHAR(13) + CHAR(10)  + ' AS SNAPSHOT OF ' + DB_NAME() 

PRINT 'This is the command to run'
PRINT @exec_sql 
--EXEC (@exec_sql)

PRINT 'This command can be used to RESTORE your db from the snapshot'
PRINT 'RESTORE DATABASE ' + DB_NAME() + ' FROM DATABASE_SNAPSHOT = ''' + @SnapshotName+'_SS''' + ';'

drop table #FileNames


