USE [msdb]
GO

/****** Object:  StoredProcedure [dbo].[cp_kill_database_users]    Script Date: 7/22/2016 9:19:22 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[cp_kill_database_users] @arg_dbname sysname WITH RECOMPILE
AS

-- kills all the users in a particular database
-- dlhatheway/3M, 11-Jun-2000

DECLARE @a_spid	SMALLINT
DECLARE @msg	VARCHAR(255)
DECLARE @a_dbid	INT

SELECT
	@a_dbid = sdb.dbid
FROM	master..sysdatabases sdb
WHERE	sdb.name = @arg_dbname

DECLARE db_users INSENSITIVE CURSOR FOR
SELECT
	sp.spid
FROM	master..sysprocesses sp
WHERE	sp.dbid = @a_dbid
UNION
 SELECT  CONVERT (SMALLINT, req_spid) AS spid 
 FROM  master.dbo.syslockinfo,  
  master.dbo.spt_values v,  
  master.dbo.spt_values x,  
  master.dbo.spt_values u  
   WHERE   master.dbo.syslockinfo.rsc_type = v.number  
   AND v.type = 'LR'  
   AND master.dbo.syslockinfo.req_status = x.number  
   AND x.type = 'LS'  
   AND master.dbo.syslockinfo.req_mode + 1 = u.number  
   AND u.type = 'L' 
   AND rsc_dbid = @a_dbid


OPEN db_users

FETCH NEXT FROM db_users INTO @a_spid
WHILE @@fetch_status = 0
	BEGIN
	SELECT @msg = 'kill '+CONVERT(CHAR(5),@a_spid)
	PRINT @msg
	EXECUTE (@msg)
	FETCH NEXT FROM db_users INTO @a_spid
	END

CLOSE db_users
DEALLOCATE db_users
--
-- end
--



GO


