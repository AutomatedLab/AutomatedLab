REPADMIN /viewlist * > DCs.txt

:: FOR /F "tokens=3" %%a IN (DCs.txt) DO ECHO dadasdads %%a
FOR /F "tokens=3" %%a IN (DCs.txt) DO CALL REPADMIN /SyncAll /AeP %%a

DEL DCs.txt

REPADMIN /ReplSum