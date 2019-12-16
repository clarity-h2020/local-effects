CREATE OR REPLACE FUNCTION clarity.hw_localeffect_tmrt_v2(eta_angle double precision, teta_angle double precision, t_air double precision, t_s double precision, gswrad double precision, albedo double precision, emissivity double precision, transmissi double precision, vegeshadow smallint, buildingsh smallint, hillsha_gf double precision, hillshadeb double precision, build_dens integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
    --	
	--  A simplified model for Tmrt evaluation in urban areas,
	--  mainly developed after the following papers:
	--	F.Lindberg & al. - SOLWEIG 1.0 - Modeling spatial variations of 3D radiant fluxes and mean radiant temperature in complex urban settings
	--  F.Lindberg & al. - The influence of vegetation and building morphology on shadow patterns and mean radiant temperatures in urban areas: model development and evaluation
	--  and Alessandra Capolupo first formulation in the excel model sheets
		--
	--	Please, note this main assumptions for Tmrt calculation with this simplified procedure:
	--
	--	completely clear sky
	--	valid daytime only
	--  if not available Ts can be estimated from Ta using an increment factor 
  --  and passed as an input parameter (test values deduce by analyzing SOLWEIG simulations results, done only on Naples area and summer time)
	--  
	--	...
	--  [stefanon nardone - PLINIVS - LUPT]

-- input parameters:
--
-- eta_angle double precision		Sun's altitude angle	
-- teta_angle double precision 		Sun's azimuth angle
-- t_air double precision 			Air temperature (°C)
-- t_s double precision 			Soil temperatue (°C)
-- gswrad double precision			Global shortwave radiation from https://meteoexploration.com/products/SolarCalculator.html (Wh/m2)
-- albedo double precision
-- emissivity double precision
-- transmissi double precision
-- vegeshadow smallint
-- buildingsh smallint
-- hillsha_gf double precision
-- hillshadeb double precision
-- build_dens integer

declare
    -- costants
    ST_BOLTZ CONSTANT float8 := 5.67E-8;				-- stefan-boltzmann constant
    E_P	  CONSTANT float8 := 0.97;						-- body emissivity
    XI_K  CONSTANT float8 := 0.7;						-- absorption coefficient for shortwave radiation
    F_AB  CONSTANT float8 := 0.06;						-- Fi angular factor for above and below
    F_4P  CONSTANT float8 := 0.22;						-- Fi for 4 cardinal points
    --
    G	  CONSTANT float8 := gswrad; 					-- 942.37; Global shortwave radiation from https://meteoexploration.com/products/SolarCalculator.html (Wh/m2)
    D	  CONSTANT float8 := 0.3*gswrad;				-- modificato da 0.1 a 0.3 -- Diffuse shortwave radiation
    I	  CONSTANT float8 := 0.7*gswrad;				-- modificato da 0.9 a 0.7 -- Direct shortwave radiation
    --	
	--         
    ETA   float8 := eta_angle;              			--  sun's altitude angle above the horizon. max elevation for Naples @21/6
    TETAE float8 := teta_angle;  						--  sun's azimuth angle init to position for Naples @21/6 @max elevation time 

    TA	  float8 := (t_air) + 273.15;					-- air temperature (converted to °K)
    TS	  float8 := t_s + 273.15;						-- surface temperature (converted to °K)	
    --
    E_SKY float8 :=  0.787 + 0.0028 * (TA-273.15);		-- sky emissivity [Ta is in C]
    
	-- E_W   float8 :=  0.7;							--
	-- ^^ modificato diventa funzione della densità dell'edificato ..
	--
	E_W float8[4] := '{0.01, 0.1, 0.4, 0.7}'::float8[];	-- E_W values attributed as a function of building densities classes [0..3] low - high	
    --
    -- aliases
    Es ALIAS for emissivity; 
    Sv ALIAS for vegeshadow;							-- vegetation shadow (boolean)   
    Sb ALIAS for buildingsh;							-- building shadov (boolean)
    Tau	ALIAS for transmissi;
    Psi_b ALIAS for hillshadeb;							--  	
    Psi_v ALIAS for hillsha_gf;							--
    Alfa ALIAS for albedo;								-- albedo, considered constant 0.15
    --
    -- variables
    tmrt	double precision;							-- mean radiant temperature
   	mrfd	double precision;							-- (R) mean radiant flux density
   	k_in	double precision; 							-- K shortwave radiation flux (W/m^2)
    k_out	double precision; 							--
    k_l		double precision[4];						--
    l_in	double precision;							-- L longwave radiation flux (W/m^2)
    l_out	double precision;							--
    l_l		double precision[4];						--
    --
	teta 	float8;		
	teta_e	float8;
	teta_s	float8; 
	teta_w	float8;
	teta_n  float8;										-- azimuth E, S, W, N components
    --
    cnt		integer;									-- loop counter
          


begin

	-- Kin
	k_in := (I * (Sb - (1 - Sv)*(1-Tau))*sind(ETA)) ;				-- angles are in degrees
	k_in  := k_in + D*(Psi_b - (1-Psi_v)*(1-Tau)) ;
    k_in  := k_in + G*Alfa*0.5*(1-(Psi_b - (1-Psi_v)*(1-Tau)));
	--                     ^^^ 0.5 is another parameter for evaluate (1-Fs) factor in the formula, with Fs fraction of building walls that is shadowed 		

    -- Kout
    k_out := k_in * Alfa;
    --    
   	teta_e := TETAE;
   	teta_s := TETAE - 90.0;
   	teta_w := TETAE - 180.0;
   	teta_n := TETAE - 270.0;
   
    teta   := teta_angle;
    
    -- k_l[1] = East	-- easterly component    			    
    if teta > 0.0 or teta <= 180.0 then    
    	k_l[1] := I*(Sb - (1-Sv)*(1-Tau))*cosd(ETA)*sind(teta_e) + D*(Psi_b - (1-Psi_v)*(1-Tau)) + G*Alfa*0.5*(1-(Psi_b-(1-Psi_v)*(1-Tau)));
																				               --       ^^^ 0.5 = (1-Fs) : Fs fraction of wall shadowed ...
    else
    	k_l[1] := D*(Psi_b - (1-Psi_v)*(1-Tau)) + G*Alfa*(1-(Psi_b-(1-Psi_v)*(1-Tau)));
    end if;
       
    -- k_l[2] = South -- southerly component
    if teta > 90.0 and teta <= 270.0 then
    	k_l[2] := I*(Sb - (1-Sv)*(1-Tau))*cosd(ETA)*sind(teta_s) + D*(Psi_b - (1-Psi_v)*(1-Tau)) + G*Alfa*0.5*(1-(Psi_b-(1-Psi_v)*(1-Tau)));																																
    else
    	k_l[2] := D*(Psi_b - (1-Psi_v)*(1-Tau)) + G*Alfa*0.5*(1-(Psi_b-(1-Psi_v)*(1-Tau)));
    end if; 
   
	-- k_l[3] = West
    if teta > 180.0 and teta <= 360.0 then
	 	k_l[3] := I*(Sb - (1-Sv)*(1-Tau))*cosd(ETA)*sind(teta_w) + D*(Psi_b - (1-Psi_v)*(1-Tau)) + G*Alfa*0.5*(1-(Psi_b-(1-Psi_v)*(1-Tau)));																																																				  	
	else
		k_l[3] := D*(Psi_b - (1-Psi_v)*(1-Tau)) + G*Alfa*0.5*(1-(Psi_b-(1-Psi_v)*(1-Tau)));																																 																																 																																 
	end if;   

    -- k_l[4] = North -- northerly component
    if teta <= 90.0 or teta > 270.0 then
		k_l[4] := I*(Sb - (1-Sv)*(1-Tau))*cosd(ETA)*sind(teta_n) + D*(Psi_b - (1-Psi_v)*(1-Tau)) + G*Alfa*0.5*(1-(Psi_b-(1-Psi_v)*(1-Tau)));																																
    else
		k_l[4] := D*(Psi_b - (1-Psi_v)*(1-Tau)) + G*Alfa*0.5*(1-(Psi_b-(1-Psi_v)*(1-Tau)));																																 
	end if;																			  
	    
   
	-- Lin
	l_in := (Psi_b + Psi_v - 1)*E_SKY*ST_BOLTZ*power(TA, 4) + (2 - Psi_v - Psi_b)*ST_BOLTZ*E_W[build_dens+1] * power(TA, 4) +
            (Psi_v - Psi_b)*E_W[build_dens+1]*E_SKY*ST_BOLTZ*power(TS,4) + (2 - Psi_b - Psi_v)*(1-E_W[build_dens+1])*ST_BOLTZ*power(TA,4)*E_SKY;
    						   
    -- Lout
    l_out := Es*ST_BOLTZ*power(TS + (TS-TA),4);

    -- L_l
    for cnt in 1..4 loop
        l_l[cnt] := 0.5*l_out;									-- simplified lateral components
    end loop;

    -- mrfd 										
    mrfd := XI_K*k_in*F_AB + E_P*l_in*F_AB;						-- Above
    mrfd := mrfd + XI_K*k_out*F_AB + E_P*l_out*F_AB;			-- Below
    for cnt in 1..4 loop
    	mrfd := mrfd + XI_K*k_l[cnt]*F_4P + E_P*l_l[cnt]*F_4P;	-- 4 cardinal points
    end loop;

    -- Tmrt ( output in °C)
   	tmrt := power(mrfd/(ST_BOLTZ * E_P), 0.25)  - 273.15;
   
    -- return
   	return tmrt;
   
end;
$function$
;

