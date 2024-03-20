USE [master]
GO

/****** Object:  DdlTrigger [Trg_Deny_Invalid_Login]    Script Date: 9/6/2016 10:23:53 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [Trg_Deny_Invalid_Login] ON ALL SERVER
    WITH EXECUTE AS 'sa'
    FOR LOGON
AS
    BEGIN

-- Purpose - Deny connection attempt of any SQL Non Interactive Functional Account
--This Trigger will Deny a Login attampt if 
-- -- -- -- -- -- a. Host Name is other than valid hosts
-- -- -- -- -- -- b. If any known SQL Native tool is being used 
-- To add a Login Names, Host Names(twice) or SQL Interactive Tools  
-- -- script out the trigger and modify the 
-- -- -- -- values below the commented sections 
-- -- -- -- and recreate the trigger in **MASTER** database

        IF ( ORIGINAL_LOGIN() IN -- -- -- -- -- -- -- -- -- --  List of Logins -- -- -- -- -- -- -- -- -- -- -- 
			  (SELECT UserName
				FROM [DBA_Utility].[dbo].[tbl_AppLoginMonAccounts])
				AND ( HOST_NAME() NOT LIKE 'HSWEBDEV%'	--'ASGAKRWEBAPP%''	--'CAMUATAPP%' ---'CAMQAAPP%'
                                  AND HOST_NAME() NOT LIKE 'ITDESK%'
                                  AND HOST_NAME() NOT LIKE 'ITLAP%'
                                  AND HOST_NAME() NOT LIKE 'ACTDESK%'
                                  AND HOST_NAME() NOT LIKE 'MKTLAP%'
                                  AND HOST_NAME() NOT LIKE 'MKTDESK%'
                                  AND HOST_NAME() NOT LIKE 'ACTLAP%')
			)
		BEGIN
				INSERT INTO [DBA_Utility].[dbo].[tbl_AppLoginMonLogs] (Hostname,LoginName,ProgramName)
				VALUES (HOST_NAME(),ORIGINAL_LOGIN(),program_name())
		END


        IF ( ORIGINAL_LOGIN() IN -- -- -- -- -- -- -- -- -- --  List of Logins -- -- -- -- -- -- -- -- -- -- -- 
				(SELECT UserName
					FROM [DBA_Utility].[dbo].[tbl_AppLoginAccounts])
             AND ( EXISTS ( SELECT  *
                            FROM    sys.dm_exec_sessions
                            WHERE   session_id = @@spid
                            AND		is_user_process = 1 
-- -- -- -- -- -- -- -- -- -- -- Host Names -- -- -- -- -- -- -- -- -- -- -- --
                            AND ( HOST_NAME LIKE 'HSWEBDEV%'	--'ASGAKRWEBAPP%''	--'CAMUATAPP%' ---'CAMQAAPP%'
                                  OR HOST_NAME LIKE 'ITDESK%'
                                  OR HOST_NAME LIKE 'ITLAP%'
                                  OR HOST_NAME LIKE 'ACTDESK%'
                                  OR HOST_NAME LIKE 'MKTLAP%'
                                  OR HOST_NAME LIKE 'MKTDESK%'
                                  OR HOST_NAME LIKE 'ACTLAP%'		---'PRODAKRWEB%'	--'UATWEB%'		--'QAWEB%'
                                        )
-- -- -- -- -- -- -- -- -- -- Interactive Tools -- -- -- -- -- -- -- -- -- -- --
                            AND program_name IN (
                            'Microsoft SQL Server',
                            'Microsoft SQL Server Management Studio',
                            'Microsoft SQL Server Management Studio - Query',
                            'SQLCMD', 
                            'OSQL-32', 
                            'Toad',
                            --'.Net SqlClient Data Provider',
                            'SQL Query Analyzer' ) ) )
           ) 
            BEGIN
                PRINT 'Interactive or Invalid Login Attempt of ' + ORIGINAL_LOGIN()
                ROLLBACK ;

				INSERT INTO [DBA_Utility].[dbo].[tbl_auditTableLogonTrg] (Hostname,LoginName,ProgramName)
				VALUES (HOST_NAME(),ORIGINAL_LOGIN(),program_name())
            END

    END ;


GO

ENABLE TRIGGER [Trg_Deny_Invalid_Login] ON ALL SERVER
GO


