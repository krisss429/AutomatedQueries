-- Script to find the JobOutPut Location.
select j.name,js.output_file_name,
  js.step_name,js.database_name "Executing On which DB?",
  last_run_outcome = case when js.last_run_outcome = 0 then 'Failed'
        when js.last_run_outcome = 1 then 'Succeeded'
        when js.last_run_outcome = 2 then 'Retry'
        when js.last_run_outcome = 3 then 'Canceled'
        else 'Unknown'
       end,
  last_run_datetime = msdb.dbo.agent_datetime(
       case when js.last_run_date = 0 then NULL else js.last_run_date end,
       case when js.last_run_time = 0 then NULL else js.last_run_time end)
from msdb.dbo.sysjobs j
  inner join msdb.dbo.sysjobsteps js
   on j.job_id = js.job_id
   WHERE js.output_file_name  '[NULL]' 
  order by js.output_file_name