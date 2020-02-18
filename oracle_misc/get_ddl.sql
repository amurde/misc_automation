SET LONG 9000
SET pagesize 1000
SET linesize 100
SET serverout ON
SET heading ON
SET ver OFF
SET scan ON
 
ACCEPT schema_name PROMPT "Enter schema name: "
ACCEPT object_name PROMPT "Enter object name: "
 
DECLARE ddl_statement VARCHAR(4000);
BEGIN
	DBMS_OUTPUT.ENABLE(1000000);
	FOR obj_type IN (SELECT REPLACE(o.object_type, ' ', '_') object_type_replaced 
	 	 FROM dba_objects o
			  WHERE o.owner = UPPER('&&schema_name')
				AND o.object_name = UPPER('&&object_name')
				AND o.object_type IN (
					'AQ QUEUE',
					'AQ QUEUE_TABLE',
					'AQ TRANSFORM',
					'ASSOCIATION',
					'AUDIT',
					'AUDIT OBJ',
					'CLUSTER',
					'COMMENT',
					'CONSTRAINT',
					'CONTEXT',
					'DATABASE EXPORT',
					'DB LINK',
					'DEFAULT ROLE',
					'DIMENSION',
					'DIRECTORY',
					'FGA POLICY',
					'FUNCTION',
					'INDEX STATISTICS',
					'INDEX',
					'INDEXTYPE',
					'JAVA SOURCE',
					'JOB',
					'LIBRARY',
					'MATERIALIZED VIEW',
					'MATERIALIZED VIEW LOG',
					'OBJECT GRANT',
					'OPERATOR',
					'OUTLINE',
					'PACKAGE',
					'PACKAGE SPEC',
					'PACKAGE BODY',
					'PROCEDURE',
					'PROFILE',
					'PROXY',
					'REF CONSTRAINT',
					'REFRESH GROUP',
					'RESOURCE COST',
					'RLS CONTEXT',
					'RLS GROUP',
					'RLS POLICY',
					'RMGR CONSUMER GROUP',
					'RMGR INTITIAL CONSUMER GROUP',
					'RMGR PLAN',
					'RMGR PLAN DIRECTIVE',
					'ROLE',
					'ROLE GRANT',
					'ROLLBACK SEGMENT',
					'SCHEMA EXPORT',
					'SEQUENCE',
					'SYNONYM',
					'SYSTEM GRANT',
					'TABLE',
					'TABLE DATA',
					'TABLE EXPORT',
					'TABLE STATISTICS',
					'TABLESPACE',
					'TABLESPACE QUOTA',
					'TRANSPORTABLE EXPORT',
					'TRIGGER',
					'TRUSTED DB LINK',
					'TYPE',
					'TYPE SPEC',
					'TYPE BODY',
					'USER',
					'VIEW',
					'XMLSCHEMA'))
	LOOP
		SELECT TO_CHAR(DBMS_METADATA.GET_DDL(
			obj_type.object_type_replaced,
			UPPER('&&object_name'),
			UPPER('&&schema_name')
			)) INTO ddl_statement FROM dual;
		DBMS_OUTPUT.PUT_LINE(ddl_statement);
	END LOOP;
END;
/