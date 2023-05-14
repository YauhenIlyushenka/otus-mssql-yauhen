USE WideWorldImporters;
GO

-- Включаем CLR
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'clr enabled', 1;
EXEC sp_configure 'clr strict security', 0;
GO

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; 

-- Подключаем dll 
-- Измените путь к файлу!
CREATE ASSEMBLY MyAssembly
FROM 'D:\SQL\OtusSqlDev\otus-mssql-yauhen\HW15-CLR\HW15DemoCLR\bin\Debug\HW15DemoCLR.dll'
WITH PERMISSION_SET = SAFE;  

-- DROP ASSEMBLY SimpleDemoAssemblyr

-- Файл сборки (dll) на диске больше не нужен, она копируется в БД

-- Как посмотреть зарегистрированные сборки 

-- SSMS
-- <DB> -> Programmability -> Assemblies 

-- Посмотреть подключенные сборки (SSMS: <DB> -> Programmability -> Assemblies)
SELECT * FROM sys.assemblies;
GO

-- Create CustomType
CREATE TYPE [dbo].[CustomEmailType] EXTERNAL NAME MyAssembly.[HW15DemoCLR.CustomEmailType];
GO

-- Executing properly
DECLARE @email CustomEmailType
SET @email = 'yauhen@mail.com'
SELECT 
	@email AS [Binary], 
	@email.ToString() AS [EmailByString]
GO

-- NULL
DECLARE @email CustomEmailType;
SELECT 
	@email AS [Binary], 
	@email.ToString() AS [EmailByString]
GO

--Validation with error
DECLARE @email CustomEmailType;
SET @email = '...@mail.com';
GO

-- Set email by property
DECLARE @email CustomEmailType;
SET @email = 'yauhen@mail.com';
SET @email.Email = 'anton@mail.com';
SELECT 
	@email AS [Binary], 
	@email.ToString() AS [EmailByString]
GO

