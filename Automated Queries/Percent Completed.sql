select percent_complete
from sys .dm_exec_requests
where session_id = 59
