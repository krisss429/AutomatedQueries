SELECT DB_NAME() [database name],
       [schema name] = SCHEMA_NAME([schema_id]),
       o.name,
       ps.last_execution_time
FROM sys.dm_exec_procedure_stats ps
    INNER JOIN sys.objects o
        ON ps.object_id = o.object_id
WHERE o.type = 'P'
      --and o.schema_id = schema_name(schema_id)
      AND o.name = 'Sproc_name'
ORDER BY ps.last_execution_time