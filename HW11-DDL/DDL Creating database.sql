USE master; 
GO 
IF DB_ID (N'RentalFirm') IS NULL 
	CREATE DATABASE RentalFirm;
GO

USE RentalFirm
GO

CREATE SCHEMA Car;
GO

CREATE SCHEMA Users;
GO

CREATE SCHEMA Insurance;
GO

CREATE SCHEMA Deal;
GO

PRINT N'Creating table Colors'
GO

CREATE TABLE [Car].[Colors] (
	ColorID INT NOT NULL IDENTITY(1,1),
	ColorName NVARCHAR(50) NOT NULL
);

GO
ALTER TABLE [Car].[Colors] 
ADD CONSTRAINT [PK_Colors] PRIMARY KEY CLUSTERED ([ColorID] ASC)
GO

GO
PRINT N'Creating table Models'
GO

CREATE TABLE [Car].[Models] (
	ModelID BIGINT NOT NULL IDENTITY(1,1),
	[Description] NVARCHAR(100) NOT NULL
);

GO
ALTER TABLE [Car].[Models] 
ADD CONSTRAINT [PK_Models] PRIMARY KEY CLUSTERED ([ModelID] ASC)
GO

GO
PRINT N'Creating table Brands'
GO

CREATE TABLE Car.Brands (
	BrandID INT NOT NULL IDENTITY(1,1),
	ModelID BIGINT NOT NULL,
	[Description] NVARCHAR(100) NOT NULL
);

GO
ALTER TABLE [Car].[Brands] 
ADD CONSTRAINT [PK_Brands] PRIMARY KEY CLUSTERED ([BrandID] ASC)
GO
ALTER TABLE [Car].[Brands]
ADD CONSTRAINT FK_Brands_Models FOREIGN KEY (ModelID) REFERENCES [Car].[Models] (ModelID)

GO
PRINT N'Creating table Cars'
GO

CREATE TABLE [Car].[Cars] (
	CarID BIGINT NOT NULL IDENTITY(1,1),
	BrandID INT NOT NULL, 
	ColorID INT NOT NULL,
	RaliseDate DATETIME2
)

GO
ALTER TABLE [Car].[Cars] 
ADD CONSTRAINT [PK_Cars] PRIMARY KEY CLUSTERED ([CarID] ASC)
GO
ALTER TABLE [Car].[Cars]
ADD CONSTRAINT FK_Cars_Brands FOREIGN KEY (BrandID) REFERENCES [Car].[Brands] (BrandID)
GO
ALTER TABLE [Car].[Cars]
ADD CONSTRAINT FK_Cars_Colors FOREIGN KEY (ColorID) REFERENCES [Car].[Colors] (ColorID)

GO
PRINT N'Creating table Companies'
GO

CREATE TABLE [Insurance].[Companies] (
	CompanyID INT NOT NULL IDENTITY(1,1),
	CompanyName NVARCHAR(100) NOT NULL,
	CreatedDate DATETIME2
)

GO
ALTER TABLE [Insurance].[Companies] 
ADD CONSTRAINT [PK_Companies] PRIMARY KEY CLUSTERED ([CompanyID] ASC)
GO

GO
PRINT N'Creating table Insurances'
GO

CREATE TABLE Insurance.Insurances (
	InsuranceID BIGINT NOT NULL IDENTITY(1,1),
	CarID BIGINT NOT NULL,
	CompanyID INT NOT NULL,
	[Year] INT NOT NULL,
	Price DECIMAL(18,3)
)

GO
ALTER TABLE [Insurance].[Insurances] 
ADD CONSTRAINT [PK_Insurances] PRIMARY KEY CLUSTERED ([InsuranceID] ASC)
GO
ALTER TABLE [Insurance].[Insurances]
ADD CONSTRAINT FK_Insurances_Cars FOREIGN KEY (CarID) REFERENCES [Car].[Cars] (CarID)
GO
ALTER TABLE [Insurance].[Insurances]
ADD CONSTRAINT FK_Insurances_Companies FOREIGN KEY (CompanyID) REFERENCES [Insurance].[Companies] (CompanyID)

GO
PRINT N'Creating table Clients'
GO

CREATE TABLE [Users].[Clients] (
	ClientID BIGINT NOT NULL IDENTITY(1,1),
	FirstName NVARCHAR(50) NOT NULL,
	LastName NVARCHAR(100) NOT NULL,
	Email NVARCHAR(50) NOT NULL,
	Phone NVARCHAR(20) NOT NULL
)

GO
ALTER TABLE [Users].[Clients] 
ADD CONSTRAINT [PK_Clients] PRIMARY KEY CLUSTERED ([ClientID] ASC)
GO
ALTER TABLE [Users].[Clients]
ADD CONSTRAINT UQ_Clients_Email UNIQUE (Email);

GO
PRINT N'Creating table Employees'
GO

CREATE TABLE [Users].[Employees] (
	EmployeeID BIGINT NOT NULL IDENTITY(1,1),
	FirstName NVARCHAR(50) NOT NULL,
	LastName NVARCHAR(100) NOT NULL,
	Email NVARCHAR(50) NOT NULL,
	Phone NVARCHAR(20) NOT NULL
)

GO
ALTER TABLE [Users].[Employees] 
ADD CONSTRAINT [PK_Employees] PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
GO
ALTER TABLE [Users].[Employees]
ADD CONSTRAINT UQ_Employees_Email UNIQUE (Email);
GO
PRINT N'Creating table Contracts'
GO

CREATE TABLE [Deal].[Contracts] (
	ContractID BIGINT NOT NULL IDENTITY(1,1),
	CarID BIGINT NOT NULL,
	ClientID BIGINT NOT NULL,
	EmployeeID BIGINT NOT NULL,
	CreatedDate DATETIME2,
	DurationDays INT NOT NULL,
	Price DECIMAL(18,3)
)

GO
ALTER TABLE [Deal].[Contracts] 
ADD CONSTRAINT [PK_Contracts] PRIMARY KEY CLUSTERED ([ContractID] ASC)
GO
ALTER TABLE [Deal].[Contracts]
ADD CONSTRAINT FK_Contracts_Cars FOREIGN KEY (CarID) REFERENCES [Car].[Cars] (CarID)
GO
ALTER TABLE [Deal].[Contracts]
ADD CONSTRAINT FK_Contracts_Clients FOREIGN KEY (ClientID) REFERENCES [Users].[Clients] (ClientID)
GO
ALTER TABLE [Deal].[Contracts]
ADD CONSTRAINT FK_Contracts_Employees FOREIGN KEY (EmployeeID) REFERENCES [Users].[Employees] (EmployeeID)
GO