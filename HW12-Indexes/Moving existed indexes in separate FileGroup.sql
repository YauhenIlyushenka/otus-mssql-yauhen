USE RentalFirm;  
GO  
-- Creates the IndexesRentalFirmFileGroup filegroup on the RentalFirm database  
ALTER DATABASE RentalFirm  
ADD FILEGROUP IndexesRentalFirmFileGroup ;  
GO  
/* Adds the RentalFirmStorageIndexes file to the IndexesRentalFirmFileGroup filegroup. Please note that you will have to change the filename parameter in this statement to execute it without errors.  
*/  
ALTER DATABASE RentalFirm   
ADD FILE   
(  
    NAME = RentalFirmStorageIndexes,  
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\RentalFirmStorageIndexes.ndf',  
    SIZE = 5GB,  
    MAXSIZE = 10GB,  
    FILEGROWTH = 1GB  
)  
TO FILEGROUP IndexesRentalFirmFileGroup;  
GO   

PRINT N'Creating index [IX_Cars_ModelID] on [Car].[Cars]'
GO
CREATE NONCLUSTERED INDEX [IX_Cars_ModelID] ON [Car].[Cars] ([ModelID]) 
	WITH (DROP_EXISTING = ON) 
	ON IndexesRentalFirmFileGroup

PRINT N'Creating index [IX_Models_BrandID] on [Car].[Models]'
GO
CREATE NONCLUSTERED INDEX [IX_Models_BrandID] ON [Car].[Models] ([BrandID])
	WITH (DROP_EXISTING = ON) 
	ON IndexesRentalFirmFileGroup
GO

PRINT N'Creating index [[IX_Contracts_ClientID_CarID]] on [Deal].[Contracts]'
CREATE NONCLUSTERED INDEX [IX_Contracts_ClientID_CarID] ON [Deal].[Contracts] ([ClientID],[CarID])
	WITH (DROP_EXISTING = ON) 
	ON IndexesRentalFirmFileGroup
GO

PRINT N'Creating index [IX_Contracts_CreatedDate_INCLUDE_EmployeeID] on [Deal].[Contracts]'
GO
CREATE NONCLUSTERED INDEX [IX_Contracts_CreatedDate_INCLUDE_EmployeeID] ON [Deal].[Contracts] ([CreatedDate]) INCLUDE ([EmployeeID])
	WITH (DROP_EXISTING = ON) 
	ON IndexesRentalFirmFileGroup

PRINT N'Creating index [IX_Insurances_CarID_Price] on [Insurance].[Insurances]'
GO
CREATE NONCLUSTERED INDEX [IX_Insurances_CarID_Price] on [Insurance].[Insurances] ([CarID],[Price])
	WITH (DROP_EXISTING = ON) 
	ON IndexesRentalFirmFileGroup

PRINT N'Creating index [IX_Insurances_FinishedDate_INCLUDE_CompanyID] on [Insurance].[Insurances]'
GO
CREATE NONCLUSTERED INDEX [IX_Insurances_FinishedDate_INCLUDE_CompanyID] on [Insurance].[Insurances] ([FinishedDate]) INCLUDE ([CompanyID])
	WITH (DROP_EXISTING = ON) 
	ON IndexesRentalFirmFileGroup