USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Coverage_All_Indoor_NEW]    Script Date: 29/05/2017 12:07:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_MDD_Coverage_All_Indoor_NEW] 
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
--use[FY1617_Coverage_Union]
--declare @provincia as varchar(256) = 'PARETSDELVALLES'
--declare @simOperator as int = 1
--declare @monthYearDash as varchar(100)='mes'
--declare @weekDash as varchar(50)='semana'
--declare @Report as varchar (256)='MUN'
--declare @aggrType as varchar(256)='GRID'
-----------------------------
-----------------------------


declare @operatorUmbrales as varchar(256)
set @operatorUmbrales= case when @Report = 'VDF' then 'Vodafone'
				else 'Orange'
			end


EXEC [dbo].[sp_MDD_Coverage_Results_Aggr_NEW] @provincia,
		'Samples_Indoor',
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
		[LTE_Samples] [int] NOT NULL,
		[LTE] [int] NOT NULL,
		[LTE2600] [int] NOT NULL,
		[LTE2100] [int] NOT NULL,
		[LTE2100_BW5] [int] NOT NULL,
		[LTE2100_BW10] [int] NOT NULL,
		[LTE2100_BW15] [int] NOT NULL,
		[LTE1800] [int] NOT NULL,
		[LTE1800_BW10] [int] NOT NULL,
		[LTE1800_BW15] [int] NOT NULL,
		[LTE1800_BW20] [int] NOT NULL,
		[LTE800] [int] NOT NULL,
		[LTE800_1800] [int] NOT NULL,
		[LTE800_2100] [int] NOT NULL,
		[LTE800_2600] [int] NOT NULL,
		[LTE1800_2100] [int] NOT NULL,
		[LTE1800_2600] [int] NOT NULL,
		[LTE2100_2600] [int] NOT NULL,
		[LTE800_1800_2100] [int] NOT NULL,
		[LTE800_1800_2600] [int] NOT NULL,
		[LTE800_2100_2600] [int] NOT NULL,
		[LTE1800_2100_2600] [int] NOT NULL,
		[UMTS_Samples] [int] NOT NULL,
		[UMTS] [int] NOT NULL,
		[UMTS2100] [int] NOT NULL,
		[UMTS2100_Carrier_only] [int] NOT NULL,
		[UMTS2100_F1] [int] NOT NULL,
		[UMTS2100_F2] [int] NOT NULL,
		[UMTS2100_F3] [int] NOT NULL,
		[UMTS2100_Dual_Carrier] [int] NOT NULL,
		[UMTS2100_F1_F2] [int] NOT NULL,
		[UMTS2100_F1_F3] [int] NOT NULL,
		[UMTS2100_F2_F3] [int] NOT NULL,
		[UMTS2100_F1_F2_F3] [int] NOT NULL,
		[UMTS900] [int] NOT NULL,
		[UMTS900_U2100_Carrier_only] [int] NOT NULL,
		[UMTS900_U2100_F1] [int] NOT NULL,
		[UMTS900_U2100_F2] [int] NOT NULL,
		[UMTS900_U2100_F3] [int] NOT NULL,
		[UMTS900_U2100_Dual_Carrier] [int] NOT NULL,
		[UMTS900_U2100_F1_F2] [int] NOT NULL,
		[UMTS900_U2100_F1_F3] [int] NOT NULL,
		[UMTS900_U2100_F2_F3] [int] NOT NULL,
		[UMTS900_U2100_F1_F2_F3] [int] NOT NULL,
		[2G_Samples] [int] NOT NULL,
		[2G] [int] NOT NULL,
		[GSM] [int] NOT NULL,
		[DCS] [int] NOT NULL,
		[GSM_DCS] [int] NOT NULL,
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
