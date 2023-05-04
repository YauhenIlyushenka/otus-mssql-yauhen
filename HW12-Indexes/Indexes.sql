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