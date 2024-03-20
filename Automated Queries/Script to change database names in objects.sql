SET NOCOUNT ON

IF OBJECT_ID('tempdb.dbo.#sp_names', 'U') IS NOT NULL
  DROP TABLE #sp_names; 
  
CREATE TABLE #sp_names 
(
    ID INT PRIMARY KEY IDENTITY,
    Name NVARCHAR(128),
       ObjType VARCHAR(150), 
       ObjText NVARCHAR(MAX),
       ObjTextUpd NVARCHAR(MAX)
);


DECLARE @sp_count INT,
        @count INT = 0,
        @sp_name NVARCHAR(1024),
        @text NVARCHAR(MAX),
        @FindStr nvarchar(max),
        @ParmDefinition nvarchar(max),
        @SQLString NVARCHAR(max);


SET @FindStr = '''%ISO_QA%''
OR  sm.definition LIKE ''%DM_Billing_Prod%''
OR  sm.definition LIKE ''%HomesiteWeb%''
OR  sm.definition LIKE ''%ISO_Print%''
OR  sm.definition LIKE ''%ISO_RATING%''
OR  sm.definition LIKE ''%DBA_Utility%''
OR  sm.definition LIKE ''%PolicyServices%''
OR  sm.definition LIKE ''%ISO_PRINT_SSIS%''
OR  sm.definition LIKE ''%Agency_Report%''
OR  sm.definition LIKE ''%AccountCodes%''
OR  sm.definition LIKE ''%Auto_DocMgt%''
OR  sm.definition LIKE ''%QWHS_PROD%''
OR  sm.definition LIKE ''%ASPState%''
OR  sm.definition LIKE ''%DocMgt%''
OR  sm.definition LIKE ''%BrandServiceData%''
OR  sm.definition LIKE ''%EBS_DomainServices%''
OR  sm.definition LIKE ''%HomesiteWeb_Logging%''
OR  sm.definition LIKE ''%HS_AGENCY_MANAGEMENT%''
OR  sm.definition LIKE ''%HS_CMS%''
OR  sm.definition LIKE ''%HS_SERVICE_INFO%''
OR  sm.definition LIKE ''%HomesiteWeb_ESS%''
OR  sm.definition LIKE ''%ISO_IVR_LOG%''
OR  sm.definition LIKE ''%ISO_TRANS%''
OR  sm.definition LIKE ''%ISO_INQUIRY%''
OR  sm.definition LIKE ''%ISO_INQUIRY_2%''
OR  sm.definition LIKE ''%ISO_RATING_ESS%''
'

--SELECT @FindStr





SET  @SQLString ='
INSERT INTO #sp_names
SELECT  DISTINCT OBJECT_NAME(sm.object_id), so.type_desc, sm.definition, sm.definition
FROM sys.sql_modules AS sm
JOIN sys.objects AS so 
ON sm.object_id = so.object_id
WHERE sm.definition like '+@FindStr
--INSERT  #sp_names
--SELECT @SQLString

SET @ParmDefinition = N'@FindStr varchar(max)'
EXECUTE sp_executesql
      @SQLString,
      @ParmDefinition,
      @FindStr = @FindStr;




DECLARE @oldname1 NVARCHAR(50),
        @oldname2 NVARCHAR(50),
        @oldname3 NVARCHAR(50),
        @newname1 NVARCHAR(50),
        @newname2 NVARCHAR(50),
        @newname3 NVARCHAR(50)

SET @oldname1 = 'iso_qa'
SET @newname1 = 'ISO_Prod'
SET @oldname2 = 'iso_rating'
SET @newname2 = 'ISO_Rating_Prod'
SET @oldname3 = 'homesiteweb'
SET @newname3 = 'HomesiteWeb_Prod'

--SELECT @SQLString


UPDATE #sp_names
SET ObjTextUpd = REPLACE(ObjText, @oldname1, @newname1)
--WHERE ID = 80

UPDATE #sp_names
SET ObjTextUpd = REPLACE(ObjTextUpd, @oldname2, @newname2)


UPDATE #sp_names
SET ObjTextUpd = REPLACE(ObjTextUpd, @oldname3, @newname3)


UPDATE #sp_names
SET ObjTextUpd = REPLACE(ObjTextUpd, 'CREATE PROC', 'ALTER PROCEDURE')


UPDATE #sp_names
SET ObjTextUpd = REPLACE(ObjTextUpd, 'CREATE TRIGGER', 'ALTER TRIGGER')

UPDATE #sp_names
SET ObjTextUpd = REPLACE(ObjTextUpd, 'CREATE VIEW', 'ALTER VIEW')


UPDATE #sp_names
SET ObjTextUpd = REPLACE(ObjTextUpd, 'CREATE PROCEDURE', 'ALTER PROCEDURE')
--WHERE ID = 80


SELECT ObjTextUpd
FROM #sp_names


