DECLARE @text VARCHAR(1000)
DECLARE @text1 VARCHAR(1000)
DECLARE @sqlcmd nVARCHAR(4000)
DECLARE @jobname varchar(200)
DECLARE @stepid VARCHAR(10)
DECLARE @flag VARCHAR(10) = 8
DECLARE @temp TABLE(Command NVARCHAR(4000))

DECLARE Job_Cursor CURSOR FOR

SELECT JOB.NAME,
STEP.STEP_ID
FROM Msdb.dbo.SysJobs JOB
INNER JOIN Msdb.dbo.SysJobSteps STEP ON STEP.Job_Id = JOB.Job_Id

OPEN Job_Cursor
FETCH NEXT FROM Job_Cursor INTO @jobname,@stepid

WHILE @@FETCH_STATUS=0
BEGIN
	
	SET @sqlcmd='EXEC msdb.dbo.sp_update_jobstep 
    @job_name =N'+''''+@jobname+''+''',
	@step_id ='+@stepid+',
    @flags ='+@flag
	INSERT INTO @temp
	        ( Command )
	SELECT @sqlcmd
	FETCH NEXT FROM Job_Cursor INTO @jobname,@stepid
END
CLOSE Job_Cursor
DEALLOCATE Job_Cursor
SELECT * FROM @temp





