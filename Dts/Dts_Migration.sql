
----You may want to transfer specific package
SELECT * FROM dbo.sysdtspackages
WHERE [name] IN ('PAckagename_1')


-----You may only want to transfer the latest or current version
SELECT T1.* FROM dbo.sysdtspackages AS T1
INNER JOIN (SELECT [name], [id], MAX([createdate]) AS [createdate] 
  FROM dbo.sysdtspackages GROUP BY [name], [id]) AS T2
ON T1.[id] = T2.[id] AND T1.[createdate] = T2.[createdate]


----You may wish to transfer the most recent n versions:
SELECT T1.* FROM dbo.sysdtspackages AS T1
INNER JOIN (SELECT T2.[name] , T2.[id], T2.[createdate] 
  FROM dbo.sysdtspackages T2
  GROUP BY T2.[name], T2.[id], T2.[createdate]
  HAVING T2.[createdate] IN (SELECT TOP n T3.[createdate] 
    FROM dbo.sysdtspackages T3 
    WHERE T2.[id] = T3.[id] 
    ORDER BY T3.[createdate] DESC) ) AS T2
ON T1.[id] = T2.[id] AND T1.[createdate] = T2.[createdate]