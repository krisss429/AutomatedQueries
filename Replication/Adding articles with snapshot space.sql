--Connect to server with local publication i.e. cambosqasql21\sql01,  cambosuatsql21\sql01, etc
USE BrandServiceData

---Run this to check immediate_sync and allow_anonymous status
sp_helppublication 

---Run on your publisher database to disable immediate_sync and allow_anonymous (change publication names below)
EXEC sp_changepublication 
@publication = 'BrandServiceData_QA', 
@property = 'allow_anonymous' , 
@value = 'false' 
GO 
EXEC sp_changepublication 
@publication = 'BrandServiceData_QA', 
@property = 'immediate_sync' , 
@value = 'false' 
go
---Run this to check immediate_sync and allow_anonymous status
sp_helppublication

/*
expand Replication
expand Local Publications
right click on publication
select Properties
select Articles
add new object(s) to publish and click ok
*/

---Run this to check subscription status of newly added article
/*
0= InActive
1= Subscribed
2= Active
*/
sp_helpsubscription

---Take Snapshot
/*
right click on publication
click on View Snapshot Agent Status
click Start
*/

-- Cross check on another server

 ---Run on your publisher database to enable immediate_sync and allow_anonymous (reverse order from above)
EXEC sp_changepublication 
@publication = 'BrandServiceData_QA', 
@property = 'immediate_sync' , 
@value = 'true' 
go
EXEC sp_changepublication 
@publication = 'BrandServiceData_QA', 
@property = 'allow_anonymous' , 
@value = 'true' 
GO 

