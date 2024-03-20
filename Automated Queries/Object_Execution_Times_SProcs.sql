SELECT DB_NAME(st.dbid) DBName,
       OBJECT_SCHEMA_NAME(st.objectid, dbid) SchemaName,
       OBJECT_NAME(st.objectid, dbid) StoredProcedure,
       MAX(cp.usecounts) Execution_count
FROM sys.dm_exec_cached_plans cp
    CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE DB_NAME(st.dbid) IS NOT NULL
      AND cp.objtype = 'proc'
      AND DB_NAME(st.dbid) IN ('ISO_PROD','ISO_Rating_Prod')
GROUP BY cp.plan_handle,
         DB_NAME(st.dbid),
         OBJECT_SCHEMA_NAME(objectid, st.dbid),
         OBJECT_NAME(objectid, st.dbid)
ORDER BY MAX(cp.usecounts)

SELECT DB_NAME(database_id) DatabaseName,
OBJECT_NAME(object_id) ProcedureName,
cached_time, last_execution_time, execution_count,
total_elapsed_time/execution_count AS avg_elapsed_time,
type_desc
FROM sys.dm_exec_procedure_stats
WHERE DB_NAME(database_id)  IN ('ISO_PROD','ISO_Rating_Prod')
ORDER BY avg_elapsed_time;