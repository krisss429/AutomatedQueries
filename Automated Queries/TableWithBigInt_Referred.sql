EXECUTE master.sys.sp_MSforeachdb 'USE [?]; 
SELECT st.name as Table_Name,
       sc.name as Column_Name,
       t.name as Data_Type
INTO #temp1
FROM sys.tables st
    JOIN sys.columns sc
        ON sc.object_id = st.object_id
    INNER JOIN sys.types t
        ON sc.user_type_id = t.user_type_id
WHERE t.name = ''bigint''
      AND st.type = ''U''


SELECT DB_NAME(),referenced_entity_name AS Table_Name,
       t1.Column_Name AS BigInt_Column,
       o.name AS Referencing_Object_name,
       o.type_desc AS Referencing_Object_Type
FROM sys.sql_expression_dependencies sed
    INNER JOIN sys.objects o
        ON sed.referencing_id = o.[object_id]
    LEFT OUTER JOIN sys.objects o1
        ON sed.referenced_id = o1.[object_id]
    JOIN #temp1 t1
        ON sed.referenced_entity_name = t1.Table_Name
ORDER BY Table_Name'