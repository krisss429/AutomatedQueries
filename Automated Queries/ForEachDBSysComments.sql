
EXECUTE master.sys.sp_MSforeachdb 'USE [?]; 
select db_name();
SELECT so.name, sc.text
FROM sys.syscomments sc
JOIN sys.objects so
ON sc.id=so.object_id
WHERE sc.text LIKE ''%ISO_QA%''
OR  sc.text LIKE ''%DM_Billing_Prod%''
OR  sc.text LIKE ''%HomesiteWeb%''
OR  sc.text LIKE ''%ISO_Print%''
OR  sc.text LIKE ''%ISO_RATING%''
OR  sc.text LIKE ''%DBA_Utility%''
OR  sc.text LIKE ''%PolicyServices%''
OR  sc.text LIKE ''%ISO_PRINT_SSIS%''
OR  sc.text LIKE ''%Agency_Report%''
OR  sc.text LIKE ''%AccountCodes%''
OR  sc.text LIKE ''%Auto_DocMgt%''
OR  sc.text LIKE ''%QWHS_PROD%''
OR  sc.text LIKE ''%ASPState%''
OR  sc.text LIKE ''%DocMgt%''
OR  sc.text LIKE ''%BrandServiceData%''
OR  sc.text LIKE ''%EBS_DomainServices%''
OR  sc.text LIKE ''%HomesiteWeb_Logging%''
OR  sc.text LIKE ''%HS_AGENCY_MANAGEMENT%''
OR  sc.text LIKE ''%HS_CMS%''
OR  sc.text LIKE ''%HS_SERVICE_INFO%''
OR  sc.text LIKE ''%HomesiteWeb_ESS%''
OR  sc.text LIKE ''%ISO_IVR_LOG%''
OR  sc.text LIKE ''%ISO_TRANS%''
OR  sc.text LIKE ''%ISO_INQUIRY%''
OR  sc.text LIKE ''%ISO_INQUIRY_2%''
OR  sc.text LIKE ''%ISO_RATING_ESS%''
'