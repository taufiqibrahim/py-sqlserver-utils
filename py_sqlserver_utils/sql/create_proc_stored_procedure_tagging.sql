USE [master]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Usp_SyncObjectStoreProcedureWithTag]
AS
BEGIN
	IF OBJECT_ID('tempdb..#SqlModulesFullString') IS NOT NULL DROP TABLE #SqlModulesFullString
	CREATE TABLE #SqlModulesFullString 
		(
			DatabaseName Varchar(300),
			ObjectId Int, 
			SchemaName Varchar(20),
			ObjectName Varchar(500),
			[Definition] Nvarchar(MAX)
		);
	DECLARE @DatabaseName Varchar(300),@Sql nVarchar(MAX) ,@LastSync DateTime,@NewLastSync DateTime
	SELECT @LastSync=DATEADD(MINUTE,-15,LastSync),@NewLastSync=GETDATE() FROM TblLastSync
	DECLARE CursorDatabase CURSOR FOR 
		SELECT name FROM sys.databases WHERE database_id>4 AND name not in ('SSISDB')   AND state_desc='ONLINE' 
			OPEN CursorDatabase FETCH NEXT
				FROM CursorDatabase INTO @DatabaseName WHILE @@FETCH_STATUS = 0 BEGIN
					SELECT @Sql = 'USE [' + @DatabaseName + ']
									INSERT INTO #SqlModulesFullString
									select '''+ @DatabaseName +''' AS DatabaseName, a.object_id,SCHEMA_NAME(b.schema_id),OBJECT_NAME(a.object_id),a.definition 
									from sys.sql_modules a INNER JOIN sys.all_objects b ON a.object_id=b.object_id
									WHERE (create_date>='''+CONVERT(VARCHAR,@LastSync,121) 
										+''' OR modify_date>='''+CONVERT(VARCHAR,@LastSync,121)+''')'
					EXECUTE	sp_executesql @Sql
				FETCH NEXT
					FROM CursorDatabase INTO @DatabaseName 
				END 
			CLOSE CursorDatabase DEALLOCATE CursorDatabase ;
		UPDATE TblLastSync SET LastSync=@NewLastSync;
		WITH tmp(DatabaseName, ObjectId, SchemaName,ObjectName, DataItem, String) AS
		  (SELECT DatabaseName,
				  ObjectId,SchemaName,
				  ObjectName,
				  LEFT(LEFT(definition, 700000), CHARINDEX('#___TAGGINGSTART___#', LEFT(definition, 700000) + '#___TAGGINGSTART___#') ),
				  STUFF(LEFT(definition, 700000), 1, CHARINDEX('#___TAGGINGSTART___#', LEFT(definition, 700000) + '#___TAGGINGSTART___#'), '')
		   FROM #SqlModulesFullString
		   UNION ALL SELECT DatabaseName,
							ObjectId,SchemaName,
							ObjectName,
							LEFT(String, CHARINDEX('#___TAGGINGSTART___#', String + '#___TAGGINGSTART___#') ),
							STUFF(String, 1, CHARINDEX('#___TAGGINGSTART___#', String + '#___TAGGINGSTART___#'), '')
		   FROM tmp
		   WHERE String > '' ),
			 tmp2(DatabaseName, ObjectId,SchemaName, ObjectName, DataItem, String) AS
		  (SELECT DatabaseName,
				  ObjectId,SchemaName,
				  ObjectName,
				  LEFT(SUBSTRING(definition, 700000, 9000000), CHARINDEX('#___TAGGINGSTART___#', SUBSTRING(definition, 700000, 9000000) + '#___TAGGINGSTART___#') ),
				  STUFF(SUBSTRING(definition, 700000, 9000000), 1, CHARINDEX('#___TAGGINGSTART___#', SUBSTRING(definition, 700000, 9000000) + '#___TAGGINGSTART___#'), '')
		   FROM #SqlModulesFullString
		   UNION ALL SELECT DatabaseName,
							ObjectId,SchemaName,
							ObjectName,
							LEFT(String, CHARINDEX('#___TAGGINGSTART___#', String + '#___TAGGINGSTART___#') ),
							STUFF(String, 1, CHARINDEX('#___TAGGINGSTART___#', String + '#___TAGGINGSTART___#'), '')
		   FROM tmp2
		   WHERE String > '' ),
			 get_tagging AS
		  (SELECT DatabaseName,
				  ObjectId,SchemaName,
				  ObjectName,
				  String_Tagging = CASE
									   WHEN DataItem like '%#___TAGGINGEND___#%' THEN CONCAT('#',LEFT(DataItem, CHARINDEX('#___TAGGINGEND___#', DataItem)+15))
									   ELSE NULL
								   END
		   FROM tmp
		   UNION SELECT DatabaseName,
						ObjectId,SchemaName,
						ObjectName,
						String_Tagging = CASE
											 WHEN DataItem like '%#___TAGGINGEND___#%' THEN CONCAT('#',LEFT(DataItem, CHARINDEX('#___TAGGINGEND___#', DataItem)+15))
											 ELSE NULL
										 END
		   FROM tmp2)
	SELECT *,RANK () OVER ( PARTITION BY DatabaseName,ObjectId ORDER BY String_Tagging DESC	) String_TaggingRank 
		INTO #Tmp_get_tagging FROM get_tagging WHERE ObjectName IS NOT NULL;

	DELETE t FROM TblStoreProcedureWithTag t
		INNER JOIN #Tmp_get_tagging st ON (st.DatabaseName = t.DatabaseName AND st.ObjectId=t.ObjectId)
		LEFT JOIN #Tmp_get_tagging s ON (s.DatabaseName = t.DatabaseName AND s.ObjectId=t.ObjectId AND s.String_TaggingRank=t.String_TaggingRank)
		WHERE s.String_TaggingRank IS NULL

	MERGE TblStoreProcedureWithTag t 
		USING #Tmp_get_tagging s
	ON (s.DatabaseName = t.DatabaseName AND s.ObjectId=t.ObjectId AND s.String_TaggingRank=t.String_TaggingRank)
	WHEN MATCHED
		THEN UPDATE SET 
			t.String_Tagging = s.String_Tagging, DateModify=GETDATE()
	WHEN NOT MATCHED BY TARGET 
		THEN INSERT (DatabaseName,ObjectId,SchemaName,ObjectName,String_TaggingRank,String_Tagging,DateModify)
			 VALUES (s.DatabaseName,s.ObjectId,s.SchemaName,s.ObjectName,s.String_TaggingRank,s.String_Tagging,GETDATE());
END
