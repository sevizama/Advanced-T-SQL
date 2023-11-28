-- Improved EXISTS with UPDATE
--However, if you need to see any data points pertaining to the match, UPDATE can be a superior alternative to EXISTS.
--Use exists if you dont wanna see all matches from the many side, and dont care to see any information about those matches(other than their existence), EXISTS is fine
create table #ProductsSold2012
(
SalesOrderID INT,
OrderDate DATE,
LineTotal MONEY,
ProductID INT
)

INSERT INTO #ProductsSold2012
(
SalesOrderID,
OrderDate
)

SELECT 
SalesOrderID,OrderDate
from [Sales].[SalesOrderHeader]
Where YEAR(OrderDate) = 2012

select * from #ProductsSold2012

--Lets try to update the null fields.
--Keep in mind there is a one to many relationships between the sales order data and our temp table and the line level data in our sales.orderdetail in which each orders constituen items are listed
--After runnong the update the number of rows stayed the same. What happened when there were multiple line items in the sales order detail table for a single sales order in our temp table
--Well, in that case, the update simply grabbed one matching record from the miniside and updated our temp table with that.
--If you only want to see a single amtch and arent particular about which match is chosen, this can be a good strategy
UPDATE #ProductsSold2012
SET
LineTotal= b.LineTotal,
ProductID=b.ProductID
from #ProductsSold2012 as a
join [Sales].[SalesOrderDetail] as b
on a.SalesOrderID = b.SalesOrderID
----
--Aqui recordamos un poco como funcionaba exists
select [SalesOrderID],[OrderDate],[TotalDue]
from [Sales].[SalesOrderHeader] as a
where exists
(SELECT 'Hello World' from [Sales].[SalesOrderDetail] as b
where a.[SalesOrderID] = b.[SalesOrderID] and LineTotal >1000)
order by 1


CREATE TABLE #Sales
(
SalesOrderID INT,
OrderDate DATE,
TotalDue MONEY,
LineTotal MONEY
)

INSERT INTO #Sales
(
SalesOrderID,
OrderDate,
TotalDue
)
SELECT 
SalesOrderID,
OrderDate,
TotalDue
FROM [Sales].[SalesOrderHeader]

Select * from #Sales WHERE LineTotal is not null


UPDATE #Sales
SET
LineTotal = b.LineTotal
FROM #Sales as a
join [Sales].[SalesOrderDetail] as b
on a.[SalesOrderID] = b.[SalesOrderID]
where B.LineTotal >10000
--Now, only sales orders that have an associated line item with a line total greater than 10k should be updated.
--But because we´re using an update, there is no possibility of our sales order data being duplicated.
--A single order will be updated with at most information from a single line item