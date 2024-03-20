EXECUTE master.sys.sp_MSforeachdb 'USE [?]; 
select db_name();
SELECT so.name, sc.text
from sys.objects so
join syscomments sc
on so.object_id = sc.id
where sc.text like ''%HOmesiteWeb_prod%''
or sc.text like ''%\[HOmesiteWeb_prod\]%'' escape ''\'''


