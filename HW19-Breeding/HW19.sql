USE RentalFirm
GO

-- First step: Create separating filegroup
ALTER DATABASE [RentalFirm]
ADD FILEGROUP [InsuranceFinishedDate]
GO

-- Second step: Add file in DB
ALTER DATABASE [RentalFirm]
ADD FILE   
(  
    NAME = InsuranceFinishedDateStorage,  
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\InsuranceFinishedDateStorage.ndf',  
    SIZE = 5GB,  
    MAXSIZE = 10GB,  
    FILEGROWTH = 1GB  
)
TO FILEGROUP InsuranceFinishedDate;  
GO 

-- Third step: Create function of partitioning by FinishedDate
CREATE PARTITION FUNCTION [InsuranceFinishedDatePartition] (DATETIME2) 
AS RANGE RIGHT FOR VALUES 
(
	'2023-01-01',
	'2024-01-01',
	'2025-01-01',
	'2026-01-01',
	'2027-01-01',
	'2028-01-01',
	'2029-01-01',
	'2030-01-01',
	'2031-01-01',
	'2032-01-01',
	'2033-01-01',
	'2034-01-01',
	'2035-01-01',
	'2036-01-01',
	'2037-01-01',
	'2038-01-01',
	'2039-01-01',
	'2040-01-01'
)
GO

-- Forth step: Partitioning, using function [InsuranceFinishedDatePartition]
CREATE PARTITION SCHEME [schmFinishedDatePartition] AS PARTITION [InsuranceFinishedDatePartition]
ALL TO (InsuranceFinishedDate)
GO

-- Fifth step: Create one more table for using partitioning
SELECT * INTO [Insurance].[InsurancesPartitioned]
FROM [Insurance].[Insurances]

-- Auto generated script with index
CREATE CLUSTERED INDEX [ClusteredIndex_on_schmFinishedDatePartition_638227696858317479] ON [Insurance].[InsurancesPartitioned]
(
	[FinishedDate]
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [schmFinishedDatePartition]([FinishedDate])

-- Check existed partitioning
SELECT 
	$PARTITION.InsuranceFinishedDatePartition(FinishedDate) as Partition,
	COUNT(*) AS [Count],
	MIN(FinishedDate) AS StartDate,
	MAX(FinishedDate) AS FinishedDate
FROM Insurance.InsurancesPartitioned
GROUP BY $PARTITION.InsuranceFinishedDatePartition(FinishedDate)
ORDER BY PARTITION