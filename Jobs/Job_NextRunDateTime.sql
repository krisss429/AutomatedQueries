USE msdb;
GO
SELECT sj.name,
       CAST(CAST(sjs.next_run_date AS CHAR(8)) + ' '
            + STUFF(STUFF(RIGHT('000000' + CAST(sjs.next_run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS DATETIME) AS [NextRunDateTime]
FROM dbo.sysjobs sj
    JOIN dbo.sysjobschedules sjs
        ON sjs.job_id = sj.job_id
WHERE sj.name IN ( 'DBMaint - USERDB - Daily', 'DBMaint - USERDB - Weekly' );

