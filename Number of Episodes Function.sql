USE [CIA]
GO
/****** Object:  UserDefinedFunction [dbo].[island_func]    Script Date: 28.04.2013 05:25:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Tim 	
-- Create date: 25.04.2013
-- Description:	Returns number of episodes for specific area, employee and client
-- =============================================
CREATE FUNCTION [dbo].[island_func]
(
	@terrID nvarchar(50),
	@empID nvarchar(50),
	@clientID nvarchar(50)
)
RETURNS int
AS
BEGIN
DECLARE @ret int;
	WITH
one AS (
		SELECT
			DATEPART(wk,d.[Date]) AS 'Date', 
			DATEPART(yyyy,d.[Date]) AS 'Year'
		FROM [CIA].[dbo].[FactSalesCalls] AS f
			LEFT OUTER JOIN [CIA].[dbo].[DimCallsDate] AS d
				ON d.DateID = f.DateID
			LEFT OUTER JOIN [CIA].[dbo].[DimCallsActivity] AS a
				ON a.ActivityID = f.ActivityID
			LEFT OUTER JOIN [CIA].[dbo].[DimCallsClient] AS c
				ON c.ClientID = f.ClientID
			LEFT OUTER JOIN [CIA].[dbo].[DimCallsEmp] AS e
				ON e.EmpID = f.EmpID
		WHERE c.[X Cov Ident] = @terrID
		AND   c.[X Client Id] = @clientID
		AND   e.[Ident User Id] =@empID
		GROUP BY DATEPART(wk,[Date]), DATEPART(yyyy,[Date])
		),
	
islands AS (
			SELECT 
				*,
				ROW_NUMBER() OVER (ORDER BY one.Date) - one.Date AS grp
			FROM one
			),

islands2 AS (
			SELECT
				*,
				(ROW_NUMBER() OVER (PARTITION BY grp ORDER BY [Date]) - [Date])*-1 islandgroups
             FROM islands)

SELECT
	@ret = COUNT(DISTINCT(islandgroups))
FROM islands2
Return @ret;
END


/*To Do: integrate ID dependency

'/