

use master
go

if exists(select 1 from sys.objects where type = 'P' and name = 'sp_DBA_Triggers')
begin
	drop procedure dbo.sp_DBA_Triggers
end
go

create procedure dbo.sp_DBA_Triggers (
	@task varchar(10),
	@recentOnly bit = NULL)
as


/***
	Author:	Joe Alves
	Date:	10/01/2013
	Desc:	enables or disables triggers
	Version: 1.1
	*********************************************************
	modified:	v1.1 - 6/24/2015 - Joe Alves
				-added logic to make @recentOnly default = 1 for ENABLE task
***/

set nocount on

begin try

	declare @i int
	declare @sql varchar(8000)

	--only enable recently disabled triggers as we don't want to accidently enable triggers
	--that were intentionally turned off at some point in the past
	--triggers that were already disabled won't have their modify_date changed
	--by attempting to disable again
	if @task = 'ENABLE' and @recentOnly is null
	begin
		set @recentOnly = 1
	end

	if @recentOnly = 1
	begin
		declare @date datetime
		set @date = (select convert(datetime,convert(varchar(10),max(modify_date),101)) from sys.triggers)
	end

	if @task not in ('DISABLE','ENABLE')
	begin
		raiserror('ERROR: Invalid task entered.',12,1)
	end

	create table #trigs (
		ID int identity (1,1),
		ExecSQL varchar(4000))

	insert into #trigs(ExecSQL)
	select 
		case
			when upper(@task) = 'DISABLE' then
				'DISABLE TRIGGER ' + quotename(ss2.name)+'.'+quotename(st.name) + ' ON ' + quotename(ss1.name)+'.'+quotename(so1.name) + ';'
			when upper(@task) = 'ENABLE' then
				'ENABLE TRIGGER ' + quotename(ss2.name)+'.'+quotename(st.name) + ' ON ' + quotename(ss1.name)+'.'+quotename(so1.name) + ';'
		end
	from sys.triggers st
	join sys.objects so1 on so1.object_id = st.parent_id
	join sys.schemas ss1 on ss1.schema_id = so1.schema_id
	join sys.objects so2 on so2.object_id = st.object_id
	join sys.schemas ss2 on ss2.schema_id = so2.schema_id
	where st.is_ms_shipped = 0
	  and so1.type = 'U'
	  and (
		   (convert(datetime,convert(varchar(10),st.modify_date,101)) = @date) 
			OR (@date is null)
		  )


	--loop through temp table and drop objects
	select @i = min(ID) from #trigs

	while @i is not null
	begin

		select 
			@sql = ExecSQL
		from #trigs
		where ID = @i

		print (@sql)
		exec (@sql)

		select @i = min(ID) from #trigs
		where ID > @i

	end

end try
begin catch
	--raise error to front end
	declare @errProc nvarchar(126),
			@errLine int,
			@errMsg  nvarchar(max)
	select  @errProc = error_procedure(),
			@errLine = error_line(),
			@errMsg  = error_message()
	raiserror('Proc: %s - Line: %d - Error: %s', 12 ,1 ,@errProc, @errLine, @errMsg)
	return(-1)
end catch

go



EXEC [sys].[sp_MS_marksystemobject] 'sp_DBA_Triggers';
GO