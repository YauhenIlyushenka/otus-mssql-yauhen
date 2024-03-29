USE RentalFirm
GO

ALTER TABLE [Car].[Brands]
ADD CONSTRAINT UQ_Brands_Description UNIQUE (Description);
GO

PRINT N'Creating some non clustered indexes on FKs'

--PRINT N'Creating index [IX_Cars_ModelID] on [Car].[Cars]'
--GO
--CREATE NONCLUSTERED INDEX [IX_Cars_ModelID] ON [Car].[Cars] ([ModelID])
--drop INDEX [IX_Cars_ModelID] ON [Car].[Cars]

CREATE NONCLUSTERED INDEX [IX_Cars_ModelID_Include_Color_PurchaseDate] ON [Car].[Cars] ([ModelID]) INCLUDE ([ColorID],[PurchasedDate])
GO


PRINT N'Creating index [IX_Models_BrandID] on [Car].[Models]'
GO
CREATE NONCLUSTERED INDEX [IX_Models_BrandID] ON [Car].[Models] ([BrandID])
GO

PRINT N'Creating index [[IX_Contracts_ClientID_CarID]] on [Deal].[Contracts]'
CREATE NONCLUSTERED INDEX [IX_Contracts_ClientID_CarID] ON [Deal].[Contracts] ([ClientID],[CarID])
GO

PRINT N'Creating index [IX_Contracts_CreatedDate_INCLUDE_EmployeeID] on [Deal].[Contracts]'
GO
CREATE NONCLUSTERED INDEX [IX_Contracts_CreatedDate_INCLUDE_EmployeeID] ON [Deal].[Contracts] ([CreatedDate]) INCLUDE ([EmployeeID])

PRINT N'Creating index [IX_Insurances_CarID_Price] on [Insurance].[Insurances]'
GO
CREATE NONCLUSTERED INDEX [IX_Insurances_CarID_Price] on [Insurance].[Insurances] ([CarID],[Price])

PRINT N'Creating index [IX_Insurances_FinishedDate_INCLUDE_CompanyID] on [Insurance].[Insurances]'
GO
CREATE NONCLUSTERED INDEX [IX_Insurances_FinishedDate_INCLUDE_CompanyID] on [Insurance].[Insurances] ([FinishedDate]) INCLUDE ([CompanyID])

