 CREATE PROCEDURE SP_ReIndex (@DbId SMALLINT = 7)
    AS
        BEGIN
			SET NOCOUNT ON; 

			--storage for objects (indexes, tables) for reorganization
			DECLARE @IndexTmpTable TABLE (
				Id INT IDENTITY(1,1) PRIMARY KEY,
				SchemaName SYSNAME, 
				TableName SYSNAME, 
				IndexName SYSNAME, 
				AvgFrag FLOAT);
			--some variables
			DECLARE 
					@RowNumber INT = 1,
					@CntRows INT,
					@CntReorganize INT = 0,
					@CntRebuild INT = 0;

			DECLARE 
					@SchemaName SYSNAME,
					@TableName SYSNAME,
					@IndexName SYSNAME,
					@AvgFrag FLOAT;
			DECLARE 
					@Command VARCHAR(8000);

			--Unique identifier DB
			SELECT @DbId = COALESCE(@DbId, DB_ID()); 

			--Detecting the level of fragmentation all of indexes by using stored procedure =>
			--sys.dm_db_index_physical_stats
			INSERT INTO @IndexTmpTable
					SELECT Sch.name AS SchemaName,
							Obj.name AS TableName,
							Inx.name AS IndexName, 
							AvgFrag.avg_fragmentation_in_percent AS Fragmentation 
					FROM sys.dm_db_index_physical_stats (@DbId, NULL, NULL, NULL, NULL) AS AvgFrag
					LEFT JOIN sys.indexes AS Inx ON AvgFrag.object_id = Inx.object_id AND AvgFrag.index_id = Inx.index_id
					LEFT JOIN sys.objects AS Obj ON AvgFrag.object_id = Obj.object_id 
					LEFT JOIN sys.schemas AS Sch ON Obj.schema_id = Sch.schema_id
					WHERE AvgFrag.index_id > 0 
						AND AvgFrag.avg_fragmentation_in_percent > 5 --5 - MIN percent of the level of fragmentation

			-- count of row for handling
			SELECT @CntRows = COUNT(*)
			FROM @IndexTmpTable

			--Cycle of handling each index
			WHILE @RowNumber <= @CntRows
					BEGIN
					  --Getting name of object, as well the level of fragmentation of current index
					  SELECT @SchemaName = SchemaName, 
							 @TableName = TableName, 
							 @IndexName = IndexName, 
							 @AvgFrag = AvgFrag
					  FROM @IndexTmpTable
					  WHERE Id = @RowNumber
                        
					  --If level of fragmentation till 30%, we'll reorganize index
					  IF @AvgFrag < 30
						 BEGIN
						   -- format command and execute that
						   SELECT @Command = 'ALTER INDEX [' + @IndexName + '] ON ' + '[' + @SchemaName + ']' 
											  + '.[' + @TableName + '] REORGANIZE';
						   EXEC (@Command);
						   SET @CntReorganize = @CntReorganize + 1; --count of indexes, which was reorganized
						  END 
                        
					  --If level of fragmentation more then 30%, we'll rebuild of index
					  IF @AvgFrag >= 30
						 BEGIN
							--format command and execute that
							SELECT @Command = 'ALTER INDEX [' + @IndexName + '] ON ' + '[' + @SchemaName + ']' 
												+ '.[' + @TableName + '] REBUILD';
							EXEC (@Command);
							SET @CntRebuild = @CntRebuild + 1; --count of indexes, which was rebuild
						 END
                        
					   --Выводим служебную информацию о текущей операции
					   PRINT 'command was executed ' + @Command;
                        
					   --iteration for the next index
					   SET @RowNumber = @RowNumber + 1
					END
                
			--Итог
			PRINT 'Overall count of indexes were handled: ' + CAST(@CntRows AS VARCHAR(10)) 
					+ ', Reorganized: ' + CAST(@CntReorganize AS VARCHAR(10)) 
					+ ', Rebuilded: ' + CAST(@CntRebuild AS VARCHAR(10))
        END

GO

--drop PROCEDURE SP_ReIndex

CREATE PROCEDURE GetLastExecutedStoredProcedures
    AS
        BEGIN
			SET NOCOUNT ON; 

			SELECT o.name, 
				   ps.last_execution_time 
			FROM   sys.dm_exec_procedure_stats ps 
			INNER JOIN 
				   sys.objects o 
				   ON ps.object_id = o.object_id 
			WHERE  DB_NAME(ps.database_id) = 'RentalFirm' 
			ORDER  BY 
				   ps.last_execution_time DESC

	END

GO