select to_char(sysdate, 'YYYY.MM.DD HH24:MI') from dual
/
SELECT substr (b.username,0,15) "USERNAME", 
	a.sid,
	DECODE( a.Type, 'TM', 'TM Table', 'TX', 'TX Trans', a.Type) "Lock Type",
	substr (DECODE( LMODE,  0, 'None', 1, 'NULL' , 2, '(SS)  Row share', 3, '(SX)  Row exclusive', 4, '(S)   Share' ,
                                                5, '(SSX) Share row exclusive', 6, '(X)   Exclusive'),0,22)  "Lock Mode",
	substr (DECODE( REQUEST ,  0, ' ', 1, 'NULL' , 2, '(SS)  Row share', 3, '(SX)  Row exclusive', 4, '(S)   Share' ,
                                                5, '(SSX) Share row exclusive', 6, '(X)   Exclusive'),0,22)  "Req. Mode",
	DECODE( block, 0, 'no', 'YES' ) BLOCKER,
	DECODE( request, 0, 'no', 'YES' ) WAITER,
	substr (DECODE( a.Type, 'TM', c.object_name, 'TX', 'Rollback'),0,20) "Object_name"
FROM v$lock a, v$session  b, dba_objects c
WHERE a.sid = b.sid and a.id1 = c.object_id (+)
and (request > 0 OR block > 0)
ORDER BY block DESC
/
