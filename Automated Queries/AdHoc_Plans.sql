SET NOCOUNT ON
SELECT objtype AS [Cache Store Type],
        COUNT_BIG(*) AS [Total Num Of Plans],
        SUM(CAST (size_in_bytes as decimal( 14,2 ))) / 1048576 AS [Total Size In MB],
        AVG(usecounts ) AS [All Plans - Ave Use Count],
        SUM(CAST ((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END ) as decimal (14, 2)))/ 1048576 AS [Size in MB of plans with a Use count = 1],
        SUM(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Number of of plans with a Use count = 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY [Size in MB of plans with a Use count = 1] DESC


DECLARE @AdHocSizeInMB decimal (14, 2), @TotalSizeInMB decimal (14 ,2)
SELECT @AdHocSizeInMB = SUM( CAST((CASE WHEN usecounts = 1 AND LOWER(objtype ) = 'adhoc' THEN size_in_bytes ELSE 0 END) as decimal(14 ,2))) / 1048576 ,
       @TotalSizeInMB = SUM (CAST (size_in_bytes as decimal (14, 2))) / 1048576
FROM sys.dm_exec_cached_plans
SELECT @AdHocSizeInMB as [Current memory occupied by adhoc plans only used once (MB)],
         @TotalSizeInMB as [Total cache plan size (MB)],
         CAST((@AdHocSizeInMB / @TotalSizeInMB) * 100 as decimal (14, 2)) as [% of total cache plan occupied by adhoc plans only used once]



select DB_NAME(dbid) DBName, COUNT(*) CountOfAdhocPlans
FROM sys .dm_exec_cached_plans cp CROSS APPLY sys.dm_exec_sql_text (cp. plan_handle) AS st
where objtype = 'Adhoc' AND cp.usecounts=1
AND cp.cacheobjtype<>'Compiled Plan Stub'
GROUP BY DB_NAME(dbid)
ORDER BY 2 desc
