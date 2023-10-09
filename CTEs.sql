--CTE´S

--Subqueries are good we need only a 2 step query but what if we need 3 or more? Use CTEs
--They allow us to express multi-stage data transformations in a linear step by step.

--Lets try to identify the top 10 sales orders per month and sum those up.
--Then compare the sum of the 10 biggest sales orders per month against the same total for the previous month.

--1st lets try with subqueries:



--Since we are going not only to group the data by month, but also trying records by the current month vs previous month
--We will ned a field in our data that identifies the month of a given sales order date. 
--For that we will use the date from parts function, that parts out the first date  of the month for any sales order date

SELECT OrderDate,
		TotalDue,
		OrderMonth = DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1)--The 1 is to get the first day of the month
from [Sales].[SalesOrderHeader]

--Next we need to rank all of our sales orders by the totalDue, but do this in groups, defined by months
SELECT OrderDate,
		TotalDue,
		OrderMonth = DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1),--The 1 is to get the first day of the month
		OrderRank = ROW_NUMBER() OVER (PARTITION BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1) ORDER BY TotalDue DESC)
from [Sales].[SalesOrderHeader]

--We need to make use of a subquery now to get our top ten sales sales order per month.
--So what we have until now will be a subquery and we will add the condition <= 10 for the top 10 in each month
SELECT
*
FROM
(
SELECT OrderDate,
		TotalDue,
		OrderMonth = DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1),--The 1 is to get the first day of the month
		OrderRank = ROW_NUMBER() OVER (PARTITION BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1) ORDER BY TotalDue DESC)
from [Sales].[SalesOrderHeader]
) as A
WHERE OrderRank <= 10

--Now we also want to have the sum of the TOP10 orders per months and group those totals by month.
SELECT
OrderMonth,
Top10SalesAmount = SUM(TotalDue)
FROM
(
SELECT OrderDate,
		TotalDue,
		OrderMonth = DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1),--The 1 is to get the first day of the month
		OrderRank = ROW_NUMBER() OVER (PARTITION BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1) ORDER BY TotalDue DESC)
from [Sales].[SalesOrderHeader]
) as A
WHERE OrderRank <= 10
group by OrderMonth

--Now we have what we want for the current month but we need to compare this to itself in the previous month.
--For this we are gonna have to compare this table to itself


SELECT
A.OrderMonth,
A.Top10SalesAmount,
PrevTop10Total = b.Top10SalesAmount
FROM
(
SELECT
OrderMonth,
Top10SalesAmount = SUM(TotalDue)
FROM
(
SELECT OrderDate,
		TotalDue,
		OrderMonth = DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1),--The 1 is to get the first day of the month
		OrderRank = ROW_NUMBER() OVER (PARTITION BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1) ORDER BY TotalDue DESC)
from [Sales].[SalesOrderHeader]
) as A
WHERE OrderRank <= 10
group by OrderMonth
) as A
LEFT JOIN --Left join so if there is no previous month, instead of no recording returning at all we simply have a null
(
SELECT
OrderMonth,
Top10SalesAmount = SUM(TotalDue)
FROM
(
SELECT OrderDate,
		TotalDue,
		OrderMonth = DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1),--The 1 is to get the first day of the month
		OrderRank = ROW_NUMBER() OVER (PARTITION BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1) ORDER BY TotalDue DESC)
from [Sales].[SalesOrderHeader]
) as A
WHERE OrderRank <= 10
group by OrderMonth
) as B ON A.OrderMonth = DATEADD(MONTH, 1, B.OrderMonth)--So what this is basically doing is saying join my subquery in B subquery such that the order month in my A subquery is equal to the order month in my B subquery plus and additional month

ORDER BY OrderMonth

--Now lets see how CTE´s can help us solve this problem in a more cleaner more linear way and with less code.

--All CTE´s start with WITH, and then specify a name for the virtual table that we will be coding.
--They work in a more subsequent way
--Lets grab our first innest table.
-- This is the basic format of the cte
WITH Sales AS
(
SELECT OrderDate,
		TotalDue,
		OrderMonth = DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1),--The 1 is to get the first day of the month
		OrderRank = ROW_NUMBER() OVER (PARTITION BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate),1) ORDER BY TotalDue DESC)
from [Sales].[SalesOrderHeader]
),

Top10 AS (
SELECT
OrderMonth,
Top10SalesAmount = SUM(TotalDue)
FROM Sales
WHERE OrderRank <= 10
group by OrderMonth
)
SELECT
A.OrderMonth,
A.Top10SalesAmount,
PrevTop10Total = b.Top10SalesAmount

FROM TOP10 as A
	LEFT JOIN Top10 as B
	On A.OrderMonth = DATEADD(MONTH,1,B.OrderMonth)

ORDER BY OrderMonth

--EXERCISE. Transform this messy code into a CTE

SELECT
A.OrderMonth,
A.TotalSales,
B.TotalPurchases

FROM (
	SELECT
	OrderMonth,
	TotalSales = SUM(TotalDue)
	FROM (
		SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM Sales.SalesOrderHeader
		) S
	WHERE OrderRank > 10
	GROUP BY OrderMonth
) A

JOIN (
	SELECT
	OrderMonth,
	TotalPurchases = SUM(TotalDue)
	FROM (
		SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM Purchasing.PurchaseOrderHeader
		) P
	WHERE OrderRank > 10
	GROUP BY OrderMonth
) B	ON A.OrderMonth = B.OrderMonth

ORDER BY 1

-----------------------------------
WITH Sales AS
(
SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
FROM Sales.SalesOrderHeader
)

,SalesMinusTop10 AS
(
SELECT
OrderMonth,
TotalSales = SUM(TotalDue)
FROM Sales
WHERE OrderRank > 10
GROUP BY OrderMonth
)

,Purchases AS
(
SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
FROM Purchasing.PurchaseOrderHeader
)

,PurchasesMinusTop10 AS
(
SELECT
OrderMonth,
TotalPurchases = SUM(TotalDue)
FROM Purchases
WHERE OrderRank > 10
GROUP BY OrderMonth
)


SELECT
A.OrderMonth,
A.TotalSales,
B.TotalPurchases

FROM SalesMinusTop10 A
	JOIN PurchasesMinusTop10 B
		ON A.OrderMonth = B.OrderMonth

ORDER BY 1

--RECURSIVE CTE´S.
--We are gonna tackle series of numbers, series of numbers.


--Lets try to generate a series from 1 to 100.

--First lets try to divide our query in 3 parts:
--The anchor member which is the part of the query on which the rest of the code is built upon which has to be a select.

SELECT 1 AS MyNumber

--The 2nd part is the recursive member, is where things get kind of weird.
--Dont need to understand the logic , this like a template.
--1st we have the anchor member, then UNION ALL, and then the recursive member which references the definition of the virtual table itself.
--and increments that field in the anchor member by some amount.

WITH NumberSeries AS
(
SELECT 1 AS MyNumber

UNION ALL

SELECT
MyNumber +1
FROM NumberSeries
WHERE MyNumber < 100
)

--So the last step here, as with any other CTE, will be to write the select stament that will generate our final output below our virtual table definition.

SELECT MyNumber
FROM NumberSeries

--Now, lets try to use this to generate a series of all dates in the year 2021.

WITH DateSeries AS
(
    SELECT CAST('2021-01-01' AS DATE) AS MyDate

    UNION ALL

    SELECT DATEADD(DAY, 1, MyDate) 
    FROM DateSeries
    WHERE MyDate < CAST('2021-12-31' AS DATE) 
)

SELECT MyDate
FROM DateSeries
OPTION (MAXRECURSION 365);

--EXERCISE:
--Use a recursive CTE to generate a list of all odd numbers between 1 and 100.
WITH NumberSeries AS
(
SELECT 1 AS MyNumber

UNION ALL

SELECT
MyNumber +2
FROM NumberSeries
WHERE MyNumber < 100
)
SELECT MyNumber
FROM NumberSeries

--Use a recursive CTE to generate a date series of all FIRST days of the month (1/1/2021, 2/1/2021, etc.)
WITH DateSeries AS
(
    SELECT CAST('2021-01-01' AS DATE) AS MyDate

    UNION ALL

    SELECT DATEADD(MONTH, 1, MyDate) 
    FROM DateSeries
    WHERE MyDate < CAST('2021-12-31' AS DATE) 
)

SELECT MyDate
FROM DateSeries
OPTION (MAXRECURSION 365);