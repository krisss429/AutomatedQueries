SELECT sj.name, sch.schedule_id, ss.schedule_id, sjs.*
FROM msdb..sysjobs sj 
JOIN msdb..sysjobsteps sjs ON sjs.job_id=sj.job_id
LEFT JOIN msdb..sysjobschedules sch ON sch.job_id=sj.job_id
LEFT JOIN msdb..sysschedules ss ON sch.schedule_id=ss.schedule_id
WHERE (    sj.name LIKE '%MASK_CHD%' 
              OR sjs.step_name LIKE '%MASK_CHD%' 
              OR sjs.command LIKE '%MASK_CHD%' 
              --OR sjs.command LIKE '%DTS%'
              --OR sjs.subsystem = 'CmdExec'
)
AND sj.enabled=1
ORDER BY sj.name
