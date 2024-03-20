SELECT  plc.page_id,
        COUNT(*) AS RowsOnPage,
        MIN(ls.ID) AS MinRowID,
        MAX(ls.ID) AS MaxRowID
FROM    dbo.FragChar ls  --table name
CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) plc
GROUP BY plc.page_id
ORDER BY MinRowID;