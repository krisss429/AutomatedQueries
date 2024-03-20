declare @maxdbid int
declare @currdbid int

declare @dbname varchar(255)

select database_id ,name
into #db_list
from sys.databases
where [state] = 0 -- 0 means ONLINE


alter table #db_list
add PK_ID int identity

set @currdbid = 1

select @maxdbid = MAX(PK_ID)
from #db_list

while (@currdbid<=@maxdbid)
begin
	
	select @dbname = name 
	from #db_list 
	where PK_ID = @currdbid
	
	--dbcc checkdb(@dbname) with physical_only
	select @currdbid,@maxdbid, @dbname
	
	set @currdbid = @currdbid +1
	
end

drop table #db_list

