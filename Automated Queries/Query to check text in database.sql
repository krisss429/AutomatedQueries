select so.name, sc.text
from sys.objects so
join syscomments sc
on so.object_id = sc.id
where sc.text like '%DM_BILLING_PROD%'
