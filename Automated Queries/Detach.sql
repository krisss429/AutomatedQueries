USE [master]
GO
/****** Object:  StoredProcedure [dbo].[hssp_Detach_AppSync_Databases_SQL03]    Script Date: 10/25/2019 6:00:18 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[hssp_Detach_AppSync_Databases_SQL03]
AS
BEGIN
    DECLARE @DatabaseName VARCHAR(100)
    DECLARE @MinDatabaseID INT
    DECLARE @MaxDatabaseID INT
    DECLARE @SQL VARCHAR(4000)

    --Check for temporary table and drop it if it exists
    IF OBJECT_ID('tempDB.dbo.#Database') IS NOT NULL
        DROP TABLE [#Database];

    --Create temporary table
    CREATE TABLE #Database
    (
        ID INT IDENTITY(1, 1),
        DatabaseName VARCHAR(100)
    )

    --Insert all database names into a temporary table
    INSERT INTO #Database
    (
        DatabaseName
    )
    VALUES
    ('ISO_Rating_Prod')
    

    --SELECT *
    --FROM #Database

    --Set Variables for the detach database loop 
    SELECT @MinDatabaseID = MIN(ID),
           @MaxDatabaseID = MAX(ID)
    FROM #Database

    --Begin loop to detach databases
    WHILE @MinDatabaseID <= @MaxDatabaseID
    BEGIN
        --Get DatabaseName
        SELECT @DatabaseName = DatabaseName
        FROM #Database
        WHERE ID = @MinDatabaseID

        --Build Detach Database Command
        SET @SQL
        = N'USE MASTER' + CHAR(13) + N'IF EXISTS (SELECT name FROM sys.sysdatabases WHERE (''['' + name + '']'' ='
          + N'''' + @DatabaseName + N'''' + N'  OR name =' + N'''' + @DatabaseName + N'''' + '))' + CHAR(13) + N'BEGIN'
          + CHAR(13) + N'ALTER DATABASE' + N' ' + @DatabaseName + N' ' + N'SET OFFLINE WITH ROLLBACK IMMEDIATE'
          + CHAR(13) + N'EXEC sp_detach_db ' + N'''' + @DatabaseName + N'''' + N';' + CHAR(13) + N'END' + CHAR(13)
          + N'ELSE' + CHAR(13) + N'PRINT ' + N'''' + +@DatabaseName + N' does not exists' + N''''

        --Try Catch block to execute SQL and handle errors            
        BEGIN TRY
            --Detach Database
            EXEC (@SQL)
            PRINT 'Detached ' + @DatabaseName
        END TRY
        BEGIN CATCH
            SELECT @DatabaseName,
                   message_id,
                   severity,
                   [text],
                   @SQL
            FROM sys.messages
            WHERE message_id = @@ERROR
                  AND language_id = 1033 -- English
        END CATCH

        --Get the next DatabaseName ID
        SET @MinDatabaseID = @MinDatabaseID + 1
    --End Loop
    END
END

