USE [msdb]
GO

/****** Object:  StoredProcedure [dbo].[hssp_RPT_LogShipping]    Script Date: 7/22/2016 9:19:27 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[hssp_RPT_LogShipping] 
	@DatabaseName VARCHAR(32) -- database name
	,@SourceLocation VARCHAR(32) -- such as BOS AKR MAR etc
	,@SourceServerName VARCHAR (64) -- source SQL server name
	,@SourceDriverLetter CHAR(1) -- source disk driver assigned letter , such as T
	,@SourceLogFileFolder VARCHAR(64) -- such as '\dir\sub_folder\'
	,@DistLogFilePath VARCHAR(128) -- <driver letter>:\folder\sub_folder\'
	,@ProcessingFlag VARCHAR (8)--'RUN' for log shiping ; 'TEST' for log file scripting
	,@SpecialLogFileName VARCHAR(128) -- special log file SHOULD BE EXCLUDED from processing
AS 
-- Note: 
--	1. This SP created in MSDB and should be run in MASTER
--	2. Log file stamp string is subject to verify in target env - see mark '!!!!!'
--
-- Rev.001 05/05/2012: Rewritten -sz
--
BEGIN
set nocount on
print '-- Processing Status:' + @ProcessingFlag
print '-- ' + @SourceLocation + ':' + @DatabaseName + ' Log shipping from '+ @SourceServerName
--
declare @dbname NVARCHAR(255)
declare @strSrcTimeStamp BIGINT, @LocalCurrentTimeStamp varchar(32)
declare @strSourceFileName NVARCHAR(520)
declare @strSourceLocalPath VARCHAR(255)
declare @strSourceUNCPath VARCHAR(255)
declare @strSourceServer VARCHAR(255)
declare @strDestPath VARCHAR(255)
declare @strcopycmd VARCHAR(2148)
declare @strrestorecmd VARCHAR(2148)
declare @cmd varchar (2148)
--
set @dbname = @DatabaseName -- 'ISO_PRINT' -- <<<< Input
--
-- select [name] from sys.databases where (state_desc = 'RESTORING' or is_in_standby = 1) and name = @dbname order by [name]
--
set @strSrcTimestamp = 0
set @strDestPath = @DistLogFilePath -- 'J:\Tlogs\ISO_PRINT_TRXN_LOGS_2K8\'
--
-- DR Location special
--
set @strSourceLocalPath = @SourceDriverLetter +':' + @SourceLogFileFolder -- 'T:\BACKUP\ISO_PRINT\TLOGS\'
set @strSourceUNCPath = '\\'+ @SourceServerName +'\' + @SourceDriverLetter + '$'+ @SourceLogFileFolder --'\\ASGMARSQL804\T$\BACKUP\ISO_PRINT\TLOGS\'
set @cmd = 'NET USE '+ '\\' + @SourceServerName +'\' + @SourceDriverLetter + '$' + ' "4muTT&jeFF" /user:asgard\sqlaccount'-- 'NET USE \\ASGMARSQL804\T$ "4muTT&jeFF" /user:asgard\sqlaccount'
EXEC MASTER.DBO.XP_CMDSHELL @cmd
--
-- !!!!! Get current restored last log file stamp
-- 
select top 1 @LocalCurrentTimeStamp = ISNULL(LEFT(RIGHT(bmf.physical_device_name,16),12),'')
--,bmf.physical_device_name
from msdb.dbo.backupset ms 
join msdb.dbo.backupmediafamily bmf on ms.media_set_id = bmf.media_set_id
where ms.type = 'L' and ms.database_name = @dbname
order by ms.backup_finish_date desc
if @LocalCurrentTimeStamp = '' or ISNUMERIC (@LocalCurrentTimeStamp) = 0 begin
	print '-- !!! Manual log loading needed. Last loaded log file stamp string is NOT in standard form as :' + @strSrcTimestamp
	return 0;
END 
set @strSrcTimestamp = @LocalCurrentTimeStamp
print '-- Last loaded log file stamp string as :'
	+ case when @strSrcTimeStamp =0 then 'N/A' else cast(@strSrcTimeStamp as varchar)end
if @strSrcTimeStamp =0 begin
	print '-- Error: Dist Database ' + @dbname + 'log shipping is not initialized yet!'
	RETURN 0
END
--
-- make list file command
--
set @cmd = 'EXEC MASTER.DBO.XP_CMDSHELL ''dir  /b  ' + @strSourceUNCPath + '''';
print @cmd
--
-- Get Log file list from source floder
--
create table #1 (fn varchar(510)) -- drop table #1; select * from #1
insert into #1
exec(@cmd) -- 'master.dbo.xp_cmdshell ''dir  /b \\ASGSQL07\D$\BACKUP\ISO_PRINT\tlogs'''
-- excluding special named log file
if @SpecialLogFileName is not null and RTRIM(@SpecialLogFileName) <> ''
	delete from #1 
	where 
		fn = RTRIM(@SpecialLogFileName) -- 'ISO_PRINT_20110821_061421.trn'
		or isnumeric(substring(right(fn,18),3,12))=0
--
-- !!!!!! Get log file info and sort them (in the case) 
--
declare @tn int, @ti int, @fn varchar(512)
create table #tf (fid int identity(1,1) primary key, fn varchar(510), fstamp bigint)
insert into #tf (fn, fstamp)
select --201205200545.Trn as right(fn,16),1,12 -- 20120520054500.Trnright(fn,18),3,12 select cast(substring(right('ISO_PROD_20120520162000.Trn',16),1,12) as bigint)
	fn 
	,cast(substring(right(fn,18),3,12) as bigint) as fstamp
from 
	#1
where
	fn is not null and right(fn,3) = 'trn' -- must no null and be trn files
and  -- log file stamp greater then current one
	cast(substring(right(fn,18),3,12) as bigint) > @strSrcTimestamp 
order by fn 
set @tn = @@rowcount -- hosted file
SET @ti = 1 -- first fid
--
-- Restore log files if any
--
PRINT '-- Log file to be restored: ' + CAST( @tn AS VARCHAR)
WHILE @tn >= @ti BEGIN
	SELECT @fn = fn FROM #tf WHERE fid = @ti -- get current log file name
	PRINT '-- Log file to be loading: ' + @fn
	--
	-- Copy selected log file
	--
	SET @strcopycmd = 'COPY ' + @strSourceUNCPath + @fn +' ' 
		+ @strDestPath + @fn + ' /Y'
	PRINT @strCopyCmd
	IF @ProcessingFlag = 'RUN'
		EXEC master.dbo.xp_cmdshell @strCopyCmd
	--
	-- Restore the log file
	--
	SET @strrestorecmd = 'RESTORE LOG ' + @dbname + ' FROM DISK = ' + '''' + @strDestPath + @fn + '''' + ' WITH NORECOVERY'
	PRINT @strrestorecmd 
	IF @ProcessingFlag = 'RUN' BEGIN
		EXEC msdb.dbo.cp_kill_database_users @dbname
		EXEC (@strrestorecmd)
	END
	--
	SET @ti = @ti+1;
END
--
-- Finish log restore @DistLogFilePath
--
SET @strrestorecmd = 'RESTORE DATABASE ' + @dbname + '  WITH STANDBY = ' + '''' 
		+ @DistLogFilePath + @dbname + '.redo' + ''''
--		+ 'J:\Tlogs\ISO_PRINT_TRXN_LOGS_2K8' + @dbname + '.redo' + ''''

PRINT '-- MSG: ' + @strrestorecmd 

IF @tn > 0 AND  @ProcessingFlag = 'RUN' BEGIN -- put database into stand by
	PRINT '-- Log shipping is going to set database ' + @dbname + ' in STAND-BY mode'
	EXEC (@strrestorecmd)
END
--
SET @cmd = 'NET USE '+ '\\' + @SourceServerName +'\' + @SourceDriverLetter + '$ /d' -- EXEC MASTER.DBO.XP_CMDSHELL 'NET USE \\ASGMARSQL804\T$ /d'
EXEC MASTER.DBO.XP_CMDSHELL @cmd
DROP TABLE #tf;
DROP TABLE #1;
--
PRINT '-- Done log shipping at: ' + @dbname
END -- hssp_RPT_LogShipping


GO


