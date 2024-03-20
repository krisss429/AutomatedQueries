SELECT object_name(i.object_id) AS 'TableName'
    ,i.NAME AS 'IndexName'
    ,i.type_desc
    ,Max(p.partition_number) AS 'partitions'
    ,Sum(p.rows) AS 'RowCount'
    ,Sum(au.data_pages) AS 'PageCount'
    ,Sum(p.rows) / Sum(au.data_pages) AS 'RowsPerPage'
    ,CAST(ROUND(((SUM(au.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB
    ,CAST(ROUND(((SUM(au.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB
    ,CAST(ROUND(((SUM(au.total_pages) - SUM(au.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM sys.indexes AS i
JOIN sys.partitions AS p ON i.object_id = p.object_id
                        AND i.index_id = p.index_id
JOIN sys.allocation_units AS au ON p.hobt_id = au.container_id
WHERE object_name(i.object_id) NOT LIKE 'sys%'
    AND au.type_desc = 'IN_ROW_DATA'
GROUP BY object_name(i.object_id)
    ,i.NAME
    ,i.type_desc
HAVING Sum(au.data_pages) > 100
ORDER BY rowsPerPage;