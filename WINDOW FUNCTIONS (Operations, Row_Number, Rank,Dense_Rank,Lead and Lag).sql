-- window functions (USED FOR PERFORMING AGGERGATIONS) with OVER().

SELECT A.[FirstName],
		A.[LastName],
		B.[JobTitle],
		AverageRate = AVG(c.[Rate]) OVER(),--Returns the AVG of all values in the Rate column, in each row
		MaxRate = MAX(C.[Rate]) OVER(),--Returns the Max of all values in the Rate column, in each row
		DiffFromAvgRate = c.[Rate] - AVG(C.[Rate]) OVER(),-- Returns an employees's pay rate, MINUS the average of all values in the "Rate" column.
		PercentMaxRate = C.[Rate]/MAX(C.[Rate]) OVER()--Returns an employees's pay rate, DIVIDED the MAX of all values in the "Rate" column.
FROM [Person].[Person] AS A
INNER JOIN [HumanResources].[Employee] AS B
ON A.[BusinessEntityID] = B.[BusinessEntityID]
INNER JOIN [HumanResources].[EmployeePayHistory] AS C
ON B.[BusinessEntityID] = C.[BusinessEntityID]

-- WINDOW FUNCTIONS with OVER and PARTITION BY.
-- PARTITION BY allows us to compute aggregate totals for groups within our data
--Sum of line totals, grouped by ProductID AND OrderQty, in an aggregate query
--for Product IDLineTotal in ORDERQTY = 24, 321 + 422 = 743
SELECT	[ProductID],
		[OrderQty],
		[LineTotal],
		ProductIDLineTotal = SUM([LineTotal]) OVER(PARTITION BY [ProductID],[OrderQty])
FROM [Sales].[SalesOrderDetail]
ORDER BY [ProductID], [OrderQty] desc

--lets compare with normal groupby
SELECT	[ProductID],
		[OrderQty],
		[LineTotal] = SUM([LineTotal])
FROM [Sales].[SalesOrderDetail]
GROUP BY  [ProductID],[OrderQty]
ORDER BY 1,2 desc

--More PARTITION BY EXAMPLES
--"AvgPriceByCategoryAndSubcategory" returns the avg ListPrice for the product category AND subcategory in each given row.
-- ProductVsCategoryDelta returns  product's list price, MINUS the average ListPrice for that product’s category.
SELECT 
  ProductName = A.Name,
  A.ListPrice,
  ProductSubcategory = B.Name,
  ProductCategory = C.Name,
  AvgPriceByCategory = avg(ListPrice) OVER(PARTITION BY B.Name,C.Name ),
  ProductVsCategoryDelta = ListPrice-avg(ListPrice) OVER (PARTITION BY C.Name)

FROM Production.Product A
  JOIN Production.ProductSubcategory B
    ON A.ProductSubcategoryID = B.ProductSubcategoryID
  JOIN Production.ProductCategory C
    ON B.ProductCategoryID = C.ProductCategoryID

--ROW_NUMBER() gives us the hability to rank records within our data.
-- It can be applied across the entirer query output .
--ORDER BY in OVER clause is MANDATORY using ROW_NUMBER()

SELECT 
[SalesOrderDetailID],
[SalesOrderID],
[LineTotal],
SalesOrderIDLineTotal = SUM([LineTotal])OVER (PARTITION BY [SalesOrderID]),
Ranking = ROW_NUMBER () OVER (PARTITION BY [SalesOrderID] ORDER BY [LineTotal] DESC)
FROM [Sales].[SalesOrderDetail]

---------------------------------------------------------------------------------------
--Same query as above but removing the partition by.
--That means there are not gonna be groups. that is why the last row of the table will have the same number as the last ranking.

SELECT 
[SalesOrderDetailID],
[SalesOrderID],
[LineTotal],
SalesOrderIDLineTotal = SUM([LineTotal])OVER (PARTITION BY [SalesOrderID]),
Ranking = ROW_NUMBER () OVER (ORDER BY [LineTotal] DESC)
FROM [Sales].[SalesOrderDetail]
ORDER BY 5

--EXERCISE ROW_NUMBER:

SELECT 
  ProductName = A.Name, 
  ProductSubcategory = B.Name,
  ProductCategory = C.Name,
  A.ListPrice,
  CategoryPriceRank = ROW_NUMBER() OVER (PARTITION BY C.Name ORDER BY ListPrice DESC),
  PriceRank = ROW_NUMBER() OVER (ORDER BY ListPrice DESC)

FROM Production.Product A
  JOIN Production.ProductSubcategory B
    ON A.ProductSubcategoryID = B.ProductSubcategoryID
  JOIN Production.ProductCategory C
    ON B.ProductCategoryID = C.ProductCategoryID

--One of the bad things about RowNumber is that rows with same amounts get different rankings.
--¿How do we solve this?
--We have RANK and DENSE_RANK.

--RANK() gives the same number if the rows are tied ans skips the number in between for eg.(1,2,3,3,5,5,7)
SELECT 
[SalesOrderDetailID],
[SalesOrderID],
[LineTotal],
--SalesOrderIDLineTotal = SUM([LineTotal])OVER (PARTITION BY [SalesOrderID]),
Ranking = RANK () OVER (PARTITION BY [SalesOrderID] ORDER BY [LineTotal] DESC)
FROM [Sales].[SalesOrderDetail]

--DENSE_RANK() gives the same number if the rows are tied and DOES NOT skip the number in between for eg.(1,2,3,3,4,4,5)
SELECT 
[SalesOrderDetailID],
[SalesOrderID],
[LineTotal],
--SalesOrderIDLineTotal = SUM([LineTotal])OVER (PARTITION BY [SalesOrderID]),
Ranking = DENSE_RANK () OVER (PARTITION BY [SalesOrderID] ORDER BY [LineTotal] DESC)
FROM [Sales].[SalesOrderDetail]

-- TO SUM UP:

--ROW_NUMBER() gives different ranking even if the results are the same
--RANK()gives the same number if the rows are tied ans skips the number in between.
--DENSE_RANK() gives the same number if the rows are tied and DOES NOT skip the number in between

--WHich one to USE?? It depends. What ever we want.  Apparently ROW_NUMBER() is used more.

--RANK() & DENSE_RANK() exercise:
SELECT 
  ProductName = A.Name, 
  ProductSubcategory = B.Name,
  ProductCategory = C.Name,
  A.ListPrice,
  CategoryPriceRank = ROW_NUMBER() OVER (PARTITION BY C.Name ORDER BY ListPrice DESC),
  PriceRank = ROW_NUMBER() OVER (ORDER BY ListPrice DESC),
  CategoryPriceRankWithRank = RANK() OVER (PARTITION BY C.Name ORDER BY ListPrice DESC),
  CategoryPriceRankWithDenseRank = DENSE_RANK() OVER (PARTITION BY C.Name ORDER BY ListPrice DESC)

FROM Production.Product A
  JOIN Production.ProductSubcategory B
    ON A.ProductSubcategoryID = B.ProductSubcategoryID
  JOIN Production.ProductCategory C
    ON B.ProductCategoryID = C.ProductCategoryID

--LEAD() & LAG()
--They let us grab values from subsequent or previous records relative to the current record in our data.
--They can be useful when we want to comapre a value in a given column to next or previous value in the same COLUMN but side by side in the same ROW.
--VERY USED IN Real-World scenarios.

--Basic LEAD/LAG example

SELECT
       SalesOrderID
      ,OrderDate
      ,CustomerID
      ,TotalDue
	  ,NextTotalDue = LEAD(TotalDue,1) OVER(ORDER BY SalesOrderID)
	  ,Next3TotalDue = LEAD(TotalDue,3) OVER(ORDER BY SalesOrderID)--Compares value in row 1 with value in row 4 
	  ,PrevTotalDue = LAG(TotalDue, 1) OVER(ORDER BY SalesOrderID)
	  ,Prev3TotalDue = LAG(TotalDue, 3) OVER(ORDER BY SalesOrderID)

FROM Sales.SalesOrderHeader

ORDER BY SalesOrderID

--Adding PARTITION BY to LEAD() and LAG()
--ORDER BY at the end by the PARTITIONED column and the ORDER BY column from the window function so have better output

SELECT
       SalesOrderID
      ,OrderDate
      ,CustomerID
      ,TotalDue
	  ,NextTotalDue = LEAD(TotalDue,1) OVER(PARTITION BY CustomerID ORDER BY SalesOrderID)
	  ,PrevTotalDue = LAG(TotalDue, 1) OVER( PARTITION BY CustomerID ORDER BY SalesOrderID)


FROM Sales.SalesOrderHeader

ORDER BY CustomerID,SalesOrderID --In the query look at the CustomerID groups for better understanding

--LEAD() & LAG() exercises

SELECT 
	   PurchaseOrderID
	  ,EmployeeID
      ,OrderDate 
	  ,VendorName = B.Name
	  ,TotalDue	  
      ,PrevOrderFromVendorAmt = LAG(A.TotalDue) OVER(PARTITION BY A.VendorID ORDER BY A.OrderDate)
	  ,NextOrderByEmployeeVendor = LEAD(B.Name) OVER(PARTITION BY A.EmployeeID ORDER BY A.OrderDate)
	  ,Next2OrderByEmployeeVendor = LEAD(B.Name,2) OVER(PARTITION BY A.EmployeeID ORDER BY A.OrderDate)
  FROM Purchasing.PurchaseOrderHeader A
  JOIN Purchasing.Vendor B
    ON A.VendorID = B.BusinessEntityID

  WHERE YEAR(A.OrderDate) >= 2013
	AND A.TotalDue > 500
	
	ORDER BY EmployeeID,OrderDate