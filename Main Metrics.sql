USE [CIA]
GO
/****** Object:  StoredProcedure [dbo].[Main]    Script Date: 28.04.2013 02:54:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Tim 
-- Create date: 28.04.2013
-- Description:	Returns main metrics
-- =============================================
CREATE PROCEDURE [dbo].[Main] @terrID nvarchar(50)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Define the CTE expression name and column list.
WITH
x 
As
(
	SELECT
	t.[Curr Cov Id]+'-'+u.[Ident User Id]+'-'+c.[Client Id D]+'-'+f.[Opp No] AS ID,
	t.[Curr Cov Id] AS terr,
	u.[Ident User Id],
	c.[Client Id D],

	CASE
		WHEN s.[Opp Siebel Sales Stage Code] >= 7 and s.[Opp Siebel Sales Stage Code] <=8 THEN 'Won' --s.[Opp Siebel Sales Stage Code]="Won"
		WHEN s.[Opp Siebel Sales Stage Code] >=9 and s.[Opp Siebel Sales Stage Code] <= 11 THEN 'Not Won' --s.[Opp Siebel Sales Stage Code]="Not Won"
		ELSE '-' 
	END
	AS stage,
	DATEDIFF(d,d.[Opp Create Date],d.[Opp Win Loss Date]) AS duration,
	f.[Opp No]
	
	FROM [CIA].[dbo].[FactSalesOpps] AS f
  	LEFT OUTER JOIN [CIA].[dbo].[DimStage] AS s
		ON s.StageID = f.StageID
	LEFT OUTER JOIN [CIA].[dbo].[DimUser] AS u
		ON u.UserID = f.UserID
	LEFT OUTER JOIN [CIA].[dbo].DimSapCustNo AS c
		ON c.SapCustId = f.SapCustNoID
	LEFT OUTER JOIN [CIA].[dbo].DimTerr AS t
		ON t.TerrID = f.TerrID
	LEFT OUTER JOIN [CIA].[dbo].[DimDate] AS d
		ON d.DateID = f.DateID

), 
t 
AS
(
	SELECT
	c.[X Cov Ident]+'-'+e.[Ident User Id]+'-'+c.[X Client Id]+'-'+f.[Opp No] AS ID,
	c.[X Cov Ident] AS Terr,
	e.[Ident User Id] AS Rep, 
	c.[X Client Id] AS Cust,
	SUM(a.[Activity Lenght]) AS TotalV,
	MAX(d.date) AS maxd

	FROM [CIA].[dbo].[FactSalesCalls] AS f
		LEFT OUTER JOIN [CIA].[dbo].[DimCallsDate] AS d
			ON d.DateID = f.DateID
		LEFT OUTER JOIN [CIA].[dbo].[DimCallsActivity] AS a
			ON a.ActivityID = f.ActivityID
		LEFT OUTER JOIN [CIA].[dbo].[DimCallsClient] AS c
			ON c.ClientID = f.ClientID
		LEFT OUTER JOIN [CIA].[dbo].[DimCallsEmp] AS e
			ON e.EmpID = f.EmpID
	
	GROUP BY c.[X Cov Ident],e.[Ident User Id], c.[X Client Id], f.[Opp No]
),
m AS
(
	SELECT
	c.[X Cov Ident]+'-'+e.[Ident User Id]+'-'+c.[X Client Id]+'-'+f.[Opp No] AS ID,
	c.[X Cov Ident] AS Terr,
	e.[Ident User Id] AS Rep, 
	c.[X Client Id] AS Cust,
	MIN(d.date) AS mind,
	CASE 
		WHEN a.[Activity Type]='Meeting' THEN SUM(a.[Activity Lenght]) 
		ELSE 0
	END
	AS MeetingV,
	CAST(DATEPART(mm,d.date) as NVARCHAR(2)) + '-' + Cast(DATEPART(yy,d.date) as NVARCHAR(4)) ma,-- distinct month active
	CAST(DATEPART(wk,d.date) as NVARCHAR(2)) +'-'+ CAST(DATEPART(yy,d.date) as NVARCHAR(4)) AS wa


	FROM [CIA].[dbo].[FactSalesCalls] AS f
		LEFT OUTER JOIN [CIA].[dbo].[DimCallsDate] AS d
			ON d.DateID = f.DateID
		LEFT OUTER JOIN [CIA].[dbo].[DimCallsActivity] AS a
			ON a.ActivityID = f.ActivityID
		LEFT OUTER JOIN [CIA].[dbo].[DimCallsClient] AS c
			ON c.ClientID = f.ClientID
		LEFT OUTER JOIN [CIA].[dbo].[DimCallsEmp] AS e
			ON e.EmpID = f.EmpID
	
	GROUP BY  c.[X Cov Ident],e.[Ident User Id], c.[X Client Id], a.[Activity Type], d.Date, f.[Opp No]
)
 
SELECT
	m.Terr,
	m.Rep, 
	m.Cust,
	t.TotalV AS Volume,
	SUM(m.MeetingV)/Sum(t.TotalV) AS Mode,
	(COUNT(DISTINCT(m.ma))/12.00) AS "Frequency Monthly",
	(COUNT(DISTINCT(m.wa))/52.00) AS "Frequency Weekly",
	t.TotalV /COUNT(DISTINCT(m.ma)) AS "Intensity Monthly",
	t.TotalV /COUNT(DISTINCT(m.wa)) AS "Intensity Weekly",
	--t.TotalV/dbo.segments_func(@terrID, m.Rep, m.Cust ) AS Intensity,
	dbo.island_func(@terrID, m.Rep, m.Cust ) AS 'Number of Episodes',
	--COUNT(DISTINCT(m.ma)) AS #Month,
	--COUNT(DISTINCT(m.wa)) AS #Weeks,
	(DATEDIFF(WEEK,MIN(m.mind), MAX(t.maxd))+1)/52.00 AS Duration,
	x.duration AS "Duration in Days",
	x.stage AS Stage,
	x.[Opp No]
	
	
FROM
     m
left JOIN t ON t.ID=m.ID
left JOIN x ON x.ID=m.ID
WHERE m.[Terr]=@terrID
GROUP BY m.Terr, m.Rep, m.Cust, t.TotalV, x.stage, x.duration, x.[Opp No]
END
