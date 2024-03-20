--Index stats query:

SELECT DB_NAME(dm.database_id) AS DATABASENAME ,
       SCHEMA_NAME(so.schema_id)+'.'+OBJECT_NAME(so.object_id) AS TABLENAME ,
       si.name AS INDEXNAME,
       dm.user_seeks ,
       dm.user_scans ,
       dm.user_lookups ,
       dm.user_updates,
       --CEILING(ISNULL((dm.user_seeks+dm.user_scans+dm.user_lookups),0)*1.0 / ( ISNULL((dm.user_seeks+dm.user_scans+dm.user_lookups),0)+1*1.0 + ISNULL(dm.user_updates,0)+1*1.0 ))*100 AS ReadRatio,
         CAST((ISNULL((dm.user_seeks+dm.user_scans+dm.user_lookups),0)*1.0 / ( ISNULL((dm.user_seeks+dm.user_scans+dm.user_lookups),0)*1.0 + ISNULL(dm.user_updates,0)*1.0 ))*100 AS DECIMAL(6,3)) AS ReadRatio,  
          sp.rows AS ROW_COUNT,
          so.type_desc, 
          si.type_desc
FROM                 sys.objects so
INNER JOIN           sys.indexes si ON si.object_id = so.object_id
LEFT OUTER JOIN sys.dm_db_index_usage_stats dm ON dm.index_id= si.index_id
                                                                             AND dm.object_id = si.object_id
                                                                             AND dm.database_id = DB_ID(DB_NAME())
LEFT OUTER JOIN sys.partitions sp on sp.object_id = si.object_id 
                                                        AND sp.index_id = si.index_id
WHERE so.type IN ('U','V')
--  AND sp.rows > 0
--  AND dm.user_updates > 0
AND so.name IN ('DIARY',
'VENDORCLAIMITEM',
'RESERVEBREAKDOWN'
,'TXN_ENC'
,'FONREF'
,'TASK'
,'PAYMNT_ENC')
ORDER BY 2, 3
