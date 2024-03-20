USE [master]
GO

/****** Object:  StoredProcedure [dbo].[hssp_ReadOnly_AppSync_Databases_SQL02]    Script Date: 10/25/2019 6:01:04 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[hssp_ReadOnly_AppSync_Databases_SQL02]
AS
BEGIN
    DECLARE @DatabaseName VARCHAR(100)
    DECLARE @LoginName VARCHAR(100)
    DECLARE @MinDatabaseID INT
    DECLARE @MaxDatabaseID INT
    DECLARE @MinLoginID INT
    DECLARE @MaxLoginID INT
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
('DM_Billing_Prod')

    --Check for temporary table and drop it if it exists
    IF OBJECT_ID('tempDB.dbo.#LoginName') IS NOT NULL
        DROP TABLE [#Login];

    --Create temporary table
    CREATE TABLE #Login
    (
        ID INT IDENTITY(1, 1),
        LoginName VARCHAR(100)
    )

    --Insert all Login names into a temporary table
    INSERT INTO #Login
    (
        LoginName
    )
    VALUES
    ('CAMELOT\Developers'),
    ('CAMELOT\QA')

    --Set Variables for the Create database loop 
    SELECT @MinDatabaseID = MIN(ID),
           @MaxDatabaseID = MAX(ID)
    FROM #Database

    --Begin loop to set databases in Read_Only Mode
    WHILE @MinDatabaseID <= @MaxDatabaseID
    BEGIN
        --Get DatabaseName
        SELECT @DatabaseName = DatabaseName
        FROM #Database
        WHERE ID = @MinDatabaseID

        SELECT @MinLoginID = MIN(ID),
               @MaxLoginID = MAX(ID)
        FROM #Login

        WHILE @MinLoginID <= @MaxLoginID
        BEGIN

            --Get LoginName
            SELECT @LoginName = LoginName
            FROM #Login
            WHERE ID = @MinLoginID

            SET @SQL
                = 'USE Master;' + CHAR(13)
                  + 'IF NOT EXISTS (SELECT name FROM sys.syslogins WHERE (''['' + name + '']'' =' + '''' + @LoginName
                  + '''' + ' OR name =' + '''' + @LoginName + '''' + '))' + CHAR(13) + 'BEGIN' + CHAR(13)
                  + 'CREATE LOGIN [' + @LoginName + '] FROM WINDOWS WITH DEFAULT_DATABASE= [master]' + CHAR(13) + 'END'
                  + CHAR(13) + CHAR(13) + 'USE ' + @DatabaseName + ';' + CHAR(13)
                  + 'IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE (''['' + name + '']'' =' + ''''
                  + @LoginName + '''' + ' OR name =' + '''' + @LoginName + '''' + '))' + CHAR(13) + 'BEGIN' + CHAR(13)
                  + 'CREATE USER [' + @LoginName + '] FOR LOGIN [' + @LoginName + '] WITH DEFAULT_SCHEMA= [dbo]'
                  + CHAR(13) + 'ALTER ROLE [db_datareader] ADD MEMBER [' + @LoginName + ']' + CHAR(13) + 'END'
                  + CHAR(13)

            BEGIN TRY
                --Add Logins
                EXEC (@SQL)
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
            SET @MinLoginID = @MinLoginID + 1
        END

        IF (@DatabaseName = 'BrandServiceData')
        BEGIN
            --Build Command to Set Database to Read_Only mode after removing replication
            SET @SQL
                = 'IF EXISTS (SELECT name FROM sys.sysdatabases WHERE (''['' + name + '']'' =' + '''' + @DatabaseName
                  + '''' + '  OR name =' + '''' + @DatabaseName + '''' + '))' + CHAR(13) + 'BEGIN' + CHAR(13) + 'USE '
                  + @DatabaseName + ';' + CHAR(13) + 'DISABLE TRIGGER [trg_auditTableDDlAllEvents] ON DATABASE'
                  + CHAR(13) + CHAR(13) + 'USE master;' + CHAR(13) + 'EXEC sp_removedbreplication ''' + @DatabaseName
                  + '''' + CHAR(13) + CHAR(13) + 'USE ' + @DatabaseName + ';' + CHAR(13)
                  + 'EXEC dbo.sp_changedbowner @loginame = N''sa''' + CHAR(13) + CHAR(13) + 'USE master;' + CHAR(13)
                  + 'ALTER DATABASE' + ' ' + @DatabaseName + ' ' + 'SET READ_ONLY WITH ROLLBACK IMMEDIATE' + CHAR(13)
                  + 'END' + CHAR(13) + CHAR(13) + 'ELSE' + CHAR(13) + 'PRINT ' + '''' + '**' + @DatabaseName + '**'
                  + ' DOES NOT EXISTS' + ''''
        END
        ELSE
            --Build Command to Set Database to Read_Only mode
            SET @SQL
                = 'USE master;' + CHAR(13)
                  + 'IF EXISTS (SELECT name FROM sys.sysdatabases WHERE (''['' + name + '']'' =' + '''' + @DatabaseName
                  + '''' + '  OR name =' + '''' + @DatabaseName + '''' + '))' + CHAR(13) + 'BEGIN' + CHAR(13) + 'USE '
                  + @DatabaseName + ';' + CHAR(13) + 'EXEC dbo.sp_changedbowner @loginame = N''sa''' + CHAR(13)
                  + CHAR(13) + 'USE master;' + CHAR(13) + 'ALTER DATABASE' + ' ' + @DatabaseName + ' '
                  + 'SET READ_ONLY WITH ROLLBACK IMMEDIATE' + CHAR(13) + 'END' + CHAR(13) + CHAR(13) + 'ELSE'
                  + CHAR(13) + 'PRINT ' + '''' + '**' + @DatabaseName + '**' + ' DOES NOT EXISTS' + ''''

        --Try Catch block to execute SQL and handle errors            
        BEGIN TRY
            --Detach Database
            EXEC (@SQL)
            PRINT @DatabaseName + ' is set to Read_Only mode'
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

GO


