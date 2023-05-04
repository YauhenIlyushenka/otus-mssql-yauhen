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

PRINT N'Creating index [IX_Contracts_CarID] on [Deal].[Contracts]'
GO
CREATE NONCLUSTERED INDEX [IX_Contracts_CarID] ON [Deal].[Contracts] ([CarID])
GO

PRINT N'Creating index [IX_Contracts_ClientID] on [Deal].[Contracts]'
GO
CREATE NONCLUSTERED INDEX [IX_Contracts_ClientID] ON [Deal].[Contracts] ([ClientID])
GO

GO
CREATE NONCLUSTERED INDEX [IX_Contracts_ClientID_CarID] ON [Deal].[Contracts] ([ClientID]) INCLUDE ([CarID])

--drop INDEX [IX_Contracts_CarID_ClientID] ON [Deal].[Contracts]