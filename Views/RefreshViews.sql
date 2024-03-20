set nocount on

select '
set nocount on

use '+name +';

SELECT DISTINCT ''use ' +name + ';
print ''''Refresh ' + name + '.'' + ss.name + ''.'' + so.name + ''.......''''
EXEC sp_refreshview '''''' + ss.name + ''.'' + so.name + ''''''
go''
FROM sys.objects AS so
join sys.schemas ss on so.schema_id = ss.schema_id
WHERE so.type = ''V'' and so.is_ms_shipped = 0 and OBJECTPROPERTY(object_id, ''IsSchemaBound'')=0'

from sysdatabases
where dbid > 4
  and name not in ( 'SSISDB')

order by name
  
