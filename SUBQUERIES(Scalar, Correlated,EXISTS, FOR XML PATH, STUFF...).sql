--SUBQUERIES

--WHEN TO USE THEM? When you wanna include aggregate calculations directly in your where clause, scalar subqueries are the way to go.
--Subqueriesare the best for 2 step queries- For 3 or more gets confusing, there are other methods.
--Remind of Window Functions. This query ranks the items within each salesorderID ordered by lined total.
--It is gonna be the subquery of the total query later on.

select [SalesOrderID],
		[SalesOrderDetailID],
		[LineTotal],
		LineTotalRanking = ROW_NUMBER() OVER(PARTITION BY [SalesOrderID] ORDER BY [LineTotal] DESC)
	 
FROM [Sales].[SalesOrderDetail]

--But what if we just wanted to see the single record with the highest LineTotal per each order? (All the 1 Ranking rows)
--if we tried to add the row_number...statement to a where clause like this:
-- WHERE ROW_NUMBER() OVER(PARTITION BY [SalesOrderID] ORDER BY [LineTotal] DESC) is gonne be an ERROR.
--Because Window functions can only be applied to SELECT and ORDER BY clauses.
--So..¿How do we apply criteria to the fields that we generate with our window functions? With SUBQUERIES  
--Subqueries is an inner query that is nested within and then referred to by an outer query.
--We are essentially defining a kind of virtual table in one SELECT query and then referring to that table in our outer query.

SELECT
*
FROM

(
select [SalesOrderID],
		[SalesOrderDetailID],
		[LineTotal],
		LineTotalRanking = ROW_NUMBER() OVER(PARTITION BY [SalesOrderID] ORDER BY [LineTotal] DESC)
	 
FROM [Sales].[SalesOrderDetail]
)as A --Really important to alias or subquery, otherwise we will get an error

WHERE LineTotalRanking = 1

--EXERCISE 

SELECT
*
FROM
(
SELECT [PurchaseOrderID],[VendorID],[OrderDate],[TaxAmt],[Freight],[TotalDue],
Most_Expensive  = ROW_NUMBER() OVER (PARTITION BY [VendorID] ORDER BY [TotalDue])

FROM [Purchasing].[PurchaseOrderHeader]
) as A
WHERE Most_Expensive <=3

--Return the orders with the same totaldue amount as long they are on the top three
SELECT
*
FROM
(
SELECT [PurchaseOrderID],[VendorID],[OrderDate],[TaxAmt],[Freight],[TotalDue],
Most_Expensive  = DENSE_RANK() OVER (PARTITION BY [VendorID] ORDER BY [TotalDue])

FROM [Purchasing].[PurchaseOrderHeader]
) as A
WHERE Most_Expensive <=3


--SCALAR SUBQUERIES.
--SCALAR means Single Value, so in SQL it means a single row with a single column.
--We can incluse such a number alongside other fields in our select clause.
--Most of the subqueries in the from clause need to be aliased and most of other subqueries do not.

SELECT [ProductID],[Name],[StandardCost],[ListPrice],
		AvgListPriceDiff = [ListPrice]-(SELECT AVG([ListPrice]) FROM [Production].[Product])
FROM [Production].[Product]
WHERE [ListPrice]-(SELECT AVG([ListPrice]) FROM [Production].[Product]) >0
ORDER BY [ListPrice]

--EXERCISE. Return the percent an individual employees' vacation hours are, of the maximum vacation hours for any employee. 
SELECT [BusinessEntityID],[JobTitle],[VacationHours],
	PercentageMaxVacationHours = [VacationHours]*1.0/(SELECT MAX([VacationHours]) FROM [HumanResources].[Employee]),
	MaxVacationHours = (SELECT MAX([VacationHours]) FROM [HumanResources].[Employee])
FROM [HumanResources].[Employee]

--CORRELATED SUBQUERIES
--Subqueries that run once for each record in the main or outer query and return a single value for that record.
--They are connected to the outter table by a common field. (almost like a join)
--Can be included in either the select clause or the where clause and have different application in each.


--Lets say that for each salesorder we would like to see a count of thetimes within that order that had a quantity > 1.
--1st we develop our subquery which is gonna try to get the count of records for certain SalesOrderId.
select count(*)
from [Sales].[SalesOrderDetail] as a
where a.[SalesOrderID] = 43659  and [OrderQty] >1

--2nd we incorporate it in the select from the outer query. (dont forget the aliases)
select [SalesOrderID],
		[OrderDate],
		[SubTotal],
		[TaxAmt],
		[Freight],
		[TotalDue],
		MultiOrderCount = (select count(*)
from [Sales].[SalesOrderDetail] as a
where a.[SalesOrderID] = b.[SalesOrderID] and [OrderQty] >1)
from	[Sales].[SalesOrderHeader] as b


--EXERCISE Add a derived column  NonRejectedItems which returns: 
--for each purchaseorderID the number of line items from the Purchasing.PurchaseOrderDetail  which did not have any rejections (i.e., RejectedQty = 0)

--1st STEP: We write the subquery for a certain PurchaseOrderID
SELECT COUNT(*) AS NumberLineTotals
FROM [Purchasing].[PurchaseOrderDetail]
WHERE [PurchaseOrderID] = 5 AND [RejectedQty] =0

--2nd: We include the subquery in the outer query in the derived column.
SELECT 
[PurchaseOrderID],
[VendorID],
[OrderDate],
[TotalDue],
NonRejectedItems = (SELECT COUNT(*) AS NumberLineTotals
FROM [Purchasing].[PurchaseOrderDetail] AS A
WHERE A.[PurchaseOrderID] = B.[PurchaseOrderID] AND [RejectedQty] =0)

FROM [Purchasing].[PurchaseOrderHeader] AS B

--EXERCISE: nclude a second derived field called MostExpensiveItem.
--This field should return, for each purchase order ID, the UnitPrice of the most expensive item for that order in the Purchasing.PurchaseOrderDetail table.

--1st STEP: We write the subquery for a certain PurchaseOrderID
SELECT MAX([UnitPrice]) AS MaxPrice
FROM [Purchasing].[PurchaseOrderDetail]
WHERE [PurchaseOrderID] = 4 AND [RejectedQty] =0

--2nd: We include the subquery in the outer query in the derived column.
SELECT 
[PurchaseOrderID],
[VendorID],
[OrderDate],
[TotalDue],
MostExpensiveItem = (SELECT MAX([UnitPrice]) AS NumberLineTotals
FROM [Purchasing].[PurchaseOrderDetail] AS A
WHERE A.[PurchaseOrderID] = B.[PurchaseOrderID] AND [RejectedQty] =0)

FROM [Purchasing].[PurchaseOrderHeader] AS B


--EXISTS.
--Which allows us to make use of correlated subqueries in the where clause.
--EXISTS are useful in one to many relationship,  run both queries below at the same time.
SELECT * FROM [Sales].[SalesOrderHeader] WHERE [SalesOrderID] = 43683
SELECT * FROM [Sales].[SalesOrderDetail] WHERE [SalesOrderID] = 43683

--So lets say when want to see all cystomer orders that have at least one item with a LineTotal of more than 10k.
--So here, for every record in the outer query for each of these 31465 records, SQL is going to take that sales order ID for the record
--and scan the salesorderdetail table and scan the salesorderdetail table via our subquery here and see if there is at least one match such that the lineTotal is greater than 10k

SELECT A.[SalesOrderID],
		A.[OrderDate],
		A.[TotalDue]

FROM [Sales].[SalesOrderHeader] as A
WHERE EXISTS(									--Exists doesnt return data, just looks for matches in a secondary table
				SELECT 1						--this 1 does not mean anything, people just put this.
				FROM [Sales].[SalesOrderDetail] B
				WHERE B.[LineTotal] > 10000
				AND A.SalesOrderID = B.SalesOrderID
				)
ORDER BY A.[SalesOrderID]

--Can obtain the opposite with NOT EXISTS
SELECT A.[SalesOrderID],
		A.[OrderDate],
		A.[TotalDue]

FROM [Sales].[SalesOrderHeader] as A
WHERE NOT EXISTS(									--Exists doesnt return data, just looks for matches in a secondary table
				SELECT 1						--this 1 does not mean anything, people just put this.
				FROM [Sales].[SalesOrderDetail] B
				WHERE B.[LineTotal] > 10000
				AND A.SalesOrderID = B.SalesOrderID
				)
ORDER BY A.[SalesOrderID]

--If we check the SalesOrderID 43659. We will see that non of the records has a LineTotal of 10k or more
SELECT * FROM [Sales].[SalesOrderDetail] WHERE [SalesOrderID] = 43659

--USE EXISTS IF: 
--you want to apply criteria to fields from a secondary table, but dont need to include those fields in your output.
--You want to apply criteria to fields from a secondary table, while ensuring that multiple matches in the secondary table wont duplicate data from the primary table in your output.
--You need to check a secondary table to make sure a match of some type does NOT exist

--EXERCISE: Select all records from the Purchasing.PurchaseOrderHeader such that there is at least one item in the order with an order quantity greater than 500

SELECT A.*
FROM [Purchasing].[PurchaseOrderHeader] as A
WHERE EXISTS(
	SELECT 1
	FROM [Purchasing].[PurchaseOrderDetail] AS B
	WHERE [OrderQty]>500 AND [UnitPrice] > 50
	AND A.[PurchaseOrderID] = B.[PurchaseOrderID]
	)
ORDER BY A.[PurchaseOrderID]

--Select all records from the Purchasing.PurchaseOrderHeader table such that NONE of the items within the order have a rejected quantity greater than 0.
SELECT A.*
FROM [Purchasing].[PurchaseOrderHeader] as A
WHERE NOT EXISTS(
	SELECT 1
	FROM [Purchasing].[PurchaseOrderDetail] AS B
	WHERE [RejectedQty] >0
	AND A.[PurchaseOrderID] = B.[PurchaseOrderID]
	)
ORDER BY A.[PurchaseOrderID]

--FOR XML WITH STUFF for flattening
--imagine we have a column line total and we want 3 row values in the same row like this : 50,53,456,31

--1Step. This will return some XML output
SELECT [LineTotal]
FROM [Sales].[SalesOrderDetail] as A
WHERE A.SalesOrderDetailID = 43659
FOR XML PATH('')

--2Step: we need to get rid of the XML logs, we and separator mas be a ',' and concatenate that to LineTotal
SELECT
',' + CAST(LineTotal as VARCHAR)
FROM [Sales].[SalesOrderDetail] as A
WHERE A.SalesOrderDetailID = 43659
FOR XML PATH('')

--3Step: At this point we have to get rif of the coma at the beginning and for taht we have the stuff funcion.
--The query we have to far is gonna be one of its arguments
SELECT
STUFF(
(SELECT
',' + CAST(CAST(LineTotal AS Money) as VARCHAR)
FROM [Sales].[SalesOrderDetail] as A
WHERE A.SalesOrderDetailID = 43659
FOR XML PATH('')
),1,--This argument means that we want to stuff our XML text starting in position 1
1,--This tells SQL how many characters  we want to clip off from the text in our first argument. (We wanna get rid of the first ',', so thats why its 1)
'')--space to put in quotes.
FROM[Sales].[SalesOrderHeader] AS B

--4rd step we include this a subquery in an outer query.
SELECT [SalesOrderID],[OrderDate],[SubTotal],[TaxAmt],[Freight],[TotalDue],
		LineTotals = STUFF(( SELECT
							',' + CAST(CAST(LineTotal AS Money) as VARCHAR)
							FROM [Sales].[SalesOrderDetail] as A
							WHERE A.[SalesOrderID] =  B.[SalesOrderID]
							FOR XML PATH('')
							),1,1,'')

FROM [Sales].[SalesOrderHeader] AS B

--EXERCISE 
--1Step. This will return some XML output

SELECT Name
FROM [Production].[Product]
WHERE [ProductSubcategoryID] = 11
FOR XML PATH('')

--2Step: we need to get rid of the XML logs, we and separator mas be a ',' and concatenate that to LineTotal

SELECT 
',' + Name
FROM [Production].[Product]
WHERE [ProductSubcategoryID] = 11
FOR XML PATH('')

--3Step: At this point we have to get rif of the coma at the beginning and for taht we have the stuff funcion.
--The query we have to far is gonna be one of its arguments
SELECT 
STUFF((
SELECT 
',' + Name
FROM [Production].[Product]
WHERE [ProductSubcategoryID] = 11
FOR XML PATH('')),
1,
1,
'')
FROM [Production].[ProductSubcategory]

--4rd step we include this a subquery in an outer query.
SELECT B.Name as SubcategoryName,
Products = STUFF((
SELECT 
',' + Name
FROM [Production].[Product] as A
WHERE A.[ProductSubcategoryID] = B.[ProductSubcategoryID]
FOR XML PATH('')),
1,
1,
'')
FROM [Production].[ProductSubcategory] as B

--FLATTEN WITH PIVOT.
--Lets imagine we have multiple records, with the same sales orderID and various line totals.
--Pivot would give us a column for each unique sales order ID and our sales

SELECT Bikes, Clothing, Accessories, Components--This columns must be the same ones that appear at the IN function in PIVOT
												--We can use SELECT * as well
FROM
(
SELECT
	   ProductCategoryName = D.Name,
	   A.LineTotal

FROM Sales.SalesOrderDetail A
	JOIN Production.Product B
		ON A.ProductID = B.ProductID
	JOIN Production.ProductSubcategory C
		ON B.ProductSubcategoryID = C.ProductSubcategoryID
	JOIN Production.ProductCategory D
		ON C.ProductCategoryID = D.ProductCategoryID
) as A

PIVOT(
SUM(LineTotal)
FOR ProductCategoryName IN(Bikes, Clothing, Accessories, Components) --In IN we have to specify which values we want to see in our output
) as B--Here we think which column in our data has the categorical output(which type of values would help us slice and dice and filter our data)


--EXERCISE 
SELECT *
FROM
(
SELECT [Gender],[JobTitle],VacationHours
FROM [HumanResources].[Employee]
) as A
PIVOT(
AVG(VacationHours)
FOR JobTitle IN([Sales Representative],[Buyer],[Janitor])
) B