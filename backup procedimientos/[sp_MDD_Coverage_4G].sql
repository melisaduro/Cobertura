USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Coverage_4G]    Script Date: 25/05/2017 11:33:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_MDD_Coverage_4G] 
(  
		-- Variables de entrada
		@provincia as varchar(256),			
		@ciudad as varchar(256),						
		@simOperator as int,
		@tech as varchar(256),
		@umbralIndoor varchar(256),
		@monthYearDash as varchar(100),
		@weekDash as varchar(50)
)
as 

EXEC [dbo].[sp_MDD_Coverage_4G_Wrapped] @provincia,		
		@ciudad,						
		@simOperator,
		@tech, 
		@umbralIndoor, 
		@monthYearDash,
		@weekDash
		WITH RESULT SETS
		((
			[Database] [nvarchar](128),
			[mnc] [varchar](50),
			[parcel] [varchar](50),
			[carrier] [varchar](50) NULL,
			[band] [varchar](50) NULL,
			[muestras] [int],
			[cobertura AVG] [float],
			[<-120] [int],
			[<=-120 a <-117] [int],
			[<=-117 a <-115] [int],
			[<=-115 a <-113] [int],
			[<=-113 a <-110] [int],
			[<=-110 a <-107] [int],
			[<=-107 a <-105] [int],
			[<=-105 a <-103] [int],
			[<=-103 a <-100] [int],
			[<=-100 a <-97] [int],
			[<=-97 a <-95] [int],
			[<=-95 a <-93] [int],
			[<=-93 a <-92] [int],
			[<=-92 a <-90] [int],
			[<=-90 a <-87] [int],
			[<=-87 a <-85] [int],
			[<=-85 a <-84] [int],
			[<=-84 a <-82] [int],
			[<=-82 a <-81] [int],
			[<=-81 a <-80] [int],
			[<=-80 a <-77] [int],
			[<=-77 a <-75] [int],
			[<=-75 a <-72] [int],
			[<=-72 a <-70] [int],
			[<=-70 a <-67] [int],
			[<=-67 a <-66] [int],
			[<=-66 a <-65] [int],
			[<=-65 a <-62] [int],
			[<=-62 a <-60] [int],
			[>=-60] [int],
			[avg_rsrq] [float],
			[>-3] [int],
			[-3 a -9] [int],
			[-9 a -12] [int],
			[-12 a -20] [int],
			[avg_CINR] [float],
			[< -10] [int],
			[-10 a 0] [int],
			[0 a 10] [int],
			[10 a 20] [int],
			[20 a 30] [int],
			[> 30] [int],
			[Indoor_Coverage_Prob] [float],
			[BW_5_Cutoff] [int],
			[BW_10_Cutoff] [int],
			[BW_15_Cutoff] [int],
			[BW_20_Cutoff] [int],
			Count_LTE2100_BW5 [int],
			Count_LTE2100_BW10 [int],
			Count_LTE2100_BW15 [int],
			Count_LTE1800_BW10 [int],
			Count_LTE1800_BW15 [int],
			Count_LTE1800_BW20 [int],
			avg_LTE2100_BW5 [float],
			avg_LTE2100_BW10 [float],
			avg_LTE2100_BW15 [float],
			avg_LTE1800_BW10 [float],
			avg_LTE1800_BW15 [float],
			avg_LTE1800_BW20 [float],
			Count_LTE2100_BW5_Ind [int],
			Count_LTE2100_BW10_Ind [int],
			Count_LTE2100_BW15_Ind [int],
			Count_LTE1800_BW10_Ind [int],
			Count_LTE1800_BW15_Ind [int],
			Count_LTE1800_BW20_Ind [int],
			Count_LTE2100_BW5_Out [int],
			Count_LTE2100_BW10_Out [int],
			Count_LTE2100_BW15_Out [int],
			Count_LTE1800_BW10_Out [int],
			Count_LTE1800_BW15_Out [int],
			Count_LTE1800_BW20_Out [int],
			[Region] [nvarchar](255),
			[Provincia] [nvarchar](255),
			[Condado] [nvarchar](255),
			[Turistico] [float],
			[Entorno] [nvarchar](255),
			[Vendor_VF] [nvarchar](255),
			[Suministrador_VF] [nvarchar](255),
			[Sum_VF_Y_PINZA] [nvarchar](255),
			[Vendor_2G_MV] [nvarchar](255),
			[Vendor_3G_MV] [nvarchar](255),
			[Vendor_OR] [nvarchar](255),
			[Suministrador_OR] [nvarchar](255),
			[CodINE] [float],
			[Ciudad] [nvarchar](255),
			[Poblacion] [float],
			[Rango_Pob_Zona] [nvarchar](255),
			[Rango_Pob] [nvarchar](255),
			[Zona] [nvarchar](255),
			[Pob_Urbano] [nvarchar](255),
			[AVE] [nvarchar](255),
			[Carretera] [nvarchar](255),
			[Carretera_P3] [nvarchar](255),
			[Ciudad_P3] [nvarchar](255),
			[Entorno_P3] [nvarchar](255),
			[Meas_Week] [varchar](3),
			[Meas_Round] [varchar](256),
			[Meas_Date] [varchar](256),
			[Entidad] [varchar](256),
			[Num_Medida] [varchar](256),
			[monthYearDash] [varchar](256) NULL,
			[weekDash] [varchar](256) NULL
		 ))