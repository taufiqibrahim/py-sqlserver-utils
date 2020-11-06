USE [master]
GO

IF OBJECT_ID('ParseStoredProcedureTagging', 'P') IS NOT NULL
DROP PROC ParseStoredProcedureTagging
GO

CREATE PROCEDURE [dbo].[ParseStoredProcedureTagging]
AS
BEGIN

IF OBJECT_ID('tempdb..#SqlModulesFullString') IS NOT NULL
DROP TABLE #SqlModulesFullString
CREATE TABLE #SqlModulesFullString (DatabaseName Varchar(300), ObjectId Int, ObjectName Varchar(500), [Definition] Nvarchar(MAX));
DECLARE @DatabaseName Varchar(300), @Sql nVarchar(MAX) DECLARE CursorDatabase
CURSOR
FOR
SELECT name
FROM sys.databases
WHERE name NOT IN ('tempdb', 'master')
  AND state_desc='ONLINE' OPEN CursorDatabase FETCH NEXT
  FROM CursorDatabase INTO @DatabaseName WHILE @@FETCH_STATUS = 0 BEGIN
SELECT @Sql = 'USE [' + @DatabaseName + ']
                    
                    
                            INSERT INTO #SqlModulesFullString
                            select '''
+ @DatabaseName +
''' AS DatabaseName, a.object_id,OBJECT_NAME(object_id),a.definition from sys.sql_modules a'
EXECUTE
sp_executesql @Sql
FETCH
NEXT
FROM CursorDatabase INTO @DatabaseName END CLOSE CursorDatabase DEALLOCATE CursorDatabase ;

WITH
tmp(DatabaseName, ObjectId, ObjectName, DataItem, String) AS (
   SELECT DatabaseName,
          ObjectId,
          ObjectName,
          LEFT(left(definition, 700000), CHARINDEX('___TAGGINGSTART___', left(definition, 700000) + '___TAGGINGSTART___') - 1),
          STUFF(left(definition, 700000), 1, CHARINDEX('___TAGGINGSTART___', left(definition, 700000) + '___TAGGINGSTART___'), '')
   FROM #SqlModulesFullString
   WHERE definition LIKE '%TAGGINGSTART%'
   UNION ALL SELECT DatabaseName,
                    ObjectId,
                    ObjectName,
                    LEFT(String, CHARINDEX('___TAGGINGSTART___', String + '___TAGGINGSTART___') - 1),
                    STUFF(String, 1, CHARINDEX('___TAGGINGSTART___', String + '___TAGGINGSTART___'), '')
   FROM tmp
   WHERE String > ''),
tmp2(DatabaseName, ObjectId, ObjectName, DataItem, String) AS (
   SELECT DatabaseName,
          ObjectId,
          ObjectName,
          LEFT(substring(definition, 700000, 9000000), CHARINDEX('___TAGGINGSTART___', substring(definition, 700000, 9000000) + '___TAGGINGSTART___') - 1),
          STUFF(substring(definition, 700000, 9000000), 1, CHARINDEX('___TAGGINGSTART___', substring(definition, 700000, 9000000) + '___TAGGINGSTART___'), '')
   FROM #SqlModulesFullString
   WHERE definition LIKE '%TAGGINGSTART%'
   UNION ALL SELECT DatabaseName,
                    ObjectId,
                    ObjectName,
                    LEFT(String, CHARINDEX('___TAGGINGSTART___', String + '___TAGGINGSTART___') - 1),
                    STUFF(String, 1, CHARINDEX('___TAGGINGSTART___', String + '___TAGGINGSTART___'), '')
   FROM tmp2
   WHERE String > ''),
     get_tagging AS
  (SELECT DatabaseName,
          ObjectId,
          ObjectName,
          String_Tagging = CASE
                               WHEN DataItem like '%___TAGGINGEND___%' THEN LEFT(DataItem, CHARINDEX('___TAGGINGEND___', DataItem)+15)
                               ELSE NULL
                           END
   FROM tmp
   UNION SELECT DatabaseName,
                ObjectId,
                ObjectName,
                String_Tagging = CASE
                                     WHEN DataItem like '%___TAGGINGEND___%' THEN LEFT(DataItem, CHARINDEX('___TAGGINGEND___', DataItem)+15)
                                     ELSE NULL
                                 END
   FROM tmp2)
SELECT DatabaseName,
ObjectId,
ObjectName,
LTRIM(RTRIM(REPLACE(REPLACE(String_Tagging, '__TAGGINGSTART___',''), '___TAGGINGEND___',''))) AS String_Tagging
FROM get_tagging
WHERE String_Tagging IS NOT NULL
ORDER BY ObjectId;
END
