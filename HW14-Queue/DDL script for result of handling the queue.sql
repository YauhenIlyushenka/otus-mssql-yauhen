USE WideWorldImporters
GO

-- Create table for queue [Sales].[Reports]
CREATE TABLE [Sales].[Reports] 
(
	ReportId BIGINT NOT NULL IDENTITY(1,1),
	CustomerId INT NOT NULL,
	OrdersCount INT NOT NULL,
	StartedDate DATETIME2,
	FinishedDate DATETIME2
)
GO

ALTER TABLE [Sales].[Reports] 
ADD CONSTRAINT [PK_Reports] PRIMARY KEY CLUSTERED ([ReportId] ASC)
GO
ALTER TABLE [Sales].[Reports]
ADD CONSTRAINT FK_Reports_Customers FOREIGN KEY (CustomerId) REFERENCES [Sales].[Customers] (CustomerID)
GO