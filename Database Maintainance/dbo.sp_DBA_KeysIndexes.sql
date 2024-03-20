

use master
go

if exists(select 1 from sys.objects where type = 'P' and name = 'sp_DBA_KeysIndexes')
begin
	drop procedure dbo.sp_DBA_KeysIndexes
end
go


create procedure dbo.sp_DBA_KeysIndexes (
	@task varchar(10),
	@runDate datetime = NULL,
	@runID int = NULL,
	@repopulate char(1) = NULL,
	@logOnly char(1) = 'N')
as

/***
	Author:	 Joe Alves
	Date:	 10/01/2013
	Desc:	 drops and or creates keys/constraints/indexes for all tables
	Version: 1.2
	*********************************************************
	modified:	v1.2 - 6/24/2015 - Joe Alves
				-added is_published = 0 to PK criteria
				-added is_ms_shipped = 0 to all criteria
***/

set nocount on

declare @i int
declare @sql varchar(8000)

begin try

	if @task not in ('DROP','CREATE')
	begin
		raiserror('ERROR: Invalid task entered.',12,1)
	end

	--create table to hold indexes if missing
	if not exists(select * from sys.objects where type = 'U' and name = 'tblDBAKeysIndexes' and schema_id = schema_id('dbo'))
	begin
		create table dbo.tblDBAKeysIndexes(
			RunDate datetime,
			RunID int,
			DropSQL varchar(8000),
			CreateSQL varchar(8000),
			SchemaName varchar(200),
			TableName varchar(200),
			IndexName varchar(200),
			IsPrimaryKey bit,
			IsForeignKey bit,
			IsUniqueConstraint bit,
			IsUnique bit,
			IsClustered bit,
			IsFullText bit,
			IsXML bit,
			TypeDesc varchar(100),
			ObjectDropped char(1) NULL,
			ObjectDroppedDate datetime NULL,
			ObjectCreated char(1) NULL,
			ObjectCreatedDate datetime NULL)

		create clustered index clidx_tblDBAKeysIndexes on dbo.tblDBAKeysIndexes (RunDate)
		create unique index uidx1_tblDBAKeysIndexes on dbo.tblDBAKeysIndexes (RunDate, RunID, SchemaName, TableName, IndexName, TypeDesc)
	end


	--delete anything older than 30 days
	delete from dbo.tblDBAKeysIndexes
	where RunDate < dateadd(dd,-30,getdate())


	if @task = 'CREATE' and @repopulate is null 
	begin 
		set @repopulate = 'N'
	end
	else
	begin
		set @repopulate = 'Y'
	end


	if @runDate is null
	begin
		set @runDate =  case 
							when @task = 'CREATE' and @repopulate = 'N' then (select max(RunDate) from dbo.tblDBAKeysIndexes)
							else convert(datetime,convert(varchar(10), getdate(),101))
						end
	end


	if @runID is null
	begin
		set @runID = case 
						 when @repopulate = 'N' then (select max(RunID) from dbo.tblDBAKeysIndexes where RunDate = @runDate)
						 else (select isnull(max(RunID),0)+1 from dbo.tblDBAKeysIndexes where RunDate = @runDate)
					 end
	end



	if @repopulate = 'Y'
	begin
		/*** FullText Indexes ***/
		insert into dbo.tblDBAKeysIndexes (RunDate, RunID, DropSQL, CreateSQL, SchemaName, TableName, IndexName, IsPrimaryKey, IsForeignKey, IsUniqueConstraint, IsUnique, IsClustered, IsFullText, IsXML, TypeDesc)
		select 
			@runDate,
			@runID,
			--'IF  EXISTS (SELECT 1 FROM sys.fulltext_indexes fti WHERE fti.object_id = OBJECT_ID('''+QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(so.object_id))+''')) 
			'DROP FULLTEXT INDEX ON '+ QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(so.object_id)) +''
			,'CREATE FULLTEXT INDEX ON '+ QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(so.object_id)) +' (' +
			STUFF((
					SELECT ',' + QUOTENAME(COL_NAME(so.OBJECT_ID, ic.column_id)) +  
							case 
								when ic.type_column_id is not null then ' TYPE COLUMN ' + QUOTENAME(COL_NAME (so.OBJECT_ID, ic.type_column_id))
								else ''
							end +
							' LANGUAGE ' + cast(ic.language_id as varchar(10))
					FROM sys.fulltext_index_columns AS ic
					WHERE so.OBJECT_ID = ic.OBJECT_ID
					ORDER BY ic.type_column_id desc, ic.column_id
					FOR XML PATH('')),1,1,'') + ')' +
			' KEY INDEX ' + QUOTENAME(si.name) + ' ON (' + QUOTENAME(fc.name) + ', FILEGROUP ' + QUOTENAME(ds.name) + ')' +
			' WITH (CHANGE_TRACKING = ' + fi.change_tracking_state_desc collate SQL_Latin1_General_CP1_CI_AS + 
			', STOPLIST = ' + case when fi.stoplist_id = 0 then 'SYSTEM' else sl.name end +')'
			,SCHEMA_NAME(so.schema_id) as SchemaName
			,OBJECT_NAME(so.OBJECT_ID) AS TableName
			,si.name AS IndexName
			,0 as IsPrimaryKey
			,0 as IsForeignKey
			,0 as IsUniqueConstraint
			,0 as IsUnique
			,0 as IsClustered
			,1 as IsFullText
			,0 as IsXML
			,'FULLTEXT INDEX' as TypeDesc
		from       sys.fulltext_indexes fi 
		inner join sys.objects so on so.object_id = fi.object_id
		inner join sys.indexes si on  si.object_id = so.object_id
								  and si.index_id = fi.unique_index_id
		inner join sys.tables st on st.object_id = fi.object_id
		inner join sys.fulltext_catalogs fc ON fi.fulltext_catalog_id = fc.fulltext_catalog_id
		inner join sys.data_spaces ds on ds.data_space_id = fi.data_space_id
		left join  sys.fulltext_stoplists sl on sl.stoplist_id = fi.stoplist_id		  
		where fi.is_enabled = 1
		  and so.is_ms_shipped = 0
		  and so.name not in ('tblDBAKeysIndexes')




		/*** XML Indexes ***/
		insert into dbo.tblDBAKeysIndexes (RunDate, RunID, DropSQL, CreateSQL, SchemaName, TableName, IndexName, IsPrimaryKey, IsForeignKey, IsUniqueConstraint, IsUnique, IsClustered, IsFullText, IsXML, TypeDesc)
		SELECT
			@runDate,
			@runID,
			--'IF EXISTS (select 1 from sys.indexes where name = ''' + si.name + ''' and object_id = ' + cast(si.object_id as varchar(50)) + ') 
			'DROP INDEX ' + QUOTENAME(si.name) + ' ON ' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(so.object_id))
			,'CREATE ' +
				CASE
					when si.using_xml_index_id is null then ' PRIMARY XML INDEX '
					else ' XML INDEX '
				END +
				QUOTENAME(si.name) + ' ON ' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(so.object_id)) + ' ' + '(' + 
				STUFF((
						SELECT ',' + QUOTENAME(COL_NAME(so.OBJECT_ID, ic.column_id))
						FROM sys.index_columns AS ic
						WHERE si.OBJECT_ID = ic.OBJECT_ID 
						  and si.index_id = ic.index_id
						  and ic.is_included_column = 0
						ORDER BY ic.index_column_id
						FOR XML PATH('')),1,1,'')+')' +
				case
					when si.using_xml_index_id is not null then ' USING XML INDEX ' + QUOTENAME((select name from sys.xml_indexes xi2 where object_id = si.object_id and index_id = si.using_xml_index_id))
					else ''
				end + 
				case
					when si.secondary_type_desc is not null then ' FOR ' + si.secondary_type_desc collate SQL_Latin1_General_CP1_CI_AS
					else ''
				end +
				CASE
					when si.fill_factor = 0 then ' WITH ('
					else ' WITH (FILLFACTOR = ' + cast(si.fill_factor as varchar(3)) + ','
				END +
				CASE
					when si.ignore_dup_key = 1 then ' IGNORE_DUP_KEY = ON'
					else ' IGNORE_DUP_KEY = OFF'
				END +
				CASE
					when si.is_padded = 1 then ', PAD_INDEX = ON'
					else ', PAD_INDEX = OFF'
				END +
				CASE
					when si.allow_page_locks = 1 then ', ALLOW_PAGE_LOCKS = ON'
					else ', ALLOW_PAGE_LOCKS = OFF'
				END +
				CASE
					when si.allow_row_locks = 1 then ', ALLOW_ROW_LOCKS = ON'
					else ', ALLOW_ROW_LOCKS = OFF'
				END + ')'
			,SCHEMA_NAME(so.schema_id) as SchemaName
			,OBJECT_NAME(so.OBJECT_ID) AS TableName
			,si.name AS IndexName
			,si.is_primary_key as IsPrimaryKey
			,0 as IsForeignKey
			,si.is_unique_constraint as IsUniqueConstraint
			,si.is_unique as IsUnique
			,INDEXPROPERTY(so.OBJECT_ID, si.name,'IsClustered' ) as IsClustered
			,0 as IsFullText
			,1 as IsXML
			,case when si.using_xml_index_id is null then 'PRIMARY_XML' else 'SECONDARY_XML' end  as TypeDesc
		FROM sys.objects so
		join sys.xml_indexes AS si on si.object_id = so.object_id
		WHERE so.type in ('U','V')
		  and so.is_ms_shipped = 0
		  and si.type_desc = 'XML'
		  and si.is_disabled = 0
		  and si.is_unique_constraint = 0 
		  and si.is_primary_key = 0
		  and so.name not in ('tblDBAKeysIndexes')



		/*** Indexes ***/
		insert into dbo.tblDBAKeysIndexes (RunDate, RunID, DropSQL, CreateSQL, SchemaName, TableName, IndexName, IsPrimaryKey, IsForeignKey, IsUniqueConstraint, IsUnique, IsClustered, IsFullText, IsXML, TypeDesc)
		SELECT
			@runDate,
			@runID,
			'IF EXISTS (select 1 from sys.objects so join sys.indexes AS si on si.object_id = so.object_id where si.name = ''' + si.name + ''' and so.object_id = ' + cast(so.object_id as varchar(50)) + ') 
			DROP INDEX ' + QUOTENAME(si.name) + ' ON ' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(so.object_id))
			,'IF NOT EXISTS (select 1 from sys.objects so join sys.indexes AS si on si.object_id = so.object_id where si.name = ''' + si.name + ''' and so.object_id = ' + cast(so.object_id as varchar(50)) + ') 
			CREATE ' +
				CASE
					when si.is_unique = 1 then ' UNIQUE '
					else ''
				END +
				CASE INDEXPROPERTY(so.OBJECT_ID, si.name,'IsClustered')
					when 1 then ' CLUSTERED '
					else ' NONCLUSTERED '
				END +
				' INDEX ' +	QUOTENAME(si.name) + ' ON ' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(so.object_id)) + ' ' + '(' + 
				STUFF((
						SELECT ',' + QUOTENAME(COL_NAME(so.OBJECT_ID, ic.column_id)) + case when ic.is_descending_key = 1 then ' DESC' else ' ASC' end
						FROM sys.index_columns AS ic
						WHERE si.OBJECT_ID = ic.OBJECT_ID 
						  and si.index_id = ic.index_id
						  and ic.is_included_column = 0
						ORDER BY ic.key_ordinal--index_column_id
						FOR XML PATH('')),1,1,'')+')' +
				case
					when (SELECT count(*) 
						  FROM sys.index_columns AS ic
						  WHERE si.OBJECT_ID = ic.OBJECT_ID 
							and si.index_id = ic.index_id
							and ic.is_included_column = 1) > 0 then ' INCLUDE ('+
							STUFF((
									SELECT ',' + QUOTENAME(COL_NAME(so.OBJECT_ID, ic.column_id)) 
									FROM sys.index_columns AS ic
									WHERE si.OBJECT_ID = ic.OBJECT_ID 
									  and si.index_id = ic.index_id
									  and ic.is_included_column = 1
									ORDER BY ic.index_column_id
									FOR XML PATH('')),1,1,'') + ')'
					else ''
				end + 
				CASE
					when si.has_filter = 1 then ' WHERE '+si.filter_definition
					else ''
				END +
				CASE
					when si.fill_factor = 0 then ' WITH ('
					else ' WITH (FILLFACTOR = ' + cast(si.fill_factor as varchar(3)) + ','
				END +
				CASE
					when si.ignore_dup_key = 1 then ' IGNORE_DUP_KEY = ON'
					else ' IGNORE_DUP_KEY = OFF'
				END +
				CASE
					when si.is_padded = 1 then ', PAD_INDEX = ON'
					else ', PAD_INDEX = OFF'
				END +
				CASE
					when si.allow_page_locks = 1 then ', ALLOW_PAGE_LOCKS = ON'
					else ', ALLOW_PAGE_LOCKS = OFF'
				END +
				CASE
					when si.allow_row_locks = 1 then ', ALLOW_ROW_LOCKS = ON'
					else ', ALLOW_ROW_LOCKS = OFF'
				END + ')' +
				' ON ' + QUOTENAME(ds.name) + 
				case 
					when ds.type = 'PS' then 
							'(' +
								(SELECT TOP 1 QUOTENAME(c.name)
								FROM sys.index_columns AS ic
								INNER JOIN sys.columns c ON ic.partition_ordinal > 0 and c.object_id = ic.object_id and c.column_id = ic.column_id
								WHERE si.OBJECT_ID = ic.OBJECT_ID 
								  and si.index_id = ic.index_id
								  and ic.is_included_column = 0
								ORDER BY ic.partition_ordinal)
							 + ')' 
					else ''
				end
			,SCHEMA_NAME(so.schema_id) as SchemaName
			,OBJECT_NAME(so.OBJECT_ID) AS TableName
			,si.name AS IndexName
			,si.is_primary_key as IsPrimaryKey
			,0 as IsForeignKey
			,si.is_unique_constraint as IsUniqueConstraint
			,si.is_unique as IsUnique
			,INDEXPROPERTY(so.OBJECT_ID, si.name,'IsClustered' ) as IsClustered
			,0 as IsFullText
			,0 as IsXML
			,case when si.is_unique = 1 then 'UNIQUE ' else '' end + si.type_desc + ' INDEX' as TypeDesc
		FROM sys.objects so
		join sys.indexes AS si on si.object_id = so.object_id
		join sys.data_spaces ds on ds.data_space_id = si.data_space_id
		WHERE so.type in ('U','V')
		  and so.is_ms_shipped = 0
		  and si.type_desc not in ('HEAP', 'XML')
		  and si.is_disabled = 0
		  and si.is_unique_constraint = 0 
		  and si.is_primary_key = 0
		  and so.name not in ('tblDBAKeysIndexes')



		/*** PRIMARY KEYS, unique constraints ***/
		insert into dbo.tblDBAKeysIndexes (RunDate, RunID, DropSQL, CreateSQL, SchemaName, TableName, IndexName, IsPrimaryKey, IsForeignKey, IsUniqueConstraint, IsUnique, IsClustered, IsFullText, IsXML, TypeDesc)
		SELECT
			@runDate,
			@runID,
			'IF EXISTS (select 1 from sys.objects where name = ''' + si.name + ''' and parent_object_id = ' + cast(so.object_id as varchar(50)) + ') 
			ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(so.object_id)) + ' DROP CONSTRAINT ' + QUOTENAME(si.name)
			,'IF NOT EXISTS (select 1 from sys.objects where name = ''' + si.name + ''' and parent_object_id = ' + cast(so.object_id as varchar(50)) + ') 
			ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(so.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(so.object_id)) + ' ADD CONSTRAINT ' + QUOTENAME(si.name) +
				CASE
					when si.is_primary_key = 1 then ' PRIMARY KEY ' 
					when si.is_unique_constraint = 1 then ' UNIQUE '
					else ''
				END +
				CASE INDEXPROPERTY(so.OBJECT_ID, si.name,'IsClustered')
					WHEN 1 THEN ' CLUSTERED '
					ELSE ' NONCLUSTERED '
				END + '(' + 
				STUFF((
						SELECT ',' + QUOTENAME(COL_NAME(so.OBJECT_ID, ic.column_id)) 
						FROM sys.index_columns AS ic
						WHERE si.OBJECT_ID = ic.OBJECT_ID 
						  and si.index_id = ic.index_id
						  and ic.is_included_column = 0
						ORDER BY ic.key_ordinal--index_column_id
						FOR XML PATH('')),1,1,'') + ')' +
				CASE
					when si.has_filter = 1 then ' WHERE '+si.filter_definition
					else ''
				END +
				CASE
					when si.fill_factor = 0 then ' WITH ('
					else ' WITH (FILLFACTOR = ' + cast(si.fill_factor as varchar(3)) + ','
				END +
				CASE
					when si.ignore_dup_key = 1 then ' IGNORE_DUP_KEY = ON'
					else ' IGNORE_DUP_KEY = OFF'
				END +
				CASE
					when si.is_padded = 1 then ', PAD_INDEX = ON'
					else ', PAD_INDEX = OFF'
				END +
				CASE
					when si.allow_page_locks = 1 then ', ALLOW_PAGE_LOCKS = ON'
					else ', ALLOW_PAGE_LOCKS = OFF'
				END +
				CASE
					when si.allow_row_locks = 1 then ', ALLOW_ROW_LOCKS = ON'
					else ', ALLOW_ROW_LOCKS = OFF'
				END + ')'+
				' ON ' + QUOTENAME(ds.name) + 
				case 
					when ds.type = 'PS' then 
							'(' +
								(SELECT TOP 1 QUOTENAME(c.name)
								FROM sys.index_columns AS ic
								INNER JOIN sys.columns c ON ic.partition_ordinal > 0 and c.object_id = ic.object_id and c.column_id = ic.column_id
								WHERE si.OBJECT_ID = ic.OBJECT_ID 
								  and si.index_id = ic.index_id
								  and ic.is_included_column = 0
								ORDER BY ic.partition_ordinal)
							 + ')' 
					else ''
				end
			,SCHEMA_NAME(so.schema_id) as SchemaName
			,OBJECT_NAME(so.OBJECT_ID) AS TableName
			,si.name AS IndexName
			,is_primary_key as IsPrimaryKey
			,0 as IsForeignKey
			,is_unique_constraint as IsUniqueConstraint
			,is_unique as IsUnique
			,INDEXPROPERTY(so.OBJECT_ID, si.name,'IsClustered' ) as IsClustered
			,0 as IsFullText
			,0 as IsXML
			,(select type_desc from sys.objects where name = si.name and parent_object_id = si.object_id and type_desc like '%CONSTRAINT') as TypeDesc
		FROM sys.objects so
		join sys.indexes AS si on si.object_id = so.object_id
		join sys.data_spaces ds on ds.data_space_id = si.data_space_id
		WHERE so.type in ('U','V')
		  and so.is_published = 0
		  and so.is_ms_shipped = 0
		  and si.type_desc <> 'HEAP'
		  and si.is_disabled = 0
		  and (si.is_unique_constraint = 1 or si.is_primary_key = 1)
		  and so.name not in ('tblDBAKeysIndexes')


		/*** FOREIGN KEYS ***/
		insert into dbo.tblDBAKeysIndexes (RunDate, RunID, DropSQL, CreateSQL, SchemaName, TableName, IndexName, IsPrimaryKey, IsForeignKey, IsUniqueConstraint, IsUnique, IsClustered, IsFullText, IsXML, TypeDesc)
		SELECT 
			@runDate,
			@runID,
			'IF EXISTS (select 1 from sys.objects where name = ''' + F.name + ''' and parent_object_id = ' + cast(f.parent_object_id as varchar(50)) + ') 
			ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(F.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(F.parent_object_id)) + ' DROP CONSTRAINT ' + QUOTENAME(F.name)
			,'IF NOT EXISTS (select 1 from sys.objects where name = ''' + F.name + ''' and parent_object_id = ' + cast(f.parent_object_id as varchar(50)) + ') 
			ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(F.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(F.parent_object_id)) + ' WITH CHECK ADD CONSTRAINT ' + QUOTENAME(F.name) +' FOREIGN KEY ' + '(' + 
				STUFF((
						SELECT ',' + QUOTENAME(COL_NAME(FC.parent_object_id, FC.parent_column_id)) 
						FROM SYS.FOREIGN_KEY_COLUMNS AS FC 
						WHERE F.OBJECT_ID = FC.constraint_object_id
						ORDER BY FC.constraint_column_id
						FOR XML PATH('')),1,1,'') + ')' +
				' REFERENCES ' + QUOTENAME(SCHEMA_NAME(RefObj.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(F.referenced_object_id)) + ' (' +
				STUFF((
						SELECT ',' + QUOTENAME(COL_NAME(FC.referenced_object_id, FC.referenced_column_id)) 
						FROM SYS.FOREIGN_KEY_COLUMNS AS FC 
						WHERE F.OBJECT_ID = FC.constraint_object_id
						ORDER BY FC.constraint_column_id
						FOR XML PATH('')),1,1,'') + ') ' +
				CASE 
					WHEN update_referential_action_desc = 'CASCADE' THEN ' ON UPDATE CASCADE'
					WHEN update_referential_action_desc = 'SET_DEFAULT' THEN ' ON UPDATE SET DEFAULT'
					WHEN update_referential_action_desc = 'SET_NULL' THEN ' ON UPDATE SET NULL' 
				ELSE '' END +
				CASE 
					WHEN delete_referential_action_desc = 'CASCADE' THEN ' ON DELETE CASCADE'
					WHEN delete_referential_action_desc = 'SET_DEFAULT' THEN ' ON DELETE SET DEFAULT'
					WHEN delete_referential_action_desc = 'SET_NULL' THEN ' ON DELETE SET NULL'
				ELSE '' END
			,SCHEMA_NAME(F.schema_id) as SchemaName
			,OBJECT_NAME(F.parent_object_id) AS TableName
			,F.name AS IndexName
			,0 as IsPrimaryKey
			,1 as IsForeignKey
			,0 as IsUniqueConstraint
			,0 as IsUnique
			,0 as IsClustered
			,0 as IsFullText
			,0 as IsXML
			,'FOREIGN_KEY_CONSTRAINT' as TypeDesc
		FROM SYS.FOREIGN_KEYS AS F
		INNER JOIN sys.objects RefObj ON RefObj.object_id = f.referenced_object_id
		WHERE RefObj.name not in ('tblDBAKeysIndexes')
		  and RefObj.is_ms_shipped = 0
	end

	-------------------------------------------

	--Create Keys/Constraints/Indexes
	if (upper(@task) = 'CREATE') and (@logOnly = 'N')
	begin
		--build a temp table of create statments
		select 
			row_number() over(order by
				case
					when IsClustered = 1		then 1
					when IsPrimaryKey = 1		then 2
					when IsUniqueConstraint = 1 then 3
					when IsUnique = 1			then 4
					when IsXML = 1 and TypeDesc like 'PRIMARY%'	then 7
					when IsXML = 1 and TypeDesc like 'SECONDARY%' then 8
					when IsFullText = 1			then 9
					when IsForeignKey = 1		then 10
					else 5
				end, TableName, IndexName) as RowNumber,
			CreateSQL
			--,*
		into #creates
		from dbo.tblDBAKeysIndexes
		where RunDate = @runDate
		  and (RunID = @runID or @runID is null)

		--loop through temp table and create objects
		select @i = min(RowNumber) from #creates

		while @i is not null
		begin

			select 
				@sql = CreateSQL
			from #creates
			where RowNumber = @i

			print (@sql)
			exec (@sql)

			update dbo.tblDBAKeysIndexes
			set ObjectCreated = 'Y',
				ObjectCreatedDate = GETDATE()
			where RunDate = @runDate
			  and RunID = @runID
			  and CreateSQL = @sql

			select @i = min(RowNumber) from #creates
			where RowNumber > @i

		end
	end


	--Drop Keys/Constraints/Indexes
	if (upper(@task) = 'DROP') and (@logOnly = 'N')
	begin
		--build a temp table of drop statments
		select 
			row_number() OVER(order by 
								case
									when IsClustered = 1		then 10
									when IsPrimaryKey = 1		then 9
									when IsUniqueConstraint = 1 then 8
									when IsUnique = 1			then 7
									when IsXML = 1 and TypeDesc like 'PRIMARY%'	then 4
									when IsXML = 1 and TypeDesc like 'SECONDARY%' then 3
									when IsFullText = 1			then 2
									when IsForeignKey = 1		then 1 --this is last to be created
									else 6
								end, TableName, IndexName) as RowNumber,
			DropSQL
			--,*
		into #drops
		from dbo.tblDBAKeysIndexes
		where RunDate = @runDate
		  and (RunID = @runID or @runID is null)


		--loop through temp table and drop objects
		select @i = min(RowNumber) from #drops

		while @i is not null
		begin

			select 
				@sql = DropSQL
			from #drops
			where RowNumber = @i

			print (@sql)
			exec (@sql)

			update dbo.tblDBAKeysIndexes
			set ObjectDropped = 'Y',
				ObjectDroppedDate = GETDATE()
			where RunDate = @runDate
			  and RunID = @runID
			  and DropSQL = @sql

			select @i = min(RowNumber) from #drops
			where RowNumber > @i

		end
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



EXEC [sys].[sp_MS_marksystemobject] 'sp_DBA_KeysIndexes';
GO