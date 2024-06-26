use <yourdbname>
go
SELECT	filegroup_name(groupid),Name, Filename,
CONVERT(Decimal(15,2),ROUND(a.Size/128.000,2)) [Currently Allocated Space (MB)],
CONVERT(Decimal(15,2),ROUND(FILEPROPERTY(a.Name,'SpaceUsed')/128.000,2)) AS [Space Used (MB)],
CONVERT(Decimal(15,2),ROUND((a.Size-FILEPROPERTY(a.Name,'SpaceUsed'))/128.000,2)) AS [Available Space (MB)]
,a.maxsize
FROM dbo.sysfiles a (NOLOCK)   