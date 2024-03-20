SET NOCOUNT ON;
SELECT command AS Before_Updating
FROM msdb.dbo.sysjobsteps
WHERE step_name = 'userdbs - Log Backup'
      AND job_id =
      (
          SELECT job_id
          FROM msdb.dbo.sysjobs
          WHERE name = 'DBMaint - USERDB - Log Backup'
      );

DECLARE @ReplacedCommand NVARCHAR(MAX);

SELECT @ReplacedCommand = REPLACE(command, '@CleanupTime = 48', '@CleanupTime = 168')
FROM msdb.dbo.sysjobsteps
WHERE step_name = 'userdbs - Log Backup'
      AND job_id =
      (
          SELECT job_id
          FROM msdb.dbo.sysjobs
          WHERE name = 'DBMaint - USERDB - Log Backup'
      );

EXEC msdb.dbo.sp_update_jobstep @job_name = 'DBMaint - USERDB - Log Backup',
                           @step_name = 'userdbs - Log Backup',
                           @step_id = 1,
                           @command = @ReplacedCommand;
GO

SELECT command AS After_Updating
FROM msdb.dbo.sysjobsteps
WHERE step_name = 'userdbs - Log Backup'
      AND job_id =
      (
          SELECT job_id
          FROM msdb.dbo.sysjobs
          WHERE name = 'DBMaint - USERDB - Log Backup'
      );