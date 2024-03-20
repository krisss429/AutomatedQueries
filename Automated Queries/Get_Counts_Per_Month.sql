----Demo 1: Getting Monthly Data
SELECT YEAR(SalesDate) [Year], MONTH(SalesDate) [Month], 
 DATENAME(MONTH,SalesDate) [Month Name], COUNT(1) [Sales Count]
FROM #Sales
GROUP BY YEAR(SalesDate), MONTH(SalesDate), 
 DATENAME(MONTH, SalesDate)
ORDER BY 1,2

--Demo 2: Getting Monthly Data using PIVOT
SELECT *
FROM (SELECT YEAR(SalesDate) [Year], 
       DATENAME(MONTH, SalesDate) [Month], 
       COUNT(1) [Sales Count]
      FROM #Sales
      GROUP BY YEAR(SalesDate), 
      DATENAME(MONTH, SalesDate)) AS MontlySalesData
PIVOT( SUM([Sales Count])   
    FOR Month IN ([January],[February],[March],[April],[May],
    [June],[July],[August],[September],[October],[November],
    [December])) AS MNamePivot