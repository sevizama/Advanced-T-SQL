--What usually slow queries down? A lot of things but usually joins between large tables(millions or hundreds of million of records).
--What can we do? First Define a filtered dataset as early as possiblein our process, wso we can JOIN additional tables to a smaller core population.

--So if you know you have some kind of limiting criteria that limits the scope of the data, establish a TEMP TABLE as early in your process as you can
--That way we can join additional tables to a smaller core population

--Avoid several JOINS in a single SELECT query, especially those involving large tables.
--We can bring different fields from other tables with update statments, to populate fields in a temp table, one source at a time.
--These update stament will actually update our target table based on values in another table.


--Why is updating a table based on values in another table faster than joining them? The simple answer is that the update statment will just grab the first matching value it finds from
--the secondary table and then populate the corresponding record in our target table.
--By contrast, direct joins between tables can requiere the secondary table to be fully scanned by the database even a match has been found, because the possibility of additional matches exists.

--Also we can apply indexes to fields, which makes looking updata in a table faster. 
--By applying indexes to fields in our temp tables that will later be used in joins, we can spped those joins up.

--Starter Code: (Lets optimize)

SELECT 
	   A.SalesOrderID
	  ,A.OrderDate
      ,B.ProductID
      ,B.LineTotal
	  ,C.[Name] AS ProductName
	  ,D.[Name] AS ProductSubcategory
	  ,E.[Name] AS ProductCategory


FROM Sales.SalesOrderHeader A
	JOIN Sales.SalesOrderDetail B
		ON A.SalesOrderID = B.SalesOrderID
	JOIN Production.Product C
		ON B.ProductID = C.ProductID
	JOIN .Production.ProductSubcategory D
		ON C.ProductSubcategoryID = D.ProductSubcategoryID
	JOIN Production.ProductCategory E
		ON D.ProductCategoryID = E.ProductCategoryID

WHERE YEAR(A.OrderDate) = 2012

--Step1 (We filter the data by our condition of the year)
CREATE TABLE #Sales2012
(
SalesOrderID INT,
OrderDate DATE
)
Insert into #Sales2012
(
SalesOrderID,
OrderDate
)
select A.SalesOrderID,A.OrderDate
from  Sales.SalesOrderHeader as A
Where YEAR(OrderDate) = 2012

--Step 2 (create our master temp table thats going to house all fields that we will need in our output)

CREATE TABLE #ProductsSold2012
(
	   SalesOrderID INT
	  ,OrderDate DATE
	  ,LineTotal MONEY
      ,ProductID INT
	  ,ProductName VARCHAR(50)
	  ,ProductSubcategoryid INT 
	  ,ProductSubcategory VARCHAR(50)
	  ,ProductCategoryID INT
	  ,ProductCategory VARCHAR(50)
)


--Primero insertamos los valores de #Sales2012

INSERT INTO #ProductsSold2012
(
	   SalesOrderID 
	  ,OrderDate 
	  ,LineTotal 
	 ,ProductID
)
SELECT 
	   A.SalesOrderID 
	  ,A.OrderDate
	  ,B.LineTotal 
      ,B.ProductID 
FROM #Sales2012 AS A
JOIN [Sales].[SalesOrderDetail] AS B
	ON A.[SalesOrderID] = B.[SalesOrderID]


--Lo que hemos hecho hasta ahora es hacer un join mas barato porque nuestra #Sales2012 tiene solo valores de ese año
--Para este proceso hasta ahora hemos necesitado. 1.La temp table filtrada de nuestra tabla principal.
--2.La temp table final creada donde migramos los datos. Luego 3 al insertar hacemos el join de la temp table filtrada con la tabla normal de SalesOrderHeader.

SELECT * FROM #ProductsSold2012

--Hasta ahora hemos insertado 4 campos en nuestra tabla final. El resto lo haremos via update statemtn.
--Darse cuenta que nuestra tabla tiene mas records que nuestra #Sales2012 table. Eso es por los joins 1 a muchos.


--Step 3: Now we are gonna populate the ProductName column, based on the product name on the production product table.
UPDATE A --Hemos hecho el alias #ProductsSold2012 AS A
SET 
ProductName = B.Name,
ProductSubcategoryid = B.ProductSubcategoryID--Si primero añadimos el primer update del name,corremos el query, luego el del subcategory id no pasa nada. No es como insert donde acabarian duplicados.
FROM #ProductsSold2012 AS A
join  Production.Product B
	ON A.ProductID = B.ProductID


SELECT * FROM #ProductsSold2012

--When you are populating fields in a temp table with updates like this, this is a consideration you´ll have to keep in mind.
--What fields do i have to have in my temp table so that i can join my temp table to some other table out to some other table to grab the secondary value.
update #ProductsSold2012
SET ProductSubcategory = B.Name,
ProductCategoryID = B.ProductCategoryID
FROM #ProductsSold2012 AS A
JOIN Production.ProductSubcategory B
	ON A.ProductSubcategoryID = B.ProductSubcategoryID

	
SELECT * FROM #ProductsSold2012

--The final Product Category Update
update #ProductsSold2012
SET 
ProductCategory = B.Name
FROM #ProductsSold2012 AS A
	JOIN Production.ProductCategory B
		ON A.ProductCategoryID = B.ProductCategoryID

SELECT * FROM #ProductsSold2012

--And finally we have the same result as our initial joins but we a couple of updates.
--I would consider this a tool to break once a query or a bit of code has proven that it needs some help to run faster