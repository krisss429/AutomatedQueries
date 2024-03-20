---Check the connections which are getting blocked
SELECT  *
FROM    sys.sysprocesses
WHERE   spid >= 50
        AND blocked <> 0;
	
---List down the transaction which is the lead blocker and the real culprit
SELECT  loginame ,
        cpu ,
        memusage ,
        physical_io ,
        *
FROM    master..sysprocesses a
WHERE   EXISTS ( SELECT b.*
                 FROM   master..sysprocesses b
                 WHERE  b.blocked > 0
                        AND b.blocked = a.spid )
        AND NOT EXISTS ( SELECT b.*
                         FROM   master..sysprocesses b
                         WHERE  b.blocked > 0
                                AND b.spid = a.spid )
ORDER BY spid;
