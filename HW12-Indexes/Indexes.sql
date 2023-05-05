USE RentalFirm
GO

ALTER TABLE [Car].[Brands]
ADD CONSTRAINT UQ_Brands_Description UNIQUE (Description);
GO

PRINT N'Creating some non clustered indexes on FKs'

PRINT N'Creating index [IX_Cars_ModelID] on [Car].[Cars]'
GO
CREATE NONCLUSTERED INDEX [IX_Cars_ModelID] ON [Car].[Cars] ([ModelID])

PRINT N'Creating index [IX_Models_BrandID] on [Car].[Models]'
GO
CREATE NONCLUSTERED INDEX [IX_Models_BrandID] ON [Car].[Models] ([BrandID])
GO

PRINT N'Creating index [[IX_Contracts_ClientID_INCLUDE_CarID]] on [Deal].[Contracts]'
CREATE NONCLUSTERED INDEX [IX_Contracts_ClientID_CarID] ON [Deal].[Contracts] ([ClientID]) INCLUDE ([CarID])
GO

PRINT N'Creating index [IX_Contracts_CreatedDate_INCLUDE_EmployeeID] on [Deal].[Contracts]'
GO
CREATE NONCLUSTERED INDEX [IX_Contracts_CreatedDate_INCLUDE_EmployeeID] ON [Deal].[Contracts] ([CreatedDate]) INCLUDE ([EmployeeID])

PRINT N'Creating index [IX_Insurances_Price_INCLUDE_CarID] on [Insurance].[Insurances]'
GO
CREATE NONCLUSTERED INDEX [IX_Insurances_Price_INCLUDE_CarID] on [Insurance].[Insurances] ([Price]) INCLUDE ([CarID])

PRINT N'Creating index [IX_Insurances_FinishedDate_INCLUDE_CompanyID] on [Insurance].[Insurances]'
GO
CREATE NONCLUSTERED INDEX [IX_Insurances_FinishedDate_INCLUDE_CompanyID] on [Insurance].[Insurances] ([FinishedDate]) INCLUDE ([CompanyID])

