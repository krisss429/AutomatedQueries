----TO Disable
DECLARE @text VARCHAR(1000)
DECLARE @text1 VARCHAR(1000)
SET @text ='exec msdb..sp_update_job @job_name = '''
SET @text1=''', @enabled = 0'
SELECT   @text, name,@text1 FROM dbo.sysjobs WHERE enabled = 1 ORDER BY name

----TO Enable
DECLARE @text VARCHAR(1000)
DECLARE @text1 VARCHAR(1000)
SET @text ='exec msdb..sp_update_job @job_name = '''
SET @text1=''', @enabled = 1'
SELECT   @text, name,@text1 FROM dbo.sysjobs WHERE enabled = 1 ORDER BY name