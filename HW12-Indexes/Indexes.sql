USE RentalFirm
GO

--SELECT SERVERPROPERTY('IsFullTextInstalled')
--EXEC sp_fulltext_database 'Enable'
--SELECT * FROM sys.fulltext_catalogs
--SELECT name as [DBName], is_fulltext_enabled
--FROM sys.databases

--SELECT LCID, NAME
--FROM 
--SYS.FULLTEXT_LANGUAGES;

--EXEC sp_configure 'default full-text language' --1033

CREATE FULLTEXT CATALOG [RentalFirm_BrandsCatalog]
WITH ACCENT_SENSITIVITY = ON AS DEFAULT
GO

IF NOT EXISTS(
	SELECT * FROM [sys].[fulltext_indexes]
	WHERE [object_id] = object_id('[Car].[Brands]'))
BEGIN
	CREATE FULLTEXT INDEX
	ON [Car].[Brands]
	(
		[Description] LANGUAGE 1033
	)
	KEY INDEX [PK_Brands]
	ON [RentalFirm_BrandsCatalog]
	WITH STOPLIST OFF;
END
GO

--ALTER FULLTEXT INDEX ON [Car].[Brands]
--START FULL POPULATION;