--Indexes, is another optimization technique.
--Also they are one of the main advantages of temp tables vs CTEs and subqueries since temp tables can be indexed and CTEs and subqueries cannot.
--Index can make queries faster by sorting the data in the fields they apply to-either in the table itself, or in a separate data structure.
--These basically define 2 different types of indexes.
--This sorting allows the database engine to locate records within a table without having to search through the table row-by-row.
--No, those 2 types of indexesare called clustered and non-clustered indexes.
--Clustered indexes. The rows of a table with a clustered index are physically sorted based on the field or fields the index is applied to.
--So if you have a clustered index on salesorderID the rows of data in that table are going to be sorted based on that field.
--A table with a primary key is given a clustered index(based on the primary key field) by default.
--In the SalesOrderDetail table we can notice that SalesOrderID and SalesOrderDetailID have the abbreviation PK.
--this means that this table has a compound pk, which means that (in this canse) these 2 fields when combined uniquely identify a row of data withun that table.
--So salesorderID  plus salesorderdetailID comprise the primary key of the table.
--if we go to the indexes tab, basically that primary key is comprised of salesorderdetailID and salesorderID and it is also a clustered index.
--Most tables should have at least a clustered index, as queries against tables with a clustered index generally tend to be faster.
--A table may only have one clustered index, so if you want more than one index on your table, you will have to resort to adding non-clustered indexes.


--CLUSTERED INDEXES (STRATEGIES):
--Apply clustered index to whatever field -or fields - are most likely to be used in a join againts the table.
--Ideally this field (or combination of fields) should also be the one that most uniquely defines a record in the table.
--If a field would be a good candidate for a primary key of a table, is usually also a good candidate for a clustered index.

--NON-clustered INDEXES_
--a Table may have many non_clustered indexes.
--Non-clustered indexes do not physically sort the data in a table like clustered indexes do you cant sort a table by 5 different indexes.
--The sorted order of the field or fields non-clustered indexes apply to is sorted in an external data structure, which works like a kind of phone book.


--NON-Clustered Indexes: Strategies
--If you will be joining your table on fields besides the one "covered" by the clustered index, consider non-clustered indexes on those fields.
--So lets say you pick your clustered index on SalesOrderID, but you are going to be joining that table on some other field down the road.
--In that case, you may want to put a non-clustered index on that  other field.
--You can add as many non-clustered indexes as you want, but you should be judicious when doing this and not just go crazy in your database and add a non-clustered index to every field.
--Fields covered by a non-clustered index should still have a high level of uniqueness. (a field like a first name would be good because names like John,Tom, Maria are repeated a lot).


--INDEXES(HOW DO WE APPROACH THEM):
--It´s how our table utilized in joins that should drive our use and design of indexes.
--So you should generally add a clustered index first, and then layer in non-clustered indexes as needed to cover additional fields used in joins against our table.
--Now indexes take up memory in the database, so you should only add them if they´re actually needed.
--They also make inserts t tables take longer so you should generally, add indexes afterdata has been inserted to the table.

--1)CREATE FILTERED TEMP TABLE OF SALES ORDER HEADER WHERE year = 2012
CREATE TABLE #Sales2012
(
SalesOrderID INT,--If we look at later parts of this proyect we can see this will be used in joins, so its a good candidate for clustered index, but remember, you generally want to put the index on after you have inserted the data
OrderDate DATE
)

INSERT INTO #Sales2012
(
SalesOrderID,
OrderDate
)
SELECT SalesOrderID, OrderDate
FROM [Sales].[SalesOrderHeader]
where YEAR(OrderDate) = 2012


--This how you create one creaate cluster index
CREATE CLUSTERED INDEX Sales2012_idx ON #Sales2012(SalesOrderID)

--2)Create a ne temp table after joining in SalesOrderDetail table
CREATE TABLE #ProductsSold2012
(
SalesOrderID INT,
SalesOrderDetailID INT,
OrderDate DATE,
LineTotal MONEY,
ProductID INT,
ProductName VARCHAR(64),
ProductSubcategoryID INT,
ProductSubcategory VARCHAR(64),
ProductCategoryID INT,
ProductCategory VARCHAR(64)
)
INSERT INTO #ProductsSold2012
(
SalesOrderID,
SalesOrderDetailID,
OrderDate,
LineTotal,
ProductID
)

SELECT 
	   A.SalesOrderID
	  ,B.SalesOrderDetailID
	  ,A.OrderDate
      ,B.LineTotal
      ,B.ProductID

--Because of this join we are gonna have multiple LineTotals for the same order
--So maybe insted of stablishing clustered index on 
FROM #Sales2012 A
	JOIN Sales.SalesOrderDetail B
		ON A.SalesOrderID = B.SalesOrderID

CREATE CLUSTERED INDEX ProductsSold2012_idx ON #ProductsSold2012(SalesOrderID,SalesOrderDetailID)

--3.) Add product data with UPDATE

UPDATE A
SET
ProductName = B.[Name],
ProductSubcategoryID = B.ProductSubcategoryID

FROM #ProductsSold2012 A
	JOIN Production.Product B
		ON A.ProductID = B.ProductID


--No podemos crear mas de un clustered index, asi que estos tienen que ser non-clustered
CREATE NONCLUSTERED INDEX ProductsSold2012_idx2 ON #ProductsSold2012(ProductID)


--4.) Add nonclustered index on product subcategory ID

UPDATE A
SET
ProductSubcategory= B.[Name],
ProductCategoryID = B.ProductCategoryID

FROM #ProductsSold2012 A
	JOIN Production.ProductSubcategory B
		ON A.ProductSubcategoryID = B.ProductSubcategoryID

CREATE NONCLUSTERED INDEX ProductsSold2012_idx3 ON #ProductsSold2012(ProductSubcategoryID)


--5) Add nonclustered index on category Id
UPDATE A
SET
ProductCategory= B.[Name]

FROM #ProductsSold2012 A
	JOIN Production.ProductCategory B
		ON A.ProductCategoryID = B.ProductCategoryID

CREATE NONCLUSTERED INDEX ProductsSold2012_idx4 ON #ProductsSold2012(ProductCategoryID)


SELECT * FROM #ProductsSold2012