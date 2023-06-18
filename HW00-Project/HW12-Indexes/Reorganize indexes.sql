-- Show all indexes with average percents of fragmentation

SELECT a.index_id, name, avg_fragmentation_in_percent  
FROM sys.dm_db_index_physical_stats (DB_ID(N'RentalFirm'), NULL, NULL, NULL, NULL) AS a  
JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id;   
GO

-- Before 50 %
ALTER INDEX IX_Models_BrandID ON [Car].[Models]
REORGANIZE;
GO
-- After 0%

-- Before 14.28 %
ALTER INDEX UQ_Clients_Email ON [Users].[Clients]
REORGANIZE;
GO
-- After 0%

-- Before 3.5% 
ALTER INDEX PK_Contracts ON [Deal].[Contracts] 
REORGANIZE;
GO
-- After 0.03%

exec SP_ReIndex
exec GetLastExecutedStoredProcedures