USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Coverage_All_Curves]    Script Date: 06/03/2018 10:29:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_MDD_Coverage_All_Curves_4G] 
(  
		-- Variables de entrada
		@provincia as varchar(256),			
		@ciudad as varchar(256),						
		@simOperator as int,
		@tech as varchar(256),
		@umbralIndoor varchar(256),
		@monthYearDash as varchar(100),
		@weekDash as varchar(50),
		@Report as varchar (256),
		@aggrType as varchar(256)
)
as 


-----------------------------
----- Testing Variables -----
-----------------------------
----use[FY1617_Coverage_Union]
----declare @provincia as varchar(256) = 'PARETSDELVALLES'
----declare @simOperator as int = 1
----declare @monthYearDash as varchar(100)='mes'
----declare @weekDash as varchar(50)='semana'
----declare @Report as varchar (256)='MUN'
----declare @aggrType as varchar(256)='GRID'
-----------------------------
-----------------------------


declare @operatorUmbrales as varchar(256)
set @operatorUmbrales= case when @Report = 'VDF' then 'Vodafone'
				else 'Orange'
			end


EXEC [dbo].[sp_MDD_Coverage_Results_Aggr_Curves4G] @provincia,
		'Curves',
		@operatorUmbrales,
		@Report,
		@simOperator,
		@monthYearDash,
		@weekDash,
		@aggrType
		WITH RESULT SETS
		((
		[Database] [nvarchar](128) NOT NULL,
		[mnc] [varchar](50) NOT NULL,
		[carrier] [varchar](50) NOT NULL,
		[band] [varchar](50) NULL,
		[parcel] [varchar](50) NULL,
		[RSRP_LTE] [float] NOT NULL,
		[RSRP_LTE2600] [float] NOT NULL,
		[RSRP_LTE2100] [float] NOT NULL,
		[RSRP_LTE1800] [float] NOT NULL,
		[RSRP_LTE800] [float] NOT NULL,
		[4G_All_Samples] [int] NOT NULL,
		[RSRP_LTE_Samples] [int] NOT NULL,
		[RSRP_LTE2600_Samples] [int] NOT NULL,
		[RSRP_LTE2100_Samples] [int] NOT NULL,
		[RSRP_LTE1800_Samples] [int] NOT NULL,
		[RSRP_LTE800_Samples] [int] NOT NULL,
		[LTE] [float] NOT NULL,
		[LTE2600] [float] NOT NULL,
		[LTE2100] [float] NOT NULL,
		[LTE2100_BW5] [float] NOT NULL,
		[LTE2100_BW10] [float] NOT NULL,
		[LTE2100_BW15] [float] NOT NULL,
		[LTE1800] [float] NOT NULL,
		[LTE1800_BW10] [float] NOT NULL,
		[LTE1800_BW15] [float] NOT NULL,
		[LTE1800_BW20] [float] NOT NULL,
		[LTE800] [float] NOT NULL,
		[LTE800_1800] [float] NOT NULL,
		[LTE800_2100] [float] NOT NULL,
		[LTE800_2600] [float] NOT NULL,
		[LTE1800_2100] [float] NOT NULL,
		[LTE1800_2600] [float] NOT NULL,
		[LTE2100_2600] [float] NOT NULL,
		[LTE800_1800_2100] [float] NOT NULL,
		[LTE800_1800_2600] [float] NOT NULL,
		[LTE800_2100_2600] [float] NOT NULL,
		[LTE1800_2100_2600] [float] NOT NULL,
		[LTE_Samples] [numeric](13, 1) NOT NULL,
		[LTE2600_Samples] [int] NOT NULL,
		[LTE2100_Samples] [int] NOT NULL,
		[LTE2100_BW5_Samples] [int] NOT NULL,
		[LTE2100_BW10_Samples] [int] NOT NULL,
		[LTE2100_BW15_Samples] [int] NOT NULL,
		[LTE1800_Samples] [int] NOT NULL,
		[LTE1800_BW10_Samples] [int] NOT NULL,
		[LTE1800_BW15_Samples] [int] NOT NULL,
		[LTE1800_BW20_Samples] [int] NOT NULL,
		[LTE800_Samples] [int] NOT NULL,
		[LTE800_1800_Samples] [int] NOT NULL,
		[LTE800_2100_Samples] [int] NOT NULL,
		[LTE800_2600_Samples] [int] NOT NULL,
		[LTE1800_2100_Samples] [int] NOT NULL,
		[LTE1800_2600_Samples] [int] NOT NULL,
		[LTE2100_2600_Samples] [int] NOT NULL,
		[LTE800_1800_2100_Samples] [int] NOT NULL,
		[LTE800_1800_2600_Samples] [int] NOT NULL,
		[LTE800_2100_2600_Samples] [int] NOT NULL,
		[LTE1800_2100_2600_Samples] [int] NOT NULL,
		[BS_LTE] [int] NOT NULL,
		[3G_All_Samples] [int] NOT NULL,
		[2G_Samples] [int] NOT NULL,
		[Region_VF] [nvarchar](255) NULL,
		[Provincia] [nvarchar](255) NULL,
		[Condado] [nvarchar](255) NULL,
		[Turistico] [float] NULL,
		[Entorno] [nvarchar](255) NULL,
		[Vendor_VF] [nvarchar](255) NULL,
		[Suministrador_VF] [nvarchar](255) NULL,
		[Sum_VF_Y_PINZA] [nvarchar](255) NULL,
		[Vendor_2G_MV] [nvarchar](255) NULL,
		[Vendor_3G_MV] [nvarchar](255) NULL,
		[Vendor_OR] [nvarchar](255) NULL,
		[Suministrador_OR] [nvarchar](255) NULL,
		[CodINE] [float] NULL,
		[Ciudad] [nvarchar](255) NULL,
		[Poblacion] [float] NULL,
		[Rango_Pob_Zona] [nvarchar](255) NULL,
		[Rango_Pob] [nvarchar](255) NULL,
		[Zona] [nvarchar](255) NULL,
		[Pob_Urbano] [nvarchar](255) NULL,
		[AVE] [nvarchar](255) NULL,
		[Carretera] [nvarchar](255) NULL,
		[Carretera_P3] [nvarchar](255) NULL,
		[Ciudad_P3] [nvarchar](255) NULL,
		[Entorno_P3] [nvarchar](255) NULL,
		[Meas_Week] [varchar](3) NULL,
		[Meas_Round] [varchar](256) NULL,
		[Meas_Date] [varchar](256) NULL,
		[Entidad] [varchar](256) NULL,
		[Num_Medida] [int] NULL,
		[monthYearDash] [varchar](256) NULL,
		[weekDash] [varchar](256) NULL,
		[Report_Type] [varchar](256) NULL,
		[Aggr_Type] [varchar](256) NULL,
		[Region_OSP] [nvarchar](255) NULL
		 ))
