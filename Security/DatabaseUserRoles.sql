 IF EXISTS ( SELECT *
 FROM tempdb.dbo.sysobjects
 WHERE id =
 OBJECT_ID(N'[tempdb].[dbo].[SQL_DB_REP]') )
 DROP TABLE [tempdb].[dbo].[SQL_DB_REP] ; /*I intentionally left out the space */
 GO
 CREATE TABLE [tempdb].[dbo].[SQL_DB_REP] 
 (
 [Server] [varchar](100) NOT NULL,
 [DB_Name] [varchar](70) NOT NULL,
 [User_Name] [nvarchar](90) NULL,
 [Group_Name] [varchar](100) NULL,
 [Account_Type] [varchar](22) NULL,
 [Login_Name] [varchar](80) NULL,
 [Def_DB] [varchar](100) NULL
 )
 ON [PRIMARY]
 INSERT INTO [tempdb].[dbo].[SQL_DB_REP]
 Exec sp_MSForEachDB 'SELECT CONVERT(varchar(100),
 SERVERPROPERTY(''Servername'')) AS Server,
 ''?'' as DB_Name,
 usu.name u_name
 ,CASE
 WHEN (usg.uid is null) then ''public''
 ELSE usg.name
 END as Group_Name
 ,CASE
 WHEN usu.isntuser=1 then ''Windows Domain Account''
 WHEN usu.isntgroup = 1 then ''Windows Group''
 WHEN usu.issqluser = 1 then ''SQL Account''
 WHEN usu.issqlrole = 1 then ''SQL Role''
 END as Account_Type
 ,lo.loginname
 ,lo.dbname as Def_DB
 FROM
 [?]..sysusers usu LEFT OUTER JOIN
 ([?]..sysmembers mem INNER JOIN [?]..sysusers usg ON
 mem.groupuid = usg.uid) ON usu.uid = mem.memberuid
 LEFT OUTER JOIN master.dbo.syslogins lo on usu.sid =
 lo.sid
 WHERE
 (usu.islogin = 1 and usu.isaliased = 0 and usu.hasdbaccess =
 1) and
 (usg.issqlrole = 1 or usg.uid is null)'
 SELECT [Server],
 [DB_Name],
 [User_Name],
 [Group_Name],
 [Account_Type],
 [Login_Name],
 [Def_DB]
 FROM [tempdb].[dbo].[SQL_DB_REP]
 SELECT [Server],
 [DB_Name],
 [User_Name],
 [Group_Name],
 [Account_Type],
 [Login_Name],
 [Def_DB]
 FROM [tempdb].[dbo].[SQL_DB_REP]
 WHERE 
 --Account_Type = 'SQL ACCOUNT'AND 
 User_Name NOT LIKE '%MS_%' AND 
 USER_NAME NOT IN ('sa','dbo','guest')
 ORDER BY DB_Name,Login_Name