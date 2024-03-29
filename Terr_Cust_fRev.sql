USE [CIA]
GO
/****** Object:  StoredProcedure [dbo].[Terr_Cust_fRev]    Script Date: 29.04.2013 15:01:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Tim
-- Create date: 14.03.13
-- Description:	
-- Terr_Cust_fRev displays Customer and future Revenue (Stage code between 1 and 6) for all Territories
-- Territory is identified/ selected via Curr Cov Id --> @terrID
-- =============================================
ALTER PROCEDURE [dbo].[Terr_Cust_fRev] @terrID nvarchar(50)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT
	  t.[Curr Cov Id], 
	  c.[Client Id D], 
	 -- CASE
		--WHEN max(s.[Opp Siebel Sales Stage Code])>0 and max(s.[Opp Siebel Sales Stage Code])<7 THEN
	 Sum(f.[Rev Usd D]) AS "Revenue"
		--ELSE '-' 
	--END AS "future Revenue"


	FROM [CIA].[dbo].[FactSalesOpps] AS f
	LEFT OUTER JOIN [CIA].[dbo].[DimSapCustNo] AS c
		ON c.SapCustId = f.SapCustNoID
	LEFT OUTER JOIN [CIA].[dbo].[DimTerr] AS t
		ON t.TerrID = f.TerrID
	LEFT OUTER JOIN [CIA].[dbo].[DimStage] AS s
		ON s.StageID = f.StageID
		
	WHERE
	t.[Curr Cov Id]=@terrID

	GROUP BY   t.[Curr Cov Id], c.[Client Id D]
	

END

