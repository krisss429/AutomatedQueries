USE [msdb]
GO
 
SET NOCOUNT ON;
DECLARE @Operator varchar(50) = 'DBA' -- place your operator name here
 
Select 'EXEC sp_update_job @job_name = ''' + j.[name] + 
       ''', @notify_email_operator_name = ''' + @Operator  +
       ''', @notify_level_email = 2'   -- 1=On Success, 2=On Faulure,3=always
       
FROM dbo.sysjobs j
WHERE j.enabled = 1 
AND j.notify_level_email <> 1
GO
