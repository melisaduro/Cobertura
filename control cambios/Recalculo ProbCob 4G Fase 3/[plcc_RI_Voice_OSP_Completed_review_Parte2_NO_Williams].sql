USE [AddedValue]
GO
/****** Object:  StoredProcedure [dbo].[plcc_RI_Voice_OSP_Completed_review_Parte2_NO_Williams]    Script Date: 09/03/2018 15:14:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER procedure [dbo].[plcc_RI_Voice_OSP_Completed_review_Parte2_NO_Williams] 
	@result as varchar(5),	--'Q' para Qlik			- lanza los procs y crea las tablas necesarias para QLIK
							--'D' para DASH			- solo las ultimas medidas y agregados de carreteras en funcion de @rollwindowRoad y @rollwindowAve
							--'E' para excel del RI	- todas las medidas - en el Excel se podra filtrar por LastMeasurement=1 para la ultima medida
	
	-- Ventanas deslizantes de las rondas a elegira para CARRETERAS y AVES:
	@rollwindowRoad as int,
	@rollwindowAve as int,

	@client as int,		-- Cliente final de entrega:+
							--VDF – borra columnas de IDs relativas a OSP  
							--OSP – ídem y además elimina la info de VOLTE para que no salga

	@isCompleted as varchar(10)		-- No aplica para VDF
											-- 'Y'		-- solo tienen en cuenta las entidades COMPLETADAS para OSP
											-- 'N'		-- tienen en cuenta todas las medidas, COMPLETADAS o no, para OSP
as


---------------------------------------
---------- Testing Variables ----------
---------------------------------------
--declare @result as varchar(5)= 'Q'		----'Q' para Qlik			- lanza los procs y crea las tablas necesarias para QLIK
--										----'D' para DASH			- solo las ultimas medidas y agregados de carreteras en funcion de @rollwindowRoad y @rollwindowAve
--										----'E' para excel del RI	- todas las medidas - en el Excel se podra filtrar por LastMeasurement=1 para la ultima medida
	
------	 Ventanas deslizantes de las rondas a elegira para CARRETERAS y AVES:
--declare @rollwindowRoad as int = 4
--declare @rollwindowAve as int = 3

--declare @client as int=0	-- Cliente final de entrega:
--								--VDF – borra columnas de IDs relativas a OSP 
--								--OSP – ídem y además elimina la info de VOLTE para que no salga

--declare @isCompleted as varchar(10)='Y'		---- No aplica para VDF
--											 ----'Y'		-- solo tienen en cuenta las entidades COMPLETADAS para OSP
--											 ----'N'		-- tienen en cuenta todas las medidas, COMPLETADAS o no, para OSP


-----------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
 --COMENTARIOS:

--	1) Se anula la info de VOLTE en medidas de 4G/3G
--	2) Se anula la info de NB en medidas M2M (el calltype viene en funcion de la bbdd de momento no se agrega)
--	   Se anula la info de WB en medidas M2F (el calltype viene en funcion de la bbdd de momento no se agrega)
--	4) Se deja la info relativa a MO/MT (intentos, cst) en llamadas M2M 
--	5) Se anulan WB AMR Only	WB_AMR_Only_Avg para YOI, ya que hay entidades agregadas con valor, y tiene q ser nulo
--	6) Se añade las ventanas deslizantes para el número de rondas a escoger para ROADs y AVEs
--	7) Se añae CR_Affected_Calls, pero se anula para todo lo que no sea AVE (en el BS el CR esta desactivdo como tal, solo funciona en los FR y de mommento interesan solo los AVEs)
--	8) Se incluye la Region_VF y Region_OSP en todas las entidades (Calidad y Cober)
--		para el @result='Q' de momento solo hace falta el Region_Road - por eso se crea una columna nueva para todas
--		para @result='D'/'E' nos quedamos SOLO con la Region correspondiente a @client y se sustituye ademas el valor para que sea del tipo ZonaX
--	9) Para el last_Measuremente, se realiza la ordenacion por cast(replace(meas_Week,'W','') as int) desc ya que de la otra forma ordena erroneamente al considerarlos como string (WX)

--	10) Se tienen en cuenta un nuevo 'report_type=ROAD'
--	Se trata de medidas de cobertura en carreteras extras para OSP solo. 
--	Se tratan de manera especial en el agregado.
--	Para mantener el formato con carreteras principales, en la parte de cobertura, se añade la coletiila -RX a las medidas que tengan este repot_type
--  Se tienen en cuenta tmb a la hora de presentar resutlado:
--		1) a VDF se borran
--		2) se tiene en cuenta que no existen en la tabla de AGRIDs.dbo.vlcc_dashboard_info_scopes_NEW - ENTITIES_DASHBOARD saldría a null

-- 11)	UPDATE_parcelas_sin_info: No se pueden dejar con codigoINE=99999 porque eso es de Indoor

-- 12)  Railways: Se anula el código_ine antes de todo el tema de unificaciones y demás, ya que codig_ine=99999 = INDOOR
-- 13)	Se cambia la forma de obtener las regiones	-> En vez de cogerse del agregado (que viene de lcc_parcelas) y tener que agrupar y modificar las tablas bases del RI, se cogen una vez unificados todas las tablas intermedias 
--			b.	Primero:
--				i.	Se asignan solo para AVEs y ROADs, en función del código_ine obtenido de vlcc_parcelas_osp -> Provincia, CCAA, Region_Road_VF, Region_Road_OSP, Region_VF y Region_OSP
--				ii.	Estos campos de vlcc_parcelas_OSP, viene de lcc_parcelas
--				iii.	Los campos:      
--							1.	Region_Road_VF, Region_Road_OSP		-> son para Qlik, solo tendran la info de carreteras, resto de entidades a null
--							2.	Region_VF y Region_OSP				-> tendrán la info para todo, en carreteras coincidirán con Region_Road_VF, Region_Road_OSP
--			c.	Segundo:
--				i.	Se unifica el código INE para todas las entidades menos AVEs y ROADs, tras lo cual, se rellenara esta información en estas entidades a partir de la V9
--			d.	Tercero: 
--					Se anula el valor de los códigos INE en carreteras y Aves, teniendo ya la info de todo
--			e.	Cuarto: 
--					Se agrupa la info por código ine de las entidades, que ahora es único para las entidades (V9) y se concatenan los KPIS de la cober ponderada por población a nivel de entidad ( mismo info en cada tipo de environment).

-- 14)	En lcc_parcelas, la info de Region viene con formato RX (tanto para VF o para OSP).
--		En V9, tenemos formato RegionX para VF y ZonaX para OSP -> En el punto 16 del RI se deja todo con formato RX (para que cuadren todos).
--		A la hora de sacar la info en los Excel, se sustituye por el formato ZonaX para ambos operadores

-- 15)	Para el cáclo del last_measurement de OSP, el meas_orderse calcula de la siguiente forma:
--		a) row_number() over 
--				(partition by  entity, mnc, meas_tech
--					order by case when max(id_osp) = 1 then max(id_osp) end DESC, meas_round DESC, case when report_type = 'MUN' then report_type end DESC,
--						meas_date DESC, cast(replace(meas_Week,'W','') as int) DESC					 
--				 ) as meas_order_osp 
--		Así, se cogera siempre la medida de la ultima fase:
--			* cd solo haya un reporte (y si está marcado como completado), lo cogera sea VDF o MUN
--			* cd haya los dos, cogera ordenadno por MUN-OSP-VDF
--		EXCEPCION en la Cobertura de ROADS y AVES, ya que cada operadro tiene sus propios umbrales. 
--		Para ello, se descartan las medidas con reporte VDF para estos scopes, para el calculo del meas_order. En cuyo caso se anula dicho campo

-- 16)	Se añaden los campos coverageXG_den_ProbCob, para usarse como denominador
--		Los AVES se agregan solo por Outdoor, y no tienen info de PCI (valor nulo que mete 0 en el calculo final del RI).
--		Esto hace que en las ppt cuenten esos 0.

--	17) Se borra el campo Report_Type para presentar en el excel


-- ************************************************************************************************************************************
--	Para ejecutar PRUEBAS que no molesten a QLIK, se puede sustituir '_RI_Voice' por _RI_Voice_VXX:
--			* TODAS las tablas involcradas en el proc empiezan por esta coletilla
--			* el codigo de replicas chequea si existe dicha coletilla para crear su tabla final con ella o no
-- ************************************************************************************************************************************

---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------EXPLICACIÓN CÓDIGO------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

  /*
  Se obtienen todos los KPIs necesarios para el RI y Qlik, tanto de 3G, 4G como 4GOnly para todos los entornos y operadores (Vodafone y Orange)
  Cuenta con un:
	* id_vdf que se pone a uno cuando la medida es tipo "VDF"
	* id_osp que se pone a 1 con la última medida Completada (medida en 3G, 4G y cobertura) 
		independientemente de que la medida sea tipo "VDF" o tipo "MUN", aunque éstas tendrán prioridad ante las medidas Vodafone.
	* id_osp_noComp que sirve para coger todas las medidas para OSP, completadas o no.

  Al final del código se pone un indicador de "última medida" tanto para Vodafone como para Orange, ya que los criterios para ambos son distintos.
	* Para Vodafone este indicador se pondrá a uno con la última medida vodafone. 
	* Para Orange se pondrá a 1 con la última medida completada, principalmente, si hubiese, por Municipios, 
		sino se quedaría con la última medida Vodafone completada.
	*/

---------------------------------------------------------------------------------------------------------------------------------------

-- ************************************************************************************************************************************
if @result='E'	-- trabajamos para Qlik				
			-- trabajamos para @result='D' o @result='E'
begin

	-- Cogemos la tabla de Qlik para trabajar con ella - ya tiene en cuenta las vueltas de AVEs y Roads
	-- drop table #RI_Voice_last_Qlik
	select * into #RI_Voice_last_Qlik from [QLIK].[dbo].[_RI_Voice_Completed_Qlik]
	
	-------------
	-- Se descartan las medidas antiguas:
	delete #RI_Voice_last_Qlik
	where Meas_Date in ('16_04','15_07','15_08','15_09')

	---------------
	-- Borramos las columnas de los rangos del CST y MOS:
	alter table #RI_Voice_last_Qlik drop column 
		[1_MO_A],	[2_MO_A],	[3_MO_A],	[4_MO_A],	[5_MO_A],	[6_MO_A],	[7_MO_A],	
		[8_MO_A],	[9_MO_A],	[10_MO_A],	[11_MO_A],	[12_MO_A],	[13_MO_A],	[14_MO_A],	
		[15_MO_A],	[16_MO_A],	[17_MO_A],	[18_MO_A],	[19_MO_A],	[20_MO_A],	[21_MO_A],	
		[22_MO_A],	[23_MO_A],	[24_MO_A],	[25_MO_A],	[26_MO_A],	[27_MO_A],	[28_MO_A],	
		[29_MO_A],	[30_MO_A],	[31_MO_A],	[32_MO_A],	[33_MO_A],	[34_MO_A],	[35_MO_A],
		[36_MO_A],	[37_MO_A],	[38_MO_A],	[39_MO_A],	[40_MO_A],	[41_MO_A],

		[1_MT_A],	[2_MT_A],	[3_MT_A],	[4_MT_A],	[5_MT_A],	[6_MT_A],	[7_MT_A],	
		[8_MT_A],	[9_MT_A],	[10_MT_A],	[11_MT_A],	[12_MT_A],	[13_MT_A],	[14_MT_A],	
		[15_MT_A],	[16_MT_A],	[17_MT_A],	[18_MT_A],	[19_MT_A],	[20_MT_A],	[21_MT_A],	
		[22_MT_A],	[23_MT_A],	[24_MT_A],	[25_MT_A],	[26_MT_A],	[27_MT_A],	[28_MT_A],	
		[29_MT_A],	[30_MT_A],	[31_MT_A],	[32_MT_A],	[33_MT_A],	[34_MT_A],	[35_MT_A],	
		[36_MT_A],	[37_MT_A],	[38_MT_A],	[39_MT_A],	[40_MT_A],	[41_MT_A],

		[1_MOMT_A],		[2_MOMT_A],		[3_MOMT_A],		[4_MOMT_A],		[5_MOMT_A],		[6_MOMT_A],	
		[7_MOMT_A],		[8_MOMT_A],		[9_MOMT_A],		[10_MOMT_A],	[11_MOMT_A],	[12_MOMT_A],	
		[13_MOMT_A],	[14_MOMT_A],	[15_MOMT_A],	[16_MOMT_A],	[17_MOMT_A],	[18_MOMT_A],	
		[19_MOMT_A],	[20_MOMT_A],	[21_MOMT_A],	[22_MOMT_A],	[23_MOMT_A],	[24_MOMT_A],	
		[25_MOMT_A],	[26_MOMT_A],	[27_MOMT_A],	[28_MOMT_A],	[29_MOMT_A],	[30_MOMT_A],
		[31_MOMT_A],	[32_MOMT_A],	[33_MOMT_A],	[34_MOMT_A],	[35_MOMT_A],	[36_MOMT_A],
		[37_MOMT_A],	[38_MOMT_A],	[39_MOMT_A],	[40_MOMT_A],	[41_MOMT_A],
			
		[1_MO_C],	[2_MO_C],	[3_MO_C],	[4_MO_C],	[5_MO_C],	[6_MO_C],	[7_MO_C],	
		[8_MO_C],	[9_MO_C],	[10_MO_C],	[11_MO_C],	[12_MO_C],	[13_MO_C],	[14_MO_C],	
		[15_MO_C],	[16_MO_C],	[17_MO_C],	[18_MO_C],	[19_MO_C],	[20_MO_C],	[21_MO_C],	
		[22_MO_C],	[23_MO_C],	[24_MO_C],	[25_MO_C],	[26_MO_C],	[27_MO_C],	[28_MO_C],	
		[29_MO_C],	[30_MO_C],	[31_MO_C],	[32_MO_C],	[33_MO_C],	[34_MO_C],	[35_MO_C],
		[36_MO_C],	[37_MO_C],	[38_MO_C],	[39_MO_C],	[40_MO_C],	[41_MO_C],

		[1_MT_C],	[2_MT_C],	[3_MT_C],	[4_MT_C],	[5_MT_C],	[6_MT_C],	[7_MT_C],	
		[8_MT_C],	[9_MT_C],	[10_MT_C],	[11_MT_C],	[12_MT_C],	[13_MT_C],	[14_MT_C],	
		[15_MT_C],	[16_MT_C],	[17_MT_C],	[18_MT_C],	[19_MT_C],	[20_MT_C],	[21_MT_C],	
		[22_MT_C],	[23_MT_C],	[24_MT_C],	[25_MT_C],	[26_MT_C],	[27_MT_C],	[28_MT_C],	
		[29_MT_C],	[30_MT_C],	[31_MT_C],	[32_MT_C],	[33_MT_C],	[34_MT_C],	[35_MT_C],
		[36_MT_C],	[37_MT_C],	[38_MT_C],	[39_MT_C],	[40_MT_C],	[41_MT_C],

		[1_MOMT_C],		[2_MOMT_C],		[3_MOMT_C],		[4_MOMT_C],		[5_MOMT_C],		[6_MOMT_C],	
		[7_MOMT_C],		[8_MOMT_C],		[9_MOMT_C],		[10_MOMT_C],	[11_MOMT_C],	[12_MOMT_C],	
		[13_MOMT_C],	[14_MOMT_C],	[15_MOMT_C],	[16_MOMT_C],	[17_MOMT_C],	[18_MOMT_C],	
		[19_MOMT_C],	[20_MOMT_C],	[21_MOMT_C],	[22_MOMT_C],	[23_MOMT_C],	[24_MOMT_C],	
		[25_MOMT_C],	[26_MOMT_C],	[27_MOMT_C],	[28_MOMT_C],	[29_MOMT_C],	[30_MOMT_C],
		[31_MOMT_C],	[32_MOMT_C],	[33_MOMT_C],	[34_MOMT_C],	[35_MOMT_C],	[36_MOMT_C],
		[37_MOMT_C],	[38_MOMT_C],	[39_MOMT_C],	[40_MOMT_C],	[41_MOMT_C]

	alter table #RI_Voice_last_Qlik drop column 
		[1_WB],	[2_WB],	[3_WB],	[4_WB],	[5_WB],	[6_WB],	[7_WB],	[8_WB],
		[1_NB],	[2_NB],	[3_NB],	[4_NB],	[5_NB],	[6_NB],	[7_NB],	[8_NB]

	-- Borramos las mil columnas de zonas y regiones innecesarias:
	alter table #RI_Voice_last_Qlik drop column Region_Road_VF, Region_Road_OSP		-- zona_VDF, zona_OSP,

	-- Borramos la columna de Report_Type:
	--alter table #RI_Voice_last_Qlik drop column Report_Type

	----------------------------------------------------------------- 
	-- Ahora separamos en funcion del cliente, ya que ira al DASH o al excel del RI:
	-------------
	if @client=1 
	begin 

		-- Nos quedamos con la columna de last_measurement de VDF, y SOLO las medidas de VDF (id_vdf=1)
		select 
			*,last_measurement_vdf as last_measurement, Region_VF as Zona,		--REPLACE(Region_VF, 'R', 'Zona') as Zona, --zona_VDF as Zona, Region_Road_VF as Region_Road, 
			case 
					when meas_Tech like 'Cover' and environment in ('MAIN HIGHWAYS', 'ROADS' , 'RURAL') then 'Rural'
					when meas_Tech like 'Cover' and environment in ('MAIN', 'SMALLER' , 'ADDON', 'TOURISTIC', 'ROC') then 'Urban'

					-- Para entidades ROADs y AVEs: 
					when meas_Tech like 'Road Cover' and environment in ('MAIN HIGHWAYS', 'ROADS' , 'RURAL') then 'Roads'
					when meas_Tech like 'Cover' and environment in ('AVE') then 'AVEs'

			end as environment_ResultCober
		into #RI_Voice_last_vf
		from #RI_Voice_last_Qlik
		where id_vdf=1		-- ojo que va a sacar las ultimas de YTB SD y NoCA_Device, son medidas antiguas

		-- Borramos la info de carreteras extras ya que van solo para OSP:
		delete #RI_Voice_last_vf
		where Report_Type='ROAD'

		-- Borramos las sobrantes - de OSP:
		alter table #RI_Voice_last_vf drop column id_osp, id_osp_noComp, last_measurement_osp, last_measurement_osp_noComp, id_vdf, last_measurement_vdf, Region_VF, Region_OSP

		-- Borramos la columna de Report_Type:
		alter table #RI_Voice_last_vf drop column Report_Type

		--******************************************************************************
		-- Se presenta el resultado final:
		if @result='D'	-- resultado para DASH				
		begin
			select d.ENTITIES_DASHBOARD, l.* 
			from #RI_Voice_last_vf l
				LEFT OUTER JOIN (select distinct entities_bbdd, ENTITIES_DASHBOARD from AGRIDs.dbo.vlcc_dashboard_info_scopes_NEW where report='VDF') d
					on l.entity=d.entities_bbdd
			-- nos quedamos con la ultima medida y los agregados de roads y aves que se indiquen como parametro
			where ((last_measurement >0 and last_measurement<=@rollwindowRoad) or  (last_measurement >0 and last_measurement<=@rollwindowAve))
				and d.ENTITIES_DASHBOARD is not null
		end

		if @result='E'	-- resultado para Excel RI			
		begin
			select l.*		-- nos quedamos todas las medidas - se podra filtrar en el excel por last_measurement=1
			from #RI_Voice_last_vf l
		end
		--******************************************************************************		
		drop table #RI_Voice_last_vf, #RI_Voice_last_Qlik		
	end		

	-------------
	if @client=3
	begin
		if @isCompleted='Y'		-- queremos la info de las COMPLETADAS para OSP
		begin
			-- Nos quedamos con la columna de last_measurement_osp y SOLO las medidas de OSP (id_osp=1 - medidas COMPLETADAS)
			select 
				*, last_measurement_osp as last_measurement, Region_OSP as Zona,		--REPLACE(Region_OSP, 'R', 'Zona') as Zona,	--zona_OSP as Zona, Region_Road_OSP as Region_Road, 
				case 
					when meas_Tech like 'Cover' and environment in ('MAIN HIGHWAYS', 'ROADS' , 'RURAL') then 'Rural'
					when meas_Tech like 'Cover' and environment in ('MAIN', 'SMALLER' , 'ADDON', 'TOURISTIC', 'ROC') then 'Urban'

					-- Para entidades ROADs y AVEs: 
					when meas_Tech like 'Road Cover' and environment in ('MAIN HIGHWAYS', 'ROADS' , 'RURAL') then 'Roads'
					when meas_Tech like 'Cover' and environment in ('AVE') then 'AVEs'

				end as environment_ResultCober
			into #RI_Voice_last_osp_Y
			from #RI_Voice_last_Qlik
			where id_osp=1					-- esto sería para medidas COMPLETADAS (por OSP, por ambos o por uno de los 2)	
				and scope <> 'ADD-ON CITIES WILLIAMS'
			-- Borramos medidas VOLTE antes de Fase 3, que no puede ver OSP:
			delete #RI_Voice_last_osp_Y
			where meas_Tech like 'VOLTE%'
			and meas_round in ('Fase 0', 'Fase 1', 'Fase 2')
			-- Borramos las sobrantes - de OSP:
			alter table #RI_Voice_last_osp_Y drop column id_vdf, id_osp, id_osp_noComp, last_measurement_osp, last_measurement_osp_noComp, last_measurement_vdf, Region_VF, Region_OSP --, zona_OSP, zona_VDF, Region_Road_VF, Region_Road_OSP

			-- Borramos la columna de Report_Type:
			alter table #RI_Voice_last_osp_Y drop column Report_Type

			--******************************************************************************	
			-- Se presenta el resultado final:
			if @result='D'	-- resultado para DASH				
			begin
				select d.ENTITIES_DASHBOARD, l.* 
				from #RI_Voice_last_osp_Y l
					LEFT OUTER JOIN (select distinct entities_bbdd, ENTITIES_DASHBOARD from AGRIDs.dbo.vlcc_dashboard_info_scopes_NEW where report='MUN') d
						on l.entity=d.entities_bbdd
				-- nos quedamos con la ultima medida y los agregados de roads y aves que se indiquen como parametro
				where ((last_measurement >0 and last_measurement<=@rollwindowRoad) or  (last_measurement >0 and last_measurement<=@rollwindowAve))	
					and d.ENTITIES_DASHBOARD is not null
			end

			if @result='E'	-- resultado para Excel RI			
			begin
				select l.*	-- nos quedamos todas las medidas - se podra filtrar en el excel por last_measurement=1
				from #RI_Voice_last_osp_Y l
				where meas_round = 'Fase 3'
			end
			--******************************************************************************		
			drop table #RI_Voice_last_osp_Y, #RI_Voice_last_Qlik		

		end	
		
		else					-- queremos TODAS las medidas, COMPLETADAS o NO
		begin
			-- Nos quedamos con la columna de last_measurement_osp_noComp y SOLO las medidas de OSP (COMPLETADAS o no)
			select 
				*,last_measurement_osp_noComp as last_measurement, Region_OSP as Zona,	--REPLACE(Region_OSP, 'R', 'Zona') as Zona,--zona_OSP as Zona, 
				case 
					-- Para las entidades ciudades - en INDOOR van sin scanner:
					when meas_Tech like 'Cover' and environment in ('MAIN HIGHWAYS', 'ROADS' , 'RURAL') then 'Rural'
					when meas_Tech like 'Cover' and environment in ('MAIN', 'SMALLER' , 'ADDON', 'TOURISTIC', 'ROC') then 'Urban'

					-- Para entidades ROADs y AVEs: 
					when meas_Tech like 'Road Cover' and environment in ('MAIN HIGHWAYS', 'ROADS' , 'RURAL') then 'Roads'
					when meas_Tech like 'Cover' and environment in ('AVE') then 'AVEs'

				end as environment_ResultCober
			into #RI_Voice_last_osp
			from #RI_Voice_last_Qlik
			where id_osp_noComp=1			-- esto serían todas las medidas para OSP, completadas o no
				and scope <> 'ADD-ON CITIES WILLIAMS'
			-- Borramos medidas VOLTE ya que van solo para VDF:
			delete #RI_Voice_last_osp
			where meas_Tech like 'VOLTE%'
			and meas_round in ('Fase 0', 'Fase 1', 'Fase 2')
			-- Borramos las sobrantes - de OSP:
			alter table #RI_Voice_last_osp drop column id_vdf, id_osp, id_osp_noComp, last_measurement_osp, last_measurement_osp_noComp, last_measurement_vdf, Region_VF, Region_OSP --, zona_OSP, zona_VDF, Region_Road_VF, Region_Road_OSP


			--******************************************************************************	
			-- Se presenta el resultado final:
			if @result='D'	-- resultado para DASH				
			begin
				select d.ENTITIES_DASHBOARD, l.*
				into #final 
				from #RI_Voice_last_osp l
					LEFT OUTER JOIN (select distinct entities_bbdd, ENTITIES_DASHBOARD from AGRIDs.dbo.vlcc_dashboard_info_scopes_NEW where report='MUN') d
						on l.entity=d.entities_bbdd
				-- nos quedamos con la ultima medida y los agregados de roads y aves que se indiquen como parametro
				where ((last_measurement >0 and last_measurement<=@rollwindowRoad) or  (last_measurement >0 and last_measurement<=@rollwindowAve))	
					 and (d.ENTITIES_DASHBOARD is not null or l.report_type='ROAD')

				-- Borramos la columna de Report_Type - lo hacemos aqui porque hacen falta en la intruccion anterior
				alter table #final drop column Report_Type

				-- Resultado final:
				select * from #final
			end

			if @result='E'	-- resultado para Excel RI			
			begin
				-- Borramos la columna de Report_Type:
				alter table #RI_Voice_last_osp drop column Report_Type

				select l.*	-- nos quedamos todas las medidas - se podra filtrar en el excel por last_measurement=1
				from #RI_Voice_last_osp l	
				where meas_round = 'Fase 3'				
			end
			--******************************************************************************		
			drop table #RI_Voice_last_osp, #RI_Voice_last_Qlik, #final	
		end
	end
end		-- fin @result='D' o @result='E'


