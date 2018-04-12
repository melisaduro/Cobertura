-------Query 2G

--Comprobamos numero de registros
select count(1)
from [dbo].[lcc_cober2G_50x50_ALICANTE_MUN]

select count(1)
from [dbo].[lcc_cober2G_50x50_ALICANTE_MUN_OLD]

--Comprobamos que no haya diferencias entre las dos tablas

SELECT [Longitud_50m]
      ,[Latitud_50m]
      ,[frecuencia]
      ,[Band]
      ,[operator]
      ,[BSIC]
      ,[RSSI_Outdoor]
      ,[RSSI_Indoor]
      ,[PcobInd]
      ,[PcobInd_Band]
      ,[num_pilots]
      ,[num_Pilots_Band]
      ,[ind_ord]
      ,[ind_ord_operator]
FROM [lcc_cober2G_50x50_ALICANTE_MUN]
UNION 
SELECT * 
FROM [lcc_cober2G_50x50_ALICANTE_MUN_OLD]
EXCEPT  
SELECT [Longitud_50m]
      ,[Latitud_50m]
      ,[frecuencia]
      ,[Band]
      ,[operator]
      ,[BSIC]
      ,[RSSI_Outdoor]
      ,[RSSI_Indoor]
      ,[PcobInd]
      ,[PcobInd_Band]
      ,[num_pilots]
      ,[num_Pilots_Band]
      ,[ind_ord]
      ,[ind_ord_operator]
FROM [lcc_cober2G_50x50_ALICANTE_MUN]
INTERSECT
SELECT * FROM [lcc_cober2G_50x50_ALICANTE_MUN_OLD];

-------Query 3G

--Comprobamos numero de registros
select count(1)
from [dbo].[lcc_cober3G_50x50_ALICANTE_MUN]

select count(1)
from [dbo].[lcc_cober3G_50x50_ALICANTE_MUN_OLD]

--Comprobamos que no haya diferencias entre las dos tablas
	--Excepto las vecinas, que descuadran por tener el mismo nivel de señal, cuadra todo
(SELECT
     'New' as Stage, *
     FROM 
	 (
     (SELECT [Longitud_50m]
      ,[Latitud_50m]
      ,[frecuencia]
      ,[operator]
      ,[SC]
      ,[RSCP_Outdoor]
      ,[RSCP_Indoor]
      ,[EcIo_max]
      ,[PcobInd]
      ,[PcobInd_Band]
      ,[PcobInd_Channel]
      ,[num_pilots]
      ,[num_Pilots_Band]
      ,[num_Pilots_Channel]
      ,[ind_ord]
      ,[ind_ord_operator]
      ,[ind_ord_band]
      ,[NoPolluters]
      ,[Polluters]
      ,[Cuadricula_Polluter]
      ,[band]
      ,[RSCP2]
      ,[SC2]
      ,[RSCP3]
      ,[SC3]
      ,[RSCP4]
      ,[SC4]
      ,[RSCP5]
      ,[SC5]
	   FROM [lcc_cober3G_50x50_ALICANTE_MUN])
      EXCEPT
      (SELECT  [Longitud_50m]
      ,[Latitud_50m]
      ,[frecuencia]
      ,[operator]
      ,[SC]
      ,[RSCP_Outdoor]
      ,[RSCP_Indoor]
      ,[EcIo_max]
      ,[PcobInd]
      ,[PcobInd_Band]
      ,[PcobInd_Channel]
      ,[num_pilots]
      ,[num_Pilots_Band]
      ,[num_Pilots_Channel]
      ,[ind_ord]
      ,[ind_ord_operator]
      ,[ind_ord_band]
      ,[NoPolluters]
      ,[Polluters]
      ,[Cuadricula_Polluter]
      ,[band]
      ,[RSCP2]
      ,[SC2]
      ,[RSCP3]
      ,[SC3]
      ,[RSCP4]
      ,[SC4]
      ,[RSCP5]
      ,[SC5]
       FROM [lcc_cober3G_50x50_ALICANTE_MUN_OLD])
     ) OnNew)
UNION
(SELECT
     'Old' as Stage, *
     FROM (
          (SELECT [Longitud_50m]
      ,[Latitud_50m]
      ,[frecuencia]
      ,[operator]
      ,[SC]
      ,[RSCP_Outdoor]
      ,[RSCP_Indoor]
      ,[EcIo_max]
      ,[PcobInd]
      ,[PcobInd_Band]
      ,[PcobInd_Channel]
      ,[num_pilots]
      ,[num_Pilots_Band]
      ,[num_Pilots_Channel]
      ,[ind_ord]
      ,[ind_ord_operator]
      ,[ind_ord_band]
      ,[NoPolluters]
      ,[Polluters]
      ,[Cuadricula_Polluter]
      ,[band]
      ,[RSCP2]
      ,[SC2]
      ,[RSCP3]
      ,[SC3]
      ,[RSCP4]
      ,[SC4]
      ,[RSCP5]
      ,[SC5]
       FROM [lcc_cober3G_50x50_ALICANTE_MUN_OLD])
          EXCEPT
          (SELECT  [Longitud_50m]
      ,[Latitud_50m]
      ,[frecuencia]
      ,[operator]
      ,[SC]
      ,[RSCP_Outdoor]
      ,[RSCP_Indoor]
      ,[EcIo_max]
      ,[PcobInd]
      ,[PcobInd_Band]
      ,[PcobInd_Channel]
      ,[num_pilots]
      ,[num_Pilots_Band]
      ,[num_Pilots_Channel]
      ,[ind_ord]
      ,[ind_ord_operator]
      ,[ind_ord_band]
      ,[NoPolluters]
      ,[Polluters]
      ,[Cuadricula_Polluter]
      ,[band]
      ,[RSCP2]
      ,[SC2]
      ,[RSCP3]
      ,[SC3]
      ,[RSCP4]
      ,[SC4]
      ,[RSCP5]
      ,[SC5]
	   FROM [lcc_cober3G_50x50_ALICANTE_MUN])
     ) OnOld)
order by 2,3,4,5,6,7,8,9,10


--*******************
-------Query 4G

--Comprobamos numero de registros
select count(1)
from [dbo].[lcc_cober4G_50x50_ALICANTE_MUN]

select count(1)
from [dbo].[lcc_cober4G_50x50_ALICANTE_MUN_OLD]

--Comprobamos que no haya diferencias entre las dos tablas
(SELECT
     'New' as Stage, *
     FROM 
	 (
     (SELECT [Longitud_50m]
      ,[Latitud_50m]
      ,[frecuencia]
      ,[operator]
      ,[PCI]
      ,[RSRP_Outdoor]
      ,[RSRP_Indoor]
      ,[RSRQ_max]
      ,[CINR_max]
      ,[PcobInd]
      ,[ind_ord]
      ,[band]
      ,[bandwidth]
	   FROM [lcc_cober4G_50x50_ALICANTE_MUN])
      EXCEPT
      (SELECT [Longitud_50m]
      ,[Latitud_50m]
      ,[frecuencia]
      ,[operator]
      ,[PCI]
      ,[RSRP_Outdoor]
      ,[RSRP_Indoor]
      ,[RSRQ_max]
      ,[CINR_max]
      ,[PcobInd]
      ,[ind_ord]
      ,[band]
      ,[bandwidth] FROM [lcc_cober4G_50x50_ALICANTE_MUN_OLD])
     ) OnNew)
UNION
(SELECT
     'Old' as Stage, *
     FROM (
          (SELECT [Longitud_50m]
      ,[Latitud_50m]
      ,[frecuencia]
      ,[operator]
      ,[PCI]
      ,[RSRP_Outdoor]
      ,[RSRP_Indoor]
      ,[RSRQ_max]
      ,[CINR_max]
      ,[PcobInd]
      ,[ind_ord]
      ,[band]
      ,[bandwidth] FROM [lcc_cober4G_50x50_ALICANTE_MUN_OLD])
          EXCEPT
          (SELECT [Longitud_50m]
      ,[Latitud_50m]
      ,[frecuencia]
      ,[operator]
      ,[PCI]
      ,[RSRP_Outdoor]
      ,[RSRP_Indoor]
      ,[RSRQ_max]
      ,[CINR_max]
      ,[PcobInd]
      ,[ind_ord]
      ,[band]
      ,[bandwidth]
	   FROM [lcc_cober4G_50x50_ALICANTE_MUN])
     ) OnOld)
order by 2,3,4,5,6,7,8,9,10