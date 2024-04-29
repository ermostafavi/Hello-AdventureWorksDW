/* --------------------
   InterView Questions
   --------------------*/
--1-Write a query that displays the Sales amount of internet sales by country
SELECT
	DimGeography.EnglishCountryRegionName AS Country,
	SUM(FactInternetSales.SalesAmount) AS SalesAmount_Country
FROM FactInternetSales
LEFT JOIN DimCustomer ON FactInternetSales.CustomerKey = DimCustomer.CustomerKey
LEFT JOIN DimGeography ON DimCustomer.GeographyKey = DimGeography.GeographyKey
GROUP BY DimGeography.EnglishCountryRegionName

--2-Write a query that displays the second customer with the highest Total purchase amount according to the total online purchases of each customer
SELECT 
	CustomerKey,
	FirstName,
	LastName,
	CustomerBuy
FROM(
	SELECT
		DimCustomer.CustomerKey,
		DimCustomer.FirstName,
		DimCustomer.LastName,
		SUM(SalesAmount) AS CustomerBuy,
		RANK() OVER (ORDER BY SUM(SalesAmount) DESC) AS RankSalesAmount
	FROM FactInternetSales
	LEFT JOIN DimCustomer ON FactInternetSales.CustomerKey = DimCustomer.CustomerKey
	GROUP BY Dimcustomer.CustomerKey, DimCustomer.FirstName, DimCustomer.LastName
) AS RankTable
WHERE RankSalesAmount = 2


--3-Write a query that calculates the total internet sales of each product subcategory and then arranges these subcategories in each category and rank
SELECT
	EnglishProductCategoryName,
	EnglishProductSubcategoryName,
	SalesSubCategory,
	RANK() OVER(PARTITION BY EnglishProductCategoryName
				ORDER BY SalesSubCategory DESC) AS RankNumber
FROM(
	SELECT 
		EnglishProductSubcategoryName,
		ProductCategoryKey,
		SUM(SalesAmount) AS SalesSubCategory
	FROM FactInternetSales
	LEFT JOIN DimProduct ON FactInternetSales.ProductKey = DimProduct.ProductKey
	LEFT JOIN DimProductSubcategory ON DimProduct.ProductSubcategoryKey = DimProductSubcategory.ProductSubcategoryKey
	GROUP BY EnglishProductSubcategoryName, ProductCategoryKey
	) AS Table1
	LEFT JOIN DimProductCategory ON Table1.ProductCategoryKey = DimProductCategory.ProductCategoryKey

--4-Write a Store Procedure that receives the product ID and returns the number of internet sales invoices that include that product
DROP PROC IF EXISTS CountSalesPerProductID
GO

CREATE PROC CountSalesPerProductID
	@ProductID AS NVARCHAR(25),
	@CountSalesPerProduct AS INT OUTPUT
AS
SET NOCOUNT ON;	

SELECT 
	COUNT(FactInternetSales.ProductKey)
FROM FactInternetSales
LEFT JOIN DimProduct ON FactInternetSales.ProductKey = DimProduct.ProductKey
WHERE DimProduct.ProductAlternateKey = @ProductID;
GO
--for execution this SP
DECLARE @rc AS INT;
EXEC CountSalesPerProductID
	@ProductID = 'BK-R93R-62',
	@CountSalesPerProduct = @rc OUTPUT

--5-Write a Store Procedure that receives the year number as a 4-digit number and show the growth rate of internet sales for each month of the selected year.
DROP PROC IF EXISTS GrowthInternetSales
GO

CREATE PROC GrowthInternetSales
	@Year AS INT
AS
SET NOCOUNT ON;	

SELECT
    OrderYear,
    OrderMonth,
    TotalSalesCurrentMonth,
	LagTotalSalesLastMonth,
    (TotalSalesCurrentMonth - LagTotalSalesLastMonth) AS SalesGrowth,
	100*(TotalSalesCurrentMonth - LagTotalSalesLastMonth)/TotalSalesCurrentMonth AS SalesGrowthPercent
FROM (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        SUM(SalesAmount) AS TotalSalesCurrentMonth,
        LAG(SUM(SalesAmount)) OVER (ORDER BY YEAR(OrderDate), MONTH(OrderDate)) AS LagTotalSalesLastMonth
    FROM
        FactInternetSales
    WHERE
        YEAR(OrderDate) = @Year
    GROUP BY
        YEAR(OrderDate), MONTH(OrderDate)
) AS MonthlySales;
--for execution this SP
EXEC GrowthInternetSales
	@Year = 2011

--6-Write a view that returns the 3rd to 5th best-selling product in online sales
DROP VIEW IF EXISTS ThirdToFifthProduct;
GO

CREATE VIEW ThirdToFifthProduct
AS

SELECT
	EnglishProductCategoryName,
	EnglishProductSubcategoryName,
	SalesSubCategory
FROM(
	SELECT 
		EnglishProductSubcategoryName,
		ProductCategoryKey,
		SUM(SalesAmount) AS SalesSubCategory
	FROM FactInternetSales
	LEFT JOIN DimProduct ON FactInternetSales.ProductKey = DimProduct.ProductKey
	LEFT JOIN DimProductSubcategory ON DimProduct.ProductSubcategoryKey = DimProductSubcategory.ProductSubcategoryKey
	GROUP BY EnglishProductSubcategoryName, ProductCategoryKey
	) AS Table1
	LEFT JOIN DimProductCategory ON Table1.ProductCategoryKey = DimProductCategory.ProductCategoryKey
ORDER BY SalesSubCategory DESC
OFFSET 2 ROWS FETCH NEXT 3 ROWS ONLY
GO

--7-Designed 3 key performance indicators (KPI) for the internet sales of this business and write query for each KPI
/* --------------------
   First KPI: Total Sales via internet per Year and per Month
   The Total Sales Key Performance Indicator (KPI) represents the overall revenue generated from sales transactions 
   within a defined period, typically measured in a specific time frame such as monthly, quarterly, or annually. 
   This metric provides a comprehensive view of the financial performance of a business's sales activities. 
   It includes the sum of all sales amounts for products or services sold during the specified period, 
   regardless of the number of transactions or individual sales figures. Monitoring Total Sales KPI helps organizations 
   assess their revenue-generating capabilities, track sales performance over time, identify trends, 
   and make informed strategic decisions to optimize sales efforts and achieve business objectives.
   --------------------*/
--TotalSales via internet per Year
SELECT 
    YEAR(OrderDate) AS OrderYear,
    SUM(SalesAmount) AS TotalSales
FROM 
    FactInternetSales
GROUP BY 
    YEAR(OrderDate)
ORDER BY 
    YEAR(OrderDate);
--TotalSales via internet per Month
SELECT 
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    SUM(SalesAmount) AS TotalSales
FROM 
    FactInternetSales
GROUP BY 
    YEAR(OrderDate), MONTH(OrderDate)
ORDER BY 
    YEAR(OrderDate), MONTH(OrderDate);

/* --------------------
   Second KPI: Number of total Internet Orders per Year and per Month
   The total number of orders, whether monthly or annually, is a key performance indicator (KPI). This metric indicates 
   the activity and volume of transactions conducted within a specific period and can assist in analyzing and evaluating 
   sales trends and activity levels over time. Assessing the total number of orders annually can help managers monitor changes
   and trends in sales throughout the year and consequently implement strategies to improve sales and facilitate related activities.
   Additionally, evaluating monthly order counts can reveal various patterns of customer behavior throughout the year and aid managers
   in enhancing marketing and sales strategies.
   --------------------*/
--TotalNumber of internet Orders per Year
SELECT 
	YEAR(OrderDate) AS OrderYear,
    COUNT(*) AS TotalNumberOrdersYear
FROM 
    FactInternetSales
GROUP BY 
    YEAR(OrderDate)
ORDER BY 
    YEAR(OrderDate);
--TotalNumber of internet Orders per Month
SELECT 
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    COUNT(*) AS TotalNumberOrdersMonth
FROM 
    FactInternetSales
GROUP BY 
    YEAR(OrderDate), MONTH(OrderDate)
ORDER BY 
    YEAR(OrderDate), MONTH(OrderDate);

/* --------------------
   Third KPI: Number of Unique Products sold via the internet
   The Key Performance Indicator (KPI) for the number of unique products represents the count of distinct products sold within a specified period.
   This metric provides insights into the variety and diversity of products that contribute to a company's sales performance. 
   It measures the breadth of the product offering and the market penetration achieved by the business.
   Monitoring the number of unique products sold helps organizations understand their product portfolio's effectiveness, identify popular and niche products,
   assess market demand, and make strategic decisions related to product development, inventory management, and marketing strategies.  
   --------------------*/
SELECT 
	DISTINCT COUNT(*) AS UniqueSalesProducts
FROM FactInternetSales
LEFT JOIN DimProduct ON FactInternetSales.ProductKey = DimProduct.ProductKey
