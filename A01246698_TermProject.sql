USE [TermProject];
GO


/*B part - Data Retrieval*/

/*B1 - Retrieve Order Details with Quantity Range*/
SELECT OrderDetails.OrderID,
	   OrderDetails.Quantity, 
	   Products.ProductID, 
	   Products.ReorderLevel, 
	   Suppliers.SupplierID
FROM OrderDetails
JOIN 
    Products ON OrderDetails.ProductID = Products.ProductID
JOIN 
    Suppliers ON Products.SupplierID = Suppliers.SupplierID
WHERE 
    OrderDetails.Quantity BETWEEN 90 AND 100
ORDER BY 
    OrderDetails.OrderID;


/*B2 - List Products with Unit Price Less than $10*/
SELECT 
    ProductID, 
    ProductName, 
    EnglishName, 
    FORMAT(UnitPrice, 'C', 'en-US') AS UnitPrice
FROM 
    Products
WHERE 
    UnitPrice < 10.00
ORDER BY 
    ProductID;


/*B3 - List Customers from Canada or USA*/
SELECT 
    CustomerID, 
    CompanyName, 
    Country, 
    Phone
FROM 
    Customers
WHERE 
    Country IN ('Canada', 'USA')
ORDER BY 
    CompanyName;


/*B4 - List Products with Units In Stock Close to Reorder Level*/
SELECT 
    Suppliers.SupplierID, 
    Suppliers.Name, 
    Products.ProductName, 
    Products.ReorderLevel, 
    Products.UnitsInStock
FROM 
    Suppliers 
JOIN 
    Products ON Suppliers.SupplierID = Products.SupplierID
WHERE 
    Products.UnitsInStock > Products.ReorderLevel AND Products.UnitsInStock <= (Products.ReorderLevel + 10)
ORDER BY 
    Products.ProductName;


/*B5 - Count of Orders Placed by Each Company in December 1993*/
SELECT 
    Customers.CompanyName,
    COUNT(Orders.OrderID) AS Amount
FROM 
    Customers
JOIN 
    Orders ON Customers.CustomerID = Orders.CustomerID
WHERE 
    Orders.OrderDate >= '1993-12-01' AND Orders.OrderDate <= '1993-12-31'
GROUP BY 
    Customers.CompanyName
ORDER BY 
    Customers.CompanyName;


/*B6 - List Top 10 Most Popular Products by Order Count*/
SELECT TOP (10) 
    Products.ProductName,
    COUNT(OrderDetails.OrderID) AS Amount
FROM 
    Products
JOIN 
    OrderDetails ON Products.ProductID = OrderDetails.ProductID
GROUP BY 
    Products.ProductID, Products.ProductName
ORDER BY 
    Amount DESC;


/*B7 - List Top 10 Most Popular Products by Total Quantity Ordered*/
SELECT TOP (10)
    Products.ProductName,
    SUM(OrderDetails.Quantity) AS Quantity
FROM 
    Products
JOIN 
    OrderDetails ON Products.ProductID = OrderDetails.ProductID
GROUP BY 
    Products.ProductID, Products.ProductName
ORDER BY 
    Quantity DESC;


/*B8 - List Orders Shipped to Vancouver with Unit Price and Quantity*/
SELECT 
    Orders.OrderID,
	FORMAT(OrderDetails.UnitPrice, 'C', 'en-US') AS UnitPrice,
    OrderDetails.Quantity
FROM 
    Orders
JOIN 
    OrderDetails ON Orders.OrderID = OrderDetails.OrderID
WHERE 
    Orders.ShipCity = 'Vancouver'
ORDER BY 
    Orders.OrderID;


/*B9 - List Unshipped Orders with Customer Information*/
SELECT 
    Customers.CustomerID,
    Customers.CompanyName,
    Orders.OrderID,
    FORMAT(Orders.OrderDate, 'MMMM dd, yyyy') AS OrderDate
FROM 
    Customers
JOIN 
    Orders ON Customers.CustomerID = Orders.CustomerID
WHERE 
    Orders.ShippedDate IS NULL
ORDER BY 
    Customers.CustomerID, Orders.OrderDate;


/*B10 - List Products with Names Containing 'choc' or 'chok'*/
SELECT 
    ProductID,
    ProductName,
    QuantityPerUnit,
    FORMAT(UnitPrice, 'C', 'en-US') AS UnitPrice
FROM 
    Products
WHERE 
    ProductName LIKE '%choc%' OR ProductName LIKE '%chok%'
ORDER BY 
    ProductName;


/*B11 - Count of Products for Each Character in the Name*/
SELECT 
    SUBSTRING(ProductName, 1, 1) AS [Character],
    COUNT(*) AS Total
FROM 
    Products
GROUP BY 
    SUBSTRING(ProductName, 1, 1)
HAVING 
    COUNT(*) > 1;


/* C part - Views and Updates*/

/*C1 - A View for Products Under $10*/
DROP VIEW IF EXISTS vProductsUnder10;
GO
CREATE VIEW vProductsUnder10 
AS
SELECT 
    Products.ProductName,
    FORMAT(Products.UnitPrice, 'C', 'en-US') AS UnitPrice,
    Suppliers.SupplierID,
    Suppliers.Name
FROM 
    Products
JOIN 
    Suppliers ON Products.SupplierID = Suppliers.SupplierID
WHERE 
    Products.UnitPrice < 10;
GO

SELECT * FROM [TermProject].[dbo].[vProductsUnder10]
ORDER BY [ProductName];


/*C2 - A View for Orders by Employee*/
DROP VIEW IF EXISTS vOrdersByEmployee;
GO
CREATE VIEW vOrdersByEmployee 
AS
SELECT 
    CONCAT(Employees.FirstName, ' ', Employees.LastName) AS Name,
    COUNT(Orders.OrderID) AS Orders
FROM 
    Employees
LEFT JOIN 
    Orders ON Employees.EmployeeID = Orders.EmployeeID
GROUP BY 
    Employees.EmployeeID, Employees.FirstName, Employees.LastName;
GO

SELECT * FROM [TermProject].[dbo].[vOrdersByEmployee]
ORDER BY [Orders] DESC;


/*C3 - Update Operation, Set 'Unknown' for NULL Fax Values*/
UPDATE Customers
SET Fax = 'Unknown'
WHERE Fax IS NULL;

SELECT @@ROWCOUNT AS [Rows Affected];


/*C4 - A View for Order Cost*/
DROP VIEW IF EXISTS vOrderCost;
GO
CREATE VIEW vOrderCost AS
SELECT 
    Orders.OrderID,
    FORMAT(Orders.OrderDate, 'MMMM dd, yyyy') AS OrderDate,
    Customers.CompanyName,
    SUM(OrderDetails.Quantity * OrderDetails.UnitPrice) AS OrderCost
FROM 
    Orders
JOIN 
    Customers ON Orders.CustomerID = Customers.CustomerID
JOIN 
    OrderDetails ON Orders.OrderID = OrderDetails.OrderID
GROUP BY 
    Orders.OrderID, Orders.OrderDate, Customers.CompanyName;
GO

SELECT TOP(5) [OrderID]
		,[OrderDate]
		,[CompanyName]
		,FORMAT([OrderCost], 'C') AS [Cost]
	FROM [TermProject].[dbo].[vOrderCost]
	ORDER BY [OrderCost] DESC;


/*C5 - Insert Operation, Add a New Supplier*/
INSERT INTO Suppliers (SupplierID, Name)
VALUES (16, 'Supplier P');

SELECT SupplierID, Name
FROM Suppliers
WHERE SupplierID > 10
ORDER BY SupplierID;


/*C6 - Update Operation, Increase Unit Prices by 15%*/
UPDATE Products
SET UnitPrice = UnitPrice * 1.15
WHERE UnitPrice < 5.00;

SELECT @@ROWCOUNT AS [Rows Affected];


/* D part - Functions, stored procedures, and triggers */

/*D1 - Function for Customers by Country*/
DROP FUNCTION IF EXISTS CustomersByCountry;
GO
CREATE FUNCTION CustomersByCountry(@CountryName NVARCHAR(15))
RETURNS TABLE
AS
RETURN
    SELECT 
        CustomerID,
        CompanyName,
        City,
        Address
    FROM 
        Customers
    WHERE 
        Country = @CountryName
GO

SELECT * FROM [TermProject].[dbo].[CustomersByCountry]('Germany')
ORDER BY [CompanyName]


/*D2 - A Function for Products in Price Range*/
DROP FUNCTION IF EXISTS ProductsInRange;
GO
CREATE FUNCTION ProductsInRange(@MinPrice MONEY, @MaxPrice MONEY)
RETURNS TABLE
AS
RETURN
    SELECT 
        ProductID,
        ProductName,
        EnglishName,
        FORMAT(UnitPrice, 'C') AS UnitPrice
    FROM 
        Products
    WHERE 
        UnitPrice BETWEEN @MinPrice AND @MaxPrice
GO

SELECT * FROM [TermProject].[dbo].[ProductsInRange](30, 50)
ORDER BY [UnitPrice];


/*D3 - A Stored Procedure for Employee Information*/
DROP PROCEDURE IF EXISTS EmployeeInfo;
GO
CREATE PROCEDURE EmployeeInfo(@EmployeeID INT)
AS
BEGIN
    SELECT 
        EmployeeID,
        LastName,
        FirstName,
        Address,
        City,
		Province,
		PostalCode,
		Phone,
        DATEDIFF(YEAR, BirthDate, '1994-01-01') AS Age
    FROM 
        Employees
    WHERE 
        EmployeeID = @EmployeeID;
END
GO

EXEC [TermProject].[dbo].[EmployeeInfo] 9;


/*D4 - A Stored Procedure for Customers by City*/
DROP PROCEDURE IF EXISTS CustomersByCity;
GO
CREATE PROCEDURE CustomersByCity(@City NVARCHAR(15))
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CustomerID,
        CompanyName,
        Address,
        City,
        Phone
    FROM 
        Customers
    WHERE 
        City = @City
    ORDER BY 
        CustomerID;
END
GO

EXEC [TermProject].[dbo].[CustomersByCity] 'London';


/*D5 - A Store Procedure of listing products within a specified price range*/
DROP PROCEDURE IF EXISTS UnitPriceByRange;
GO
CREATE PROCEDURE UnitPriceByRange(@MinPrice MONEY, @MaxPrice MONEY)
AS
BEGIN
    SELECT 
        ProductID,
        ProductName,
        EnglishName,
        FORMAT(UnitPrice, 'C') AS UnitPrice
    FROM 
        Products
    WHERE 
        UnitPrice BETWEEN @MinPrice AND @MaxPrice
    ORDER BY 
        Products.UnitPrice;
END
GO

EXEC [TermProject].[dbo].[UnitPriceByRange] 6.00, 12.00;


/*D6 - A Stored Procedure of listing orders shipped between specified dates*/
DROP PROCEDURE IF EXISTS OrdersByDates;
GO
CREATE PROCEDURE OrdersByDates(@StartDate DATE, @EndDate DATE)
AS
BEGIN
    SELECT 
        Orders.OrderID,
        Customers.CompanyName AS Customer,
        Shippers.CompanyName AS Shipper,
        FORMAT(Orders.ShippedDate, 'MMMM dd, yyyy') AS ShippedDate
    FROM 
        Orders
    JOIN 
        Customers ON Orders.CustomerID = Customers.CustomerID
    JOIN 
        Shippers ON Orders.ShipperID = Shippers.ShipperID
    WHERE 
        Orders.ShippedDate BETWEEN @StartDate AND @EndDate
    ORDER BY 
        Orders.ShippedDate;
END
GO

EXEC [TermProject].[dbo].[OrdersByDates] '1991-05-15', '1991-05-31';


/*D7 - A Stored Procedure listing distinct products of a specified type ordered during a specified month and year*/
DROP PROCEDURE IF EXISTS ProductsByMonthAndYear;
GO
CREATE PROCEDURE ProductsByMonthAndYear(@ProductName NVARCHAR(40), @Month NVARCHAR(9), @Year INT)
AS
BEGIN
    DECLARE @MonthNumber INT;
    SET @MonthNumber = 
        CASE LOWER(@Month)
            WHEN 'january' THEN 1
            WHEN 'february' THEN 2
            WHEN 'march' THEN 3
            WHEN 'april' THEN 4
            WHEN 'may' THEN 5
            WHEN 'june' THEN 6
            WHEN 'july' THEN 7
            WHEN 'august' THEN 8
            WHEN 'september' THEN 9
            WHEN 'october' THEN 10
            WHEN 'november' THEN 11
            WHEN 'december' THEN 12
        END
    SELECT
        Products.EnglishName,
        FORMAT(Products.UnitPrice, 'C') AS UnitPrice,
        Products.UnitsInStock,
        Suppliers.Name
    FROM 
        Products
    JOIN 
        OrderDetails ON Products.ProductID = OrderDetails.ProductID
    JOIN 
        Orders ON OrderDetails.OrderID = Orders.OrderID
    JOIN 
        Suppliers ON Products.SupplierID = Suppliers.SupplierID
    WHERE 
        Products.EnglishName LIKE @ProductName
        AND MONTH(Orders.OrderDate) = MONTH(DATEFROMPARTS(@Year, @MonthNumber, 1))
        AND YEAR(Orders.OrderDate) = @Year
    GROUP BY
        Products.EnglishName, Products.UnitPrice, Products.UnitsInStock, Suppliers.Name;
END
GO

EXEC [TermProject].[dbo].[ProductsByMonthAndYear] '%cheese', 'December', 1992;


/*D8 - A Stored Procedure of listing products where the reorder level subtracted from the units in stock is less than a specified value*/
DROP PROCEDURE IF EXISTS ReorderQuantity;
GO
CREATE PROCEDURE ReorderQuantity(@InputReorderQuantity  INT)
AS
BEGIN
    SELECT
        Products.ProductID,
        Products.ProductName,
		Suppliers.Name,
        Products.UnitsInStock,
        Products.ReorderLevel
    FROM 
        Products
    JOIN 
        Suppliers ON Products.SupplierID = Suppliers.SupplierID
    WHERE 
        (Products.UnitsInStock - Products.ReorderLevel) < @InputReorderQuantity
    ORDER BY 
        Products.ProductName;
END
GO

EXEC [TermProject].[dbo].[ReorderQuantity] 5;


/*D9 - A Stored Procedure of listing orders with details and days delayed if shipped later than the required date*/
DROP PROCEDURE IF EXISTS ShippingDelay;
GO
CREATE PROCEDURE ShippingDelay(@CutoffDate DATE)
AS
BEGIN
    SELECT
        Orders.OrderID,
		Customers.CompanyName AS CustomerName,
        Shippers.CompanyName AS ShipperName,
        FORMAT(Orders.OrderDate, 'MMMM dd, yyyy') AS OrderDate,
        FORMAT(Orders.RequiredDate, 'MMMM dd, yyyy') AS RequiredDate,
        FORMAT(Orders.ShippedDate, 'MMMM dd, yyyy') AS ShippedDate,
        DATEDIFF(DAY, Orders.RequiredDate, Orders.ShippedDate) AS DaysDelayedBy
    FROM 
        Orders
    JOIN 
        Customers ON Orders.CustomerID = Customers.CustomerID
    JOIN 
        Shippers ON Orders.ShipperID = Shippers.ShipperID
    WHERE 
        Orders.OrderDate > @CutoffDate
        AND Orders.ShippedDate > Orders.RequiredDate
    ORDER BY 
        Orders.OrderDate;
END
GO

EXEC [TermProject].[dbo].[ShippingDelay] '1993-12-01';


/*D10 -  A Store Procedure of deleting customers that have no orders*/
DROP PROCEDURE IF EXISTS DeleteInactiveCustomers;
GO
CREATE PROCEDURE DeleteInactiveCustomers
AS
BEGIN
    DELETE FROM Customers
    WHERE CustomerID NOT IN (SELECT DISTINCT CustomerID FROM Orders);
END
GO

EXEC DeleteInactiveCustomers;
GO
SELECT COUNT(*) AS [ActiveCustomers] FROM [TermProject].[dbo].[Customers];
GO


/*D11 - Instead Of Insert Trigger for Shippers*/
CREATE TRIGGER InsertShippers
ON Shippers
INSTEAD OF INSERT
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Shippers
        WHERE EXISTS (
            SELECT 1
            FROM inserted
            WHERE Shippers.CompanyName = inserted.CompanyName
        )
    )
    BEGIN
        INSERT INTO Shippers (ShipperID, CompanyName)
        SELECT ShipperID, CompanyName FROM inserted;
    END
END
GO

INSERT INTO [TermProject].[dbo].[Shippers]
VALUES (4, 'Federal Shipping');
GO
SELECT * FROM [TermProject].[dbo].[Shippers];
GO
INSERT INTO [TermProject].[dbo].[Shippers]
VALUES (4, 'On-Time Delivery');
GO
SELECT * FROM [TermProject].[dbo].[Shippers];
GO


/*D12 -  Instead Of Insert and Update Trigger for OrderDetails*/
CREATE TRIGGER CheckQuantity
ON OrderDetails
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM inserted
        JOIN Products ON inserted.ProductID = Products.ProductID
        WHERE Products.UnitsInStock < inserted.Quantity
    )
    BEGIN
        MERGE INTO OrderDetails AS target
        USING inserted AS source
        ON target.OrderID = source.OrderID AND target.ProductID = source.ProductID
        WHEN MATCHED THEN
            UPDATE SET target.Quantity = source.Quantity
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (OrderID, ProductID, Quantity) VALUES (source.OrderID, source.ProductID, source.Quantity);
    END
	ELSE
	BEGIN
		SELECT 'Ordered: ' + CAST(inserted.Quantity AS NVARCHAR) + '; available: ' + CAST(Products.UnitsInStock AS NVARCHAR) AS Error
		FROM inserted
        JOIN Products ON inserted.ProductID = Products.ProductID
        WHERE Products.UnitsInStock < inserted.Quantity
	END
END
GO


/*Term Project Part - to check the correct output*/
UPDATE [TermProject].[dbo].[OrderDetails]
SET [Quantity] = 50
WHERE [OrderID] = 10044 AND [ProductID] = 77;
GO

SELECT [Quantity] FROM [TermProject].[dbo].[OrderDetails]
WHERE [OrderID] = 10044 AND [ProductID] = 77
GO

UPDATE [TermProject].[dbo].[OrderDetails]
SET [Quantity] = 30
WHERE [OrderID] = 10044 AND [ProductID] = 77;
GO

SELECT [Quantity] FROM [TermProject].[dbo].[OrderDetails]
WHERE [OrderID] = 10044 AND [ProductID] = 77
GO