--VIEW is essentially a virtual table based on the result set of a SQL query.
--It contains rows and columns just like a real table, and thats because the fields are jsut fields from one more real tables in the database,
--possibly combined with derived columns, just like the derived columns you might include in a SQL query.
--With views you can incorporate all the SQL tricks in your toolkit. Built int functions, join case statements, window functions and so on into a query.
-- but then make the query results available to other analysts as if the data was coming from a single table. So lets drill down a little deeper into why views are useful.
--Views can simplify the use of a database, especially from an analyst perspective, by joining multiple tables and combining different fields from those tables, then presenting them as a single table.
-- This can be particularly useful for users who might not know how to write complex queries or who might not be familiar with how the tables in that particular dv are related and thus not know how to join them together.
--A second benefit to views is consistent logic. If there is a specific calcualtion or transformation you are doing on your data regularly, you can embed that logic in a view.
--This ensures consistency as you dont have to re-write thatlofic everytime you need it.
--And there is query abstraction. So if changes are made to your database, like for example, changing the structure of various tables, you can modify the queries underlying your views to make sure they keeo the same structure, which means
--that any applications or reports that rely on those views might not need to change.
--So generally speaking, the queries that we encapsulate with views tend to be on the complicated side.
--Thats why we are crating the view to beging with, to spare other analyst from having to know how to put together and especially involvedd query.

--Creating the view:

CREATE VIEW Sales.vw_SalesRolling3Days AS --standard naming convention to start views with vw

SELECT
    OrderDate,
    TotalDue,
	SalesLast3Days = SUM(TotalDue) OVER(ORDER BY OrderDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
FROM (
	SELECT
		OrderDate,
		TotalDue = SUM(TotalDue)
	FROM
		Sales.SalesOrderHeader

	WHERE YEAR(OrderDate) = 2014

	GROUP BY
		OrderDate
) X
--views cant have order by


--Querying against the view:

SELECT
	OrderDate
   ,TotalDue
   ,SalesLast3Days
   ,[% Rolling 3 Days Sales] = FORMAT(TotalDue / SalesLast3Days, 'p')

FROM AdventureWorks2022.Sales.vw_SalesRolling3Days