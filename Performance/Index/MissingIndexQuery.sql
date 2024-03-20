--Missing index query:

--user impact of missing indexes #2
SELECT TOP 25
       --CONVERT(decimal(18,2), (user_seeks+ user_scans) * avg_total_user_cost * (avg_user_impact * 0.01)) AS [index_advantage], 
       --migs.last_user_seek, 
       CONVERT(decimal(18,2), user_seeks * avg_total_user_cost * (avg_user_impact * 0.01)) AS IndexBenefit,
       migs.avg_total_user_cost, 
       migs.avg_user_impact,
       mid.[statement] AS [Database.Schema.Table],
       mid.equality_columns, 
       mid.inequality_columns, 
       mid.included_columns,
       migs.unique_compiles, 
       migs.user_seeks, 
       --migs.user_scans,
       'CREATE INDEX idx_' + [statement] +
ISNULL(equality_columns , '_' ) +
ISNULL(inequality_columns , '_' ) + ' ON ' + [statement] +
' (' + ISNULL( equality_columns, ' ') +
ISNULL(inequality_columns , ' ' ) + ')' +
ISNULL(' INCLUDE (' + included_columns + ')' , '' )
AS create_missing_index_command
FROM       sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK) ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK) ON mig.index_handle = mid.index_handle
WHERE mid.[statement] LIKE N'%CMS%'
ORDER BY IndexBenefit DESC OPTION (RECOMPILE);
