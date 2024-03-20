
declare @x int, @y int, @z int
declare @counter smallint
declare @days varchar(100), @day varchar(10)
declare @jname sysname, @freq_interval int, @jid varchar(50)
SET NOCOUNT ON

create table #temp (jid varchar(50), jname sysname, 
Jdays varchar(100))
--This cursor runs throough all the jobs that have a weekly frequency running on different days
Declare c cursor for select job_id, name, freq_interval from msdb..sysschedules a, msdb..sysjobschedules b
where freq_type = 8 and a.schedule_id = b.schedule_id
Open c
Fetch Next from c into @jid, @jname, @freq_interval
while @@fetch_status = 0
Begin
set @counter = 0
set @x = 64
set @y = @freq_interval
set @z = @y
set @days = ''
set @day = ''

while @y <> 0
begin
select @y = @y - @x
select @counter = @counter + 1
If @y < 0 
Begin
set @y = @z
GOTO start
End


Select @day = CASE @x
when 1 Then 'Sunday'
when 2 Then 'Monday'
when 4 Then 'Tuesday'
when 8 Then 'Wednesday'
when 16 Then 'Thursday'
when 32 Then 'Friday'
when 64 Then 'Saturday'
End

select @days = @day + ',' + @days
start:
Select @x = CASE @counter
When 1 then 32
When 2 then 16
When 3 then 8
When 4 then 4
When 5 then 2
When 6 then 1
End

set @z = @y
if @y = 0 break
end

Insert into #temp select @jid, @jname, left(@days, len(@days)-1)
Fetch Next from c into @jid, @jname, @freq_interval

End
close c
deallocate c

--Final query to extract complete information by joining sysjobs, sysjobschedules and #Temp table

select @@servername,
  b.name Job_Name, 
  CASE b.enabled 
	when 1 then 'Enabled'
	Else 'Disabled'
  End as 'JobEnabled', 
--  a.name as 'Schedule_Name', 
  CASE a.enabled 
	when 1 then 'Enabled'
	Else 'Disabled'
  End as 'ScheduleEnabled',
  CASE freq_type 
	when 1 Then 'Once'
	when 4 Then 'Daily'
	when 8 then 'Weekly'
	when 16 Then 'Monthly' --+ cast(freq_interval as char(2)) + 'th Day'
	when 32 Then 'Monthly Relative'
	when 64 Then 'Execute When SQL Server Agent Starts'
  End as 'Job Frequency',
  CASE freq_type 
	when 32 then CASE freq_relative_interval
					when 1 then 'First'
					when 2 then 'Second'
					when 4 then 'Third'
					when 8 then 'Fourth'
					when 16 then 'Last'
				 End
	Else ''
  End as 'Monthly Frequency',
  CASE freq_type
	when 16 then 'Day '+cast(freq_interval as varchar(2)) + ' of Month'
	when 32 then CASE freq_interval 
					when 1 then 'Sunday'
					when 2 then 'Monday'
					when 3 then 'Tuesday'
					when 4 then 'Wednesday'
					when 5 then 'Thursday'
					when 6 then 'Friday'
					when 7 then 'Saturday'
					when 8 then 'Day'
					when 9 then 'Weekday'
					when 10 then 'Weekend day'
				 End
	when 8 then c.Jdays
	Else ''
  End as 'Runs On',
  CASE freq_subday_type
	when 1 then 'At the specified Time'
	when 2 then 'Seconds'
	when 4 then 'Minutes'
	when 8 then 'Hours'
  End as 'Interval Type',
  CASE freq_subday_type 
	when 1 then 0
	Else freq_subday_interval 
  End as 'Time Interval',
  CASE freq_type 
	when 8 then cast(freq_recurrence_factor as char(2)) + ' Week'
	when 16 Then cast(freq_recurrence_factor as char(2)) + ' Month'
	when 32 Then cast(freq_recurrence_factor as char(2)) + ' Month'
	Else ''
  End as 'Occurs Every',
--  left(active_start_date,4) + '-' + substring(cast(active_start_date as char),5,2) 
--  + '-' + right(active_start_date,2) 'Begin Date-Executing Job', 
  left(REPLICATE('0', 6-len(active_start_time)) + cast(active_start_time as char(6)),2) + ':' +
  substring(REPLICATE('0', 6-len(active_start_time)) + cast(active_start_time as char(6)),3,2) + ':' +
  substring(REPLICATE('0', 6-len(active_start_time)) + cast(active_start_time as char(6)),5,2) as 'Executing At'

--  left(active_end_date,4) + '-' + substring(cast(active_end_date as char),5,2) 
--  + '-' + right(active_end_date,2) [End Date-Executing Job],

--  left(REPLICATE('0', 6-len(active_end_time)) + cast(active_end_time as char(6)),2) + ':' +
--  substring(REPLICATE('0', 6-len(active_end_time)) + cast(active_end_time as char(6)),3,2) + ':' +
--  substring(REPLICATE('0', 6-len(active_end_time)) + cast(active_end_time as char(6)),5,2)
--  'End Time-Executing Job',

--  b.date_created 'Job Created',
--  a.date_created 'Schedule Created' 
  ,CASE 
        WHEN [sJOBH].[run_date] IS NULL OR [sJOBH].[run_time] IS NULL THEN NULL
        ELSE CAST(
                CAST([sJOBH].[run_date] AS CHAR(8))
                + ' ' 
                + STUFF(
                    STUFF(RIGHT('000000' + CAST([sJOBH].[run_time] AS VARCHAR(6)),  6)
                        , 3, 0, ':')
                    , 6, 0, ':')
                AS DATETIME)
   END AS [LastRunDateTime]
  ,CASE [sJOBSCH].[NextRunDate]
        WHEN 0 THEN NULL
        ELSE CAST(
                CAST([sJOBSCH].[NextRunDate] AS CHAR(8))
                + ' ' 
                + STUFF(
                    STUFF(RIGHT('000000' + CAST([sJOBSCH].[NextRunTime] AS VARCHAR(6)),  6)
                        , 3, 0, ':')
                    , 6, 0, ':')
                AS DATETIME)
   END AS [NextRunDateTime]
  ,CASE [sJOBH].[run_status]
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'Running' -- In Progress
   END AS [LastRunStatus]
  ,[sJOBH].[message] AS [LastRunStatusMessage]
  , STUFF(
            STUFF(RIGHT('000000' + CAST([sJOBH].[run_duration] AS VARCHAR(6)),  6)
                , 3, 0, ':')
            , 6, 0, ':') 
        AS [LastRunDuration (HH:MM:SS)]
from msdb..sysjobschedules d
	 RIGHT OUTER JOIN msdb..sysjobs b ON d.job_id  = b.job_id 
	 left outer join msdb..sysschedules a on a.schedule_id = d.schedule_id
	 LEFT OUTER JOIN #temp c on a.name = c.jname collate SQL_Latin1_General_CP437_BIN
							and d.job_id = c.jid collate SQL_Latin1_General_CP437_BIN
    LEFT JOIN (
                SELECT
                    [job_id]
					,schedule_id
                    , MIN([next_run_date]) AS [NextRunDate]
                    , MIN([next_run_time]) AS [NextRunTime]
                FROM [msdb].[dbo].[sysjobschedules]
                GROUP BY [job_id], schedule_id
            ) AS [sJOBSCH]
        ON [b].[job_id] = [sJOBSCH].[job_id]
		and [sJOBSCH].schedule_id = a.schedule_id
	LEFT JOIN (
                SELECT 
                    [job_id]
                    , [run_date]
                    , [run_time]
                    , [run_status]
                    , [run_duration]
                    , [message]
                    , ROW_NUMBER() OVER (
                                            PARTITION BY [job_id] 
                                            ORDER BY [run_date] DESC, [run_time] DESC
                      ) AS RowNumber
                FROM [msdb].[dbo].[sysjobhistory]
                WHERE [step_id] = 0
            ) AS [sJOBH]
        ON b.[job_id] = [sJOBH].[job_id]
        AND [sJOBH].[RowNumber] = 1
Order by 1,2

Drop Table #temp


GO
