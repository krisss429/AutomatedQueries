USE msdb;
GO
SELECT name, enabled, description
FROM dbo.sysjobs WHERE notify_level_email = 0;
GO

USE msdb
SELECT name, notify_email_operator_id   
FROM dbo.sysjobs  
WHERE notify_email_operator_id = 0;