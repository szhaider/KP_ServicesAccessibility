

*Regressions

*-------------------------------------------------------------------------------


*Population Data for regressions  (To upadte this data, first update the excel input)
/*
import excel using "$xlsx/population/KP_WSF_adm3_Pop.xlsx", first clear
drop if _n == _N   //Dropping totals
drop in 154/159
save "$output/population_number.dta", replace

*/

*-------------------------------------------------------------------------------

/*
*Keeping only those Tehsils which are correctly specified in Mouza census 2020. And we have a mapping in Shapefile 2022
*Dropping upper, lower, central etc.
*WE have 133 TEHSILS for regressions

import excel using "$xlsx/fuzzyjoin_adm3.xlsx", first clear
drop Similarity
*drop ADM3_CODE
drop if ADM3_NAME == ""
save "$output/tehsil_mouzatoshp2022.dta", replace         //Mapping file for Mouza and Shapefile tehsils
*/

*-------------------------------------------------------------------------------

*Reading Tehsil level sums for services (Education + Health + admin)
use "$output/tehsillevel_services_sums.dta", clear


*merging mouza-shapefile mapping   (Use this file to map mouza census tehsils to map Pak shapefile 2022 tehsils)
merge 1:m tehsil using "$output/tehsil_mouzatoshp2022.dta"    //same 133 tehsils matched
keep if _m == 3
drop _m

order ADM3_NAME ADM3_CODE


*Combining with Tehsil level Popualtion numbers
merge m:1 ADM3_NAME using  "$output/population_number.dta"   , force   //same 133 tehsils matched
keep if _m == 3
drop _m

order ADM2_NAME-DISP_AREA, before(ADM3_NAME)
destring WPOP20, replace force

drop Y


*>>>>>
*drop if ADM3_NAME =="Razmak"
*drop if ADM3_NAME == "Bar Chamarkand"     //outlier since number of schools < log pop and other services 0 (This is NMD tehsil!!!!!!!)
drop if ADM3_NAME == "Kalam"   //dropping Kalam since its covered in WSF population data, but not available in mouza census, . Matched with "Shah Alam". Secondly, It has around 1100 poplation (too fewer people) but 284 schools - so clearly shah alam is not a typo for kalam  - dropped
*<<<<<


gen NMDs = 1 if ADM2_NAME == "Bajaur" | ADM2_NAME == "Khyber" | ADM2_NAME == "Kurram" | ADM2_NAME == "Mohmand" | ADM2_NAME == "North Waziristan" | ADM2_NAME == "Orakzai" | ADM2_NAME == "South Waziristan" 
replace NMDs = 0 if NMDs == .
tab NMDs,m             //40 NMD tehsils


*to reverse coeff sign of interaction of pop and NMDs
gen NMAs = NMDs == 0

*-------------------------------------------------------------------------------

*Elasticities estimation
clonevar PrimarySchools = pri_schl_tot
clonevar MiddleSchools = mid_schl_tot
clonevar SecondarySchools = sec_schl_tot
clonevar Colleges = col_tot
clonevar Madrassahs = rel_schl_tot
clonevar Hospitals = health_facilities
clonevar PoliceStations = p8q051_admin_fac
clonevar WholesaleMarkets = p6q1311_admin_fac
clonevar Markets = p6q061_admin_fac

gen log_primary_schools = log(PrimarySchools)

*WSF19
gen logpop20 = log(WSF19POP17)
gen logpop25 = log(WSF19_TehsilPop_2025)
gen logpop30 = log(WSF19_TehsilPop_2030)

*WPOP20
gen logWpop20 = log(WPOP20)
gen logWpop25 = log(WPOP20_TehsilPop_2025)
gen logWpop30 = log(WPOP20_TehsilPop_2030)


gen log_WSF19_Pop_densitysqkm = log(WSF19_Pop_densitysqkm)

gen pop_gr2025  = ((WSF19_TehsilPop_2025 - WSF19POP17)/WSF19POP17)
gen pop_gr2030  = ((WSF19_TehsilPop_2030 - WSF19POP17)/WSF19POP17)

gen log_Adm3_Area_sqkm = log(Adm3_Area_sqkm)
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
*Overall Elasticity estimates (KP Province)


est clear

* 1. 2019-2020 WSF Population

global Models "PrimarySchools MiddleSchools SecondarySchools Colleges Hospitals WholesaleMarkets"

foreach var of varlist $Models {
		
	eststo `var' : reg `var' logpop20 c.logpop20#i.NMDs log_Adm3_Area_sqkm // absorb(NMDs)  nocons   log_WSF19_Pop_densitysqkm
	
	predict `var'_yhat, xb
	predict `var'_delta, residuals
	
	replace `var'_yhat = round(`var'_yhat)
	replace `var'_delta = round(`var'_delta)
	
	outreg2 . using "$tables/elasticity_estimates_`var'.xls", replace
		
*For population in 2025 & 2030 projections
*Using the Population projections for 2025 and 2030 on the estimated elasticities for 2020

estimates replay `var'

foreach i of numlist 25 30 {
gen `var'_`i' = round( e(b)[1,5]	+ 	 (e(b)[1,1] * logpop`i')  	+  ( e(b)[1,3]	* (logpop`i' * NMDs)) + (e(b)[1,4] * log_Adm3_Area_sqkm)  ) 
//+ `var'_delta
	}
	
}

est dir

*-------------------------------------------------------------------------------
*Coef plot for over all KP

coefplot $Models , yline(0) vertical title("Elasticity Estimates (Log Linear)") ///
ytitle("Change in basic services due to Population Growth (%)") drop(_cons log_Adm3_Area_sqkm) ///  log_WSF19_Pop_densitysqkm
subtitle("Controlling for Tehsil Area (sq-km)")  ///
		  recast(bar) ciopts(recast(rcap)) citop barwidt(0.07) ///  
		  note("Source: Authors' calculations based on Mouza Census 2020 & WSF19")
graph export "$figures/coefplot_allcategories.png", replace	
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
*Predictions frontier (Population per schools benchmarking)- to see how far behind the tehsils are from top performers

*Benchmark - Population per (should be) school (Population per (yhat) average umber of schools) not using predictions due to negatives
*2020

* Holding the population per school benchmark constant at 2020 levels - Otherwise we're allowing average schools to nearly double in capacity

 gen pop_per_pred_prim_school 	  = WSF19POP17 / PrimarySchools_yhat    
 gen pop_per_pred_midl_school 	  = WSF19POP17 / MiddleSchools_yhat   
 gen pop_per_pred_secd_school 	  = WSF19POP17 / SecondarySchools_yhat  
 gen pop_per_pred_colg		  	  = WSF19POP17 / Colleges_yhat  
 gen pop_per_pred_hospl	  	  	  = WSF19POP17 / Hospitals_yhat
 gen pop_per_pred_makt 		  	  = WSF19POP17 / WholesaleMarkets_yhat
 
 *2025
 gen pop_per_pred_prim_school_25  = WSF19_TehsilPop_2025 / PrimarySchools_25    
 gen pop_per_pred_midl_school_25  = WSF19_TehsilPop_2025 / MiddleSchools_25   
 gen pop_per_pred_secd_school_25  = WSF19_TehsilPop_2025 / SecondarySchools_25  
 gen pop_per_pred_colg_25		  = WSF19_TehsilPop_2025 / Colleges_25  
 gen pop_per_pred_hospl_25	  	  = WSF19_TehsilPop_2025 / Hospitals_25
 gen pop_per_pred_makt_25 		  = WSF19_TehsilPop_2025 / WholesaleMarkets_25

 *2030
 gen pop_per_pred_prim_school_30  = WSF19_TehsilPop_2030 / PrimarySchools_30   
 gen pop_per_pred_midl_school_30  = WSF19_TehsilPop_2030 / MiddleSchools_30   
 gen pop_per_pred_secd_school_30  = WSF19_TehsilPop_2030 / SecondarySchools_30  
 gen pop_per_pred_colg_30		  = WSF19_TehsilPop_2030 / Colleges_30  
 gen pop_per_pred_hospl_30	  	  = WSF19_TehsilPop_2030 / Hospitals_30
 gen pop_per_pred_makt_30		  = WSF19_TehsilPop_2030 / WholesaleMarkets_30
 
 drop if ADM3_NAME == "Bar Chamarkand"     //Since negative average due to very very small population - WSF issue to discuss
 drop if ADM3_NAME == "Razmak" 
 drop if ADM3_NAME == "Garyum"
  drop if ADM3_NAME == "Ghulam Khan"
  
 *2020
	 
	 
 global averages "pop_per_pred_prim_school pop_per_pred_midl_school pop_per_pred_secd_school pop_per_pred_colg pop_per_pred_hospl pop_per_pred_makt"
  
 foreach avg of varlist $averages {
 
 *gsort pop_per_pred_prim_school     // Kalam has 1168 people????
 gsort `avg'
 
 *Taking average of top 20% of the tehsils as population per school benchmark for rural areas
 *list pop_per_pred_school in 1/26
 
 preserve
 
 keep in 1/25   //10%    //10  26
 
 *sum pop_per_pred_school
 sum `avg'
 
 local top =  r(mean)
 di "`top'"    //581.71 people / school
 
 restore

 gen top_`avg' = r(mean)
 
 label var top_`avg' "Population per predicted facililites - Benchmark 2020"
 
 }

*2020 

 gen pop_per_pred_prim_school_diff 	  =     pop_per_pred_prim_school -  top_pop_per_pred_prim_school
 gen pop_per_pred_midl_school_diff 	  =     pop_per_pred_midl_school -  top_pop_per_pred_midl_school
 gen pop_per_pred_secd_school_diff 	  =   	pop_per_pred_secd_school -	top_pop_per_pred_secd_school 
 gen pop_per_pred_colg_diff 	  =   		pop_per_pred_colg -	        top_pop_per_pred_colg 
 gen pop_per_pred_hospl_diff   =     		pop_per_pred_hospl -		top_pop_per_pred_hospl 
 gen pop_per_pred_makt_diff 	  =   		pop_per_pred_makt -         top_pop_per_pred_makt
 
*2025
 
 gen pop_per_pred_prim_school_25_diff =     pop_per_pred_prim_school_25 -   top_pop_per_pred_prim_school
 gen pop_per_pred_midl_school_25_diff =     pop_per_pred_midl_school_25 -   top_pop_per_pred_midl_school
 gen pop_per_pred_secd_school_25_diff =     pop_per_pred_secd_school_25 -   top_pop_per_pred_secd_school
 gen pop_per_pred_colg_25_diff =     		pop_per_pred_colg -   top_pop_per_pred_colg
 gen pop_per_pred_hospl_25_diff =   		pop_per_pred_hospl -  top_pop_per_pred_hospl
 gen pop_per_pred_makt_25_diff =     		pop_per_pred_makt -   top_pop_per_pred_makt

*2030
 
 gen pop_per_pred_prim_school_30_diff  =    pop_per_pred_prim_school_30  - top_pop_per_pred_prim_school 
 gen pop_per_pred_midl_school_30_diff  =    pop_per_pred_midl_school_30  - top_pop_per_pred_midl_school 
 gen pop_per_pred_secd_school_30_diff  =    pop_per_pred_secd_school_30  - top_pop_per_pred_secd_school 
 gen pop_per_pred_colg_30_diff  =    		pop_per_pred_colg  - top_pop_per_pred_colg
 gen pop_per_pred_hospl_30_diff =    		pop_per_pred_hospl - top_pop_per_pred_hospl
 gen pop_per_pred_makt_30_diff  =    		pop_per_pred_makt  - top_pop_per_pred_makt
 


*2020 
  gen req_pop_per_pred_prim_school =  round(pop_per_pred_prim_school_diff /   top_pop_per_pred_prim_school)   //top_pop_per_pred_prim_school   
  gen req_pop_per_pred_midl_school =  round(pop_per_pred_midl_school_diff /   top_pop_per_pred_midl_school)   //top_pop_per_pred_prim_school   
  gen req_pop_per_pred_secd_school =  round(pop_per_pred_secd_school_diff /   top_pop_per_pred_secd_school)   //top_pop_per_pred_prim_school   
  gen req_pop_per_pred_colg =  		  round(pop_per_pred_colg_diff /   top_pop_per_pred_colg)   //top_pop_per_pred_prim_school   
  gen req_pop_per_pred_hospl = 		  round(pop_per_pred_hospl_diff / top_pop_per_pred_hospl)   //top_pop_per_pred_prim_school   
  gen req_pop_per_pred_makt =  		  round(pop_per_pred_makt_diff /   top_pop_per_pred_makt)   //top_pop_per_pred_prim_school   

 
*2025 
  gen req_pop_per_pred_prim_school_25 = round(pop_per_pred_prim_school_25_diff / top_pop_per_pred_prim_school)   //top_pop_per_pred_prim_school  
  gen req_pop_per_pred_midl_school_25 = round(pop_per_pred_midl_school_25_diff / top_pop_per_pred_midl_school)   //top_pop_per_pred_prim_school  
  gen req_pop_per_pred_secd_school_25 = round(pop_per_pred_secd_school_25_diff / top_pop_per_pred_secd_school)   //top_pop_per_pred_prim_school  
  gen req_pop_per_pred_colg_25 = 	    round(pop_per_pred_colg_25_diff / top_pop_per_pred_colg)   //top_pop_per_pred_prim_school  
  gen req_pop_per_pred_hospl_25 = 		round(pop_per_pred_hospl_25_diff / top_pop_per_pred_hospl)   //top_pop_per_pred_prim_school  
  gen req_pop_per_pred_makt_25 = 		round(pop_per_pred_makt_25_diff / top_pop_per_pred_makt)   //top_pop_per_pred_prim_school  

 
*2030 
  gen req_pop_per_pred_prim_school_30 = round(pop_per_pred_prim_school_30_diff / top_pop_per_pred_prim_school)   //top_pop_per_pred_prim_school 
  gen req_pop_per_pred_midl_school_30 = round(pop_per_pred_midl_school_30_diff / top_pop_per_pred_midl_school)   //top_pop_per_pred_prim_school 
  gen req_pop_per_pred_secd_school_30 = round(pop_per_pred_secd_school_30_diff / top_pop_per_pred_secd_school)   //top_pop_per_pred_prim_school 
  gen req_pop_per_pred_colg_30 =  		round(pop_per_pred_colg_30_diff / top_pop_per_pred_colg)   //top_pop_per_pred_prim_school 
  gen req_pop_per_pred_hospl_30 =      	round(pop_per_pred_hospl_30_diff / top_pop_per_pred_hospl)   //top_pop_per_pred_prim_school 
  gen req_pop_per_pred_makt_30 =  		round(pop_per_pred_makt_30_diff / top_pop_per_pred_makt)   //top_pop_per_pred_prim_school 

  *****
*Not using increment since increments are 0 if 2025 and 2030 are same as 2020

* gen incremet_prim_2025 = req_pop_per_pred_prim_school_25 - req_pop_per_pred_prim_school
* gen incremet_prim_2030 = req_pop_per_pred_prim_school_30 - req_pop_per_pred_prim_school
 
 
 *gen incremet_midl_2025 = req_pop_per_pred_midl_school_25 - req_pop_per_pred_midl_school
 *gen incremet_midl_2030 = req_pop_per_pred_midl_school_30 - req_pop_per_pred_midl_school
 
 *replace incremet_midl_2025 = abs(incremet_midl_2025) 
 *replace incremet_midl_2030 = abs(incremet_midl_2030) 
 *replace incremet_midl_2030 = 0 if (incremet_midl_2030 == incremet_midl_2025)    //because we are showing only increment
 
  
 *gen incremet_secd_2025 = req_pop_per_pred_secd_school_25 - req_pop_per_pred_secd_school
 *gen incremet_secd_2030 = req_pop_per_pred_secd_school_30 - req_pop_per_pred_secd_school
 
 *replace incremet_secd_2025 = abs(incremet_secd_2025) 
 *replace incremet_secd_2030 = abs(incremet_secd_2030) 
 
 *gen incremet_hospl_2025 = req_pop_per_pred_hospl_25 - req_pop_per_pred_hospl
 *gen incremet_hospl_2030 = req_pop_per_pred_hospl_30 - req_pop_per_pred_hospl
  
 
 
 preserve
 
drop if req_pop_per_pred_prim_school == 0 & NMDs == 1
 
 graph hbar req_pop_per_pred_prim_school  req_pop_per_pred_prim_school_25 req_pop_per_pred_prim_school_30 if NMDs == 1, stack over(ADM3_NAME, sort(req_pop_per_pred_prim_school descending) ///
 lab(labsize(vsmall))) ytitle("Additional primary schools required (rounded)") ///
 title("NMAs: Based on Model Averages (yhats)") ///
 subtitle("New Schools needed: To reach population per school benchmark") ///
 legend(label(1 "Base 2020") label(2 "Projected 2025") label(3 "Projected 2030"))
 
 graph export "$figures/primary_NMDs_additional.png", replace  
 
 restore
 
 *****
 
 preserve
 
 *drop if (req_pop_per_pred_midl_school <= 0 | req_pop_per_pred_midl_school==.) & NMDs == 1
 
 graph hbar req_pop_per_pred_midl_school req_pop_per_pred_midl_school_25  req_pop_per_pred_midl_school_30 if NMDs == 1, stack over(ADM3_NAME, sort(req_pop_per_pred_midl_school req_pop_per_pred_midl_school descending) ///
 lab(labsize(vsmall))) ytitle("Additional middle schools required (rounded)") ///
 title("NMAs: Based on Model Averages (yhat)") ///
 subtitle("New Schools needed: To reach population per school benchmark")  ///
 legend(label(1 "Base 2020") label(2 "Projected 2025") label(3 "Projected 2030"))
 
 graph export "$figures/middle_NMDs_additional.png", replace  
 
 restore

  *****
 preserve
 
 drop if (req_pop_per_pred_secd_school <= 0 | req_pop_per_pred_secd_school ==.) & NMDs == 1
*drop if (req_pop_per_pred_secd_school <= 0 | req_pop_per_pred_secd_school ==.) & NMDs == 1
 
 graph hbar req_pop_per_pred_secd_school req_pop_per_pred_secd_school_25 req_pop_per_pred_secd_school_30  if NMDs == 1, stack over(ADM3_NAME, sort(req_pop_per_pred_secd_school descending) ///
 lab(labsize(vsmall))) ytitle("Additional Higher Secondary schools required (rounded)") ///
 title("NMAs: Based on Model Averages (yhat)") ///
 subtitle("New Schools needed: To reach population per school benchmark") ///
 legend(label(1 "Base 2020") label(2 "Projected 2025") label(3 "Projected 2030"))
 
 
 graph export "$figures/secondary_NMDs_additional.png", replace  
 
 restore
 
 ******
 preserve
 
drop if (req_pop_per_pred_hospl <= 0 | req_pop_per_pred_hospl == .) & NMDs == 1
 
 graph hbar req_pop_per_pred_hospl req_pop_per_pred_hospl_25 req_pop_per_pred_hospl_30  if NMDs == 1, stack over(ADM3_NAME, sort(req_pop_per_pred_hospl descending) ///
 lab(labsize(vsmall))) ytitle("Additional Hospitals/Dispencaries required (rounded)") ///
 title("NMAs: Based on Model Averages (yhat)") ///
 subtitle("To reach population per hospital benchmark") ///
 legend(label(1 "Base 2020") label(2 "Marginal 2025") label(3 "Marginal 2030"))
 
 graph export "$figures/hospitals_NMDs_additional.png", replace  
 
 restore
  
 
*-------------------------------------------------------------------------------
*Deltas Visualization for NMD tehsils in KP
*PrimarySchools_delta_2025 PrimarySchools_delta_2030
graph hbar PrimarySchools_delta   if NMDs == 1, over(ADM3_NAME, sort(PrimarySchools_delta descending) lab(labsize(vsmall))) ytitle("Predictions (number of primary schools)") title("NMAs Model Predictions: y-yhat") 
*subtitle("Newly Merged Tehsils")  
*legend( label(1 "Primary Schools 2019") label(2 "Primary Schools 2025") label(3 "Primary Schools 2030") ) 
graph export "$figures/primary_tehsil_deltas.png", replace  

graph hbar MiddleSchools_delta  if NMDs == 1, over(ADM3_NAME, sort(MiddleSchools_delta descending) lab(labsize(vsmall))) ytitle("Predictions (number of middle schools)") title("NMAs Model Predictions: y-yhat") 
graph export "$figures/middle_tehsil_deltas.png", replace  

graph hbar SecondarySchools_delta if NMDs == 1, over(ADM3_NAME, sort(SecondarySchools_delta descending) lab(labsize(vsmall))) ytitle("Predictions (number of secondary schools)") title("NMAs Model Predictions: y-yhat") 
graph export "$figures/Secondary_tehsil_deltas.png", replace  


graph hbar Hospitals_delta if NMDs == 1, over(ADM3_NAME, sort(Hospitals_delta descending) lab(labsize(vsmall))) ytitle("Predictions (number of secondary schools)") title("NMAs Model Predictions: y-yhat") 
graph export "$figures/hospitals_tehsil_deltas.png", replace  


/*
*Elasticity Estimates KP :  with and without NMDs

est clear

global Models "PrimarySchools MiddleSchools SecondarySchools Colleges Hospitals WholesaleMarkets"

levelsof NMDs, local(NMD)

foreach var of varlist $Models {
	
	foreach num of local NMD {
	
	eststo `var'_`num' : reg `var' log_WSF19POP17 log_WSF19_Pop_densitysqkm if NMDs == `num'   // absorb(NMDs) 

	outreg2 . using "$tables/elasticity_estimates_`var'_`num'.xls", replace
	
	}

}

est dir

global Models_NMDs_1 "PrimarySchools_0 PrimarySchools_1" 
global Models_NMDs_2 "MiddleSchools_0 MiddleSchools_1" 
global Models_NMDs_3 "SecondarySchools_0 SecondarySchools_1" 

global Models_NMDs_4 "Colleges_0 Colleges_1 Hospitals_0 Hospitals_1 WholesaleMarkets_0 WholesaleMarkets_1"
*-------------------------------------------------------------------------------
*Coefplot for NMDs	vs KP

coefplot  $Models_NMDs_1 $Models_NMDs_2 $Models_NMDs_3 , yline(0) vertical title("Elasticity Estimates (Log Linear)") ///
		  subtitle("NMDs vs Rest of the KP") ytitle("Change in basic services due to Population Growth (%)") drop(_cons) ///
		  recast(rarea) ciopts(recast(rcap)) citop ///  
		  note("Source: Authors' calculations based on Mouza Census 2020 & WSF19") ///
		  legend( label(1 "Primary Schools: Rest of KP") label(3 "Primary Schools: NMDs")  ///
		  label(5 "Middle Schools: Rest of KP") label(7 "Middle Schools: NMDs")  ///
		  label(9 "Secondary Schools: Rest of KP") label(11 "Secondary Schools: NMDs") ) ///
		  
graph export "$figures/coefplot_schools_withand withoutNMDs.png", replace
*-------------------------------------------------------------------------------
*Coefplot for NMDs	vs KP
coefplot  $Models_NMDs_4 , yline(0) vertical title("Elasticity Estimates (Log Linear)") ///
		  subtitle("NMDs vs Rest of the KP") ytitle("Change in basic services due to Population Growth (%)") drop(_cons) ///
		  recast(rarea) ciopts(recast(rcap)) citop ///  
		  note("Source: Authors' calculations based on Mouza Census 2020 & WSF19") ///
		  legend( label(1 "Colleges: Rest of KP") label(3 "Colleges: NMDs")  ///
		  label(5 "Hospitals: Rest of KP") label(7 "Hospitals: NMDs")  ///
		  label(9 "WholesaleMarkets: Rest of KP") label(11 "WholesaleMarkets: NMDs") ) ///
	
graph export "$figures/coefplot_othercats_withand withoutNMDs.png", replace
*-------------------------------------------------------------------------------

save "$output/model_predictions.dta", replace

*-------------------------------------------------------------------------------

*export excel using "$xlsx/facilities_needed_v1.xlsx" if NMDs == 1, first(variable) replace
/* Rough

*areg PrimarySchools log_WSF19POP17 c.log_WSF19POP17#c.NMDs  log_WSF19_Pop_densitysqkm, absorb(NMDs)    //Tobediscussed
*areg middle_schools log_WSF19POP17 c.log_WSF19POP17#c.NMDs  log_WSF19_Pop_densitysqkm, absorb(NMDs)    //Tobediscussed
*areg secondary_schools log_WSF19POP17 c.log_WSF19POP17#c.NMDs  log_WSF19_Pop_densitysqkm, absorb(NMDs)    //Tobediscussed
*areg colleges log_WSF19POP17 c.log_WSF19POP17#c.NMDs  log_WSF19_Pop_densitysqkm, absorb(NMDs)    //Tobediscussed
*areg wholesale_markets log_WSF19POP17 c.log_WSF19POP17#c.NMDs  log_WSF19_Pop_densitysqkm, absorb(NMDs)    //Tobediscussed

*---
eststo PrimarySchools: reg PrimarySchools log_WSF19POP17 c.log_WSF19POP17#i.NMDs  // log_WSF19_Pop_densitysqkm i.NMDs  
*eststo PrimarySchools: areg primary_schools log_WSF19POP17 c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm , absorb(NMDs)
outreg2 . using "$tables/elasticity_estimates_primary_all.xls", replace

*lvr2plot
*rvfplot
*rvpplot log_WSF19POP17
*gen log_WSF19_TehsilPop_2025 = log(WSF19_TehsilPop_2025)
*avplots 

*Predict
predict primary_schools_pred, xb 
predict primary_delta, residuals

*gen delta_primary = primary_schools_pred - primary_schools   //errors

*gen log_WSF19_TehsilPop_2025 = log(WSF19_TehsilPop_2025)
gen primary_schools_new =  primary_schools_pred * (1+pop_gr2025)
gen primary_schools_needed2025 = round(primary_schools_new - primary_schools_pred) 

*gen schools  = primary_schools + (_b[log_WSF19POP17] * (1+pop_gr2025))
*gen new_schools = schools - primary_schools
*replace  primary_schools = primary_schools + _b[log_WSF19POP17] * (1+pop_gr2025)
*predict primary_schools_p, xb 

*---
*Middle schools for boys + girls
eststo MiddleSchools: reg MiddleSchools log_WSF19POP17 c.log_WSF19POP17#i.NMDs // log_WSF19_Pop_densitysqkm i.NMDs  
*eststo MiddleSchools: areg middle_schools log_WSF19POP17 c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm , absorb(NMDs)
outreg2 . using "$tables/elasticity_estimates_middle_all.xls", replace

*---
*Higher Secondary schools for boys + girls
eststo SecondarySchools: reg SecondarySchools log_WSF19POP17 c.log_WSF19POP17#i.NMDs // log_WSF19_Pop_densitysqkm i.NMDs  
*eststo SecondarySchools: areg secondary_schools log_WSF19POP17 c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm , absorb(NMDs)
outreg2 . using "$tables/elasticity_estimates_highersecondary_all.xls", replace

*---
*COlleges for boys + girls
eststo Colleges: reg Colleges log_WSF19POP17 c.log_WSF19POP17#i.NMDs // log_WSF19_Pop_densitysqkm i.NMDs  
*eststo Colleges: areg colleges log_WSF19POP17 c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm , absorb(NMDs)
outreg2 . using "$tables/elasticity_estimates_colleges_all.xls", replace

*---
*Religious schools for boys + girls
eststo Madrassahs: reg Madrassahs log_WSF19POP17 c.log_WSF19POP17#i.NMDs // log_WSF19_Pop_densitysqkm i.NMDs  
*eststo Madrassahs: areg madrassah log_WSF19POP17 c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm , absorb(NMDs)
outreg2 . using "$tables/elasticity_estimates_madrassah_all.xls", replace

*---
*Health Facilities
*eststo Hospitals_PopDensity: reg health_facilities log_WSF19_Pop_densitysqkm  
*outreg2 . using "$tables/elasticity_estimates_hlth1.xls", replace

eststo Hospitals: reg Hospitals log_WSF19POP17  c.log_WSF19POP17#i.NMDs //log_WSF19_Pop_densitysqkm i.NMDs 
*eststo Hospitals: areg health_facilities log_WSF19POP17  c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm , absorb(NMDs)
outreg2 . using "$tables/elasticity_estimates_hospitals.xls", replace

*replace hospitals  = hospitals + _b[log_WSF19POP17] * pop_gr2025
predict hospitals_pred, xb 
predict hospitals_delta, residuals

gen hospitals_new =  hospitals_pred * (1+pop_gr2025)
gen hospitals_needed2025 = round(hospitals_new - hospitals_pred) 

*---
*POlice Stations
*eststo PoliceSt_PopDensity: reg police_stations log_WSF19_Pop_densitysqkm 
*outreg2 . using "$tables/elasticity_estimates_adm1.xls", replace

eststo PoliceStations: reg PoliceStations log_WSF19POP17 c.log_WSF19POP17#i.NMDs //log_WSF19_Pop_densitysqkm i.NMDs  
*eststo PoliceStations: areg police_stations log_WSF19POP17 c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm , absorb(NMDs)
outreg2 . using "$tables/elasticity_estimates_policest.xls", replace

*replace  police_stat =  police_stat + _b[log_WSF19POP17] * pop_gr2025
predict policestat_pred, xb 
predict policestat_delta, residuals 

gen policestat_new =  policestat_pred * (1+pop_gr2025)  
gen police_stat_needed2025 = round(policestat_new - policestat_pred) 

*---
*Whoelsale Markets
eststo WholesaleMarkets: reg WholesaleMarkets log_WSF19POP17 c.log_WSF19POP17#i.NMDs //log_WSF19_Pop_densitysqkm i.NMDs  
*eststo WholesaleMarkets: areg wholesale_markets log_WSF19POP17 c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm , absorb(NMDs)
outreg2 . using "$tables/elasticity_estimates_wholesalemarkets.xls", replace

*---
* Markets and Bazzars in mouzas - aggregated at tehsil level
eststo Markets: reg Markets log_WSF19POP17 c.log_WSF19POP17#i.NMDs //log_WSF19_Pop_densitysqkm i.NMDs  
*eststo Markets: areg markets log_WSF19POP17 c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm , absorb(NMDs)
outreg2 . using "$tables/elasticity_estimates_markets.xls", replace

est dir


* Holding the population per school benchmark constant at 2020 levels - Otherwise we're allowing average schools to nearly double in capacity

 gen pop_per_pred_prim_school 	  = WSF19POP17 / PrimarySchools_yhat    
 gen pop_per_pred_midl_school 	  = WSF19POP17 / MiddleSchools_yhat   
 gen pop_per_pred_secd_school 	  = WSF19POP17 / SecondarySchools_yhat  
 gen pop_per_pred_colg		  	  = WSF19POP17 / Colleges_yhat  
 gen pop_per_pred_hospl	  	  	  = WSF19POP17 / Hospitals_yhat
 gen pop_per_pred_makt 		  	  = WSF19POP17 / WholesaleMarkets_yhat
 
 *2025
* gen pop_per_pred_prim_school_25  = WSF19_TehsilPop_2025 / PrimarySchools_25    
* gen pop_per_pred_midl_school_25  = WSF19_TehsilPop_2025 / MiddleSchools_25   
* gen pop_per_pred_secd_school_25  = WSF19_TehsilPop_2025 / SecondarySchools_25  
* gen pop_per_pred_colg_25		  = WSF19_TehsilPop_2025 / Colleges_25  
* gen pop_per_pred_hospl_25	  	  = WSF19_TehsilPop_2025 / Hospitals_25
* gen pop_per_pred_makt_25 		  = WSF19_TehsilPop_2025 / WholesaleMarkets_25

 *2030
* gen pop_per_pred_prim_school_30  = WSF19_TehsilPop_2030 / PrimarySchools_30   
* gen pop_per_pred_midl_school_30  = WSF19_TehsilPop_2030 / MiddleSchools_30   
* gen pop_per_pred_secd_school_30  = WSF19_TehsilPop_2030 / SecondarySchools_30  
* gen pop_per_pred_colg_30		  = WSF19_TehsilPop_2030 / Colleges_30  
* gen pop_per_pred_hospl_30	  	  = WSF19_TehsilPop_2030 / Hospitals_30
* gen pop_per_pred_makt_30		  = WSF19_TehsilPop_2030 / WholesaleMarkets_30
 
 drop if ADM3_NAME == "Bar Chamarkand"     //Since negative average due to very very small population - WSF issue to discuss

 *2020
 global averages "pop_per_pred_prim_school pop_per_pred_midl_school pop_per_pred_secd_school pop_per_pred_colg pop_per_pred_hospl pop_per_pred_makt"
  
 foreach avg of varlist $averages {
 
 *gsort pop_per_pred_prim_school     // Kalam has 1168 people????
 gsort `avg'
 
 *Taking average of top 20% of the tehsils as population per school benchmark for rural areas
 *list pop_per_pred_school in 1/26
 
 preserve
 
 keep in 1/26   //10%    //10  26
 
 *sum pop_per_pred_school
 sum `avg'
 
 local top =  r(mean)
 di "`top'"    //581.71 people / school
 
 restore

 gen top_`avg' = r(mean)
 
 label var top_`avg' "Population per predicted facililites - Benchmark 2020"
 
 }
/*
*2025
global averages2025 "pop_per_pred_prim_school_25 pop_per_pred_midl_school_25 pop_per_pred_secd_school_25 pop_per_pred_colg_25 pop_per_pred_hospl_25 pop_per_pred_makt_25"
  
 foreach avg of varlist $averages2025 {
 
 *gsort pop_per_pred_prim_school     // Kalam has 1168 people????
 gsort `avg'
 
 *Taking average of top 20% of the tehsils as population per school benchmark for rural areas
 *list pop_per_pred_school in 1/26
 
 preserve
 
 keep in 1/26   //10%    //10  26
 
 *sum pop_per_pred_school
 sum `avg'
 
 local top =  r(mean)
 di "`top'"    //581.71 people / school
 
 restore

 gen top_`avg' = r(mean)
 
 label var top_`avg' "Population per predicted facililites - 2025 Benchmark"
 
 } 
 
*2030
global averages2030 "pop_per_pred_prim_school_30 pop_per_pred_midl_school_30 pop_per_pred_secd_school_30 pop_per_pred_colg_30 pop_per_pred_hospl_30 pop_per_pred_makt_30"
  
 foreach avg of varlist $averages2030 {
 
 *gsort pop_per_pred_prim_school     // Kalam has 1168 people????
 gsort `avg'
 
 *Taking average of top 20% of the tehsils as population per school benchmark for rural areas
 *list pop_per_pred_school in 1/26
 
 preserve
 
 keep in 1/26   //10%    //10  26
 
 *sum pop_per_pred_school
 sum `avg'
 
 local top =  r(mean)
 di "`top'"    //581.71 people / school
 
 restore

 gen top_`avg' = r(mean)
 
 label var top_`avg' "Population per predicted facililites - 2030 Benchmark"
 
 }  
*/
 * Benchmark - Population per actual school
	 gen pop_per_actual_prim_school = WSF19POP17 / PrimarySchools
	 gen pop_per_actual_midl_school = WSF19POP17 / MiddleSchools
	 gen pop_per_actual_secd_school = WSF19POP17 / SecondarySchools
	 gen pop_per_actual_colg_school = WSF19POP17 / Colleges
	 gen pop_per_actual_hospl       = WSF19POP17 / Hospitals
	 gen pop_per_actual_makt        = WSF19POP17 / WholesaleMarkets    

	*global actual_fac "pop_per_actual_prim_school pop_per_actual_midl_school pop_per_actual_secd_school pop_per_actual_colg_school pop_per_actual_hospl pop_per_actual_makt"
 
*foreach act of varlist $actual_fac{
 
 *gen pop_per_pred_school_diff =   pop_per_pred_school  - `prim'
 *gen `act'_diff =   $actual_fac  - `top'        // `avg'
*2020 
 gen pop_per_actual_prim_school_diff = pop_per_actual_prim_school - top_pop_per_pred_prim_school
 gen pop_per_actual_midl_school_diff = pop_per_actual_midl_school - top_pop_per_pred_midl_school
 gen pop_per_actual_secd_school_diff = pop_per_actual_secd_school - top_pop_per_pred_secd_school
 gen pop_per_actual_colg_school_diff = pop_per_actual_colg_school - top_pop_per_pred_colg
 gen pop_per_actual_hospl_diff       = pop_per_actual_hospl       - top_pop_per_pred_hospl
 gen pop_per_actual_makt_diff        = pop_per_actual_makt        - top_pop_per_pred_makt    
 
*2025
 gen pop_per_act_prim_school_25_diff = pop_per_actual_prim_school - top_pop_per_pred_prim_school_25
 gen pop_per_act_midl_school_25_diff = pop_per_actual_midl_school - top_pop_per_pred_midl_school_25
 gen pop_per_act_secd_school_25_diff = pop_per_actual_secd_school - top_pop_per_pred_secd_school_25
 gen pop_per_act_colg_school_25_diff = pop_per_actual_colg_school - top_pop_per_pred_colg_25
 gen pop_per_act_hospl_25_diff       = pop_per_actual_hospl       - top_pop_per_pred_hospl_25
 gen pop_per_act_makt_25_diff        = pop_per_actual_makt        - top_pop_per_pred_makt_25
 
*2030
 gen pop_per_act_prim_school_30_diff = pop_per_actual_prim_school - top_pop_per_pred_prim_school_30
 gen pop_per_act_midl_school_30_diff = pop_per_actual_midl_school - top_pop_per_pred_midl_school_30
 gen pop_per_act_secd_school_30_diff = pop_per_actual_secd_school - top_pop_per_pred_secd_school_30
 gen pop_per_act_colg_school_30_diff = pop_per_actual_colg_school - top_pop_per_pred_colg_30
 gen pop_per_act_hospl_30_diff       = pop_per_actual_hospl       - top_pop_per_pred_hospl_30
 gen pop_per_act_makt_30_diff        = pop_per_actual_makt        - top_pop_per_pred_makt_30
 
 *gen new_prim_req = round(pop_per_pred_school_diff / `prim')    //Additinal schools required
 *gen new_req_`avg' = round(`avg'_diff / `top') 
 
*2020 
 gen req_pop_per_actual_prim_school = round(pop_per_actual_prim_school_diff / top_pop_per_pred_prim_school)   //use actual here instead   
 gen req_pop_per_actual_midl_school = round(pop_per_actual_midl_school_diff / top_pop_per_pred_midl_school)   //top_pop_per_pred_midl_school
 gen req_pop_per_actual_secd_school = round(pop_per_actual_secd_school_diff / top_pop_per_pred_secd_school)   //top_pop_per_pred_secd_school
 gen req_pop_per_actual_colg_school = round(pop_per_actual_colg_school_diff / top_pop_per_pred_colg)   //top_pop_per_pred_colg
 gen req_pop_per_actual_hospl       = round(pop_per_actual_hospl_diff       / top_pop_per_pred_hospl)   //top_pop_per_pred_hospl
 gen req_pop_per_actual_makt        = round(pop_per_actual_makt_diff        / top_pop_per_pred_makt)   // top_pop_per_pred_makt
 
 *2025
 gen req_pop_per_ac_prim_school_25  = round(pop_per_act_prim_school_25_diff  / top_pop_per_pred_prim_school_25)   //use actual here instead   
 gen req_pop_per_act_midl_school_25 = round(pop_per_act_midl_school_25_diff / top_pop_per_pred_midl_school_25)   //top_pop_per_pred_midl_school
 gen req_pop_per_act_secd_school_25 = round(pop_per_act_secd_school_25_diff / top_pop_per_pred_secd_school_25)   //top_pop_per_pred_secd_school
 gen req_pop_per_act_colg_school_25 = round(pop_per_act_colg_school_25_diff / top_pop_per_pred_colg_25)   //top_pop_per_pred_colg
 gen req_pop_per_act_hospl_25       = round(pop_per_act_hospl_25_diff       / top_pop_per_pred_hospl_25)   //top_pop_per_pred_hospl
 gen req_pop_per_act_makt_25        = round(pop_per_act_makt_25_diff        / top_pop_per_pred_makt_25)   // top_pop_per_pred_makt
 
 *2030
 gen req_pop_per_ac_prim_school_30 	= round(pop_per_act_prim_school_30_diff  / top_pop_per_pred_prim_school_30)   //use actual here instead   
 gen req_pop_per_act_midl_school_30 = round(pop_per_act_midl_school_30_diff / top_pop_per_pred_midl_school_30)   //top_pop_per_pred_midl_school
 gen req_pop_per_act_secd_school_30 = round(pop_per_act_secd_school_30_diff / top_pop_per_pred_secd_school_30)   //top_pop_per_pred_secd_school
 gen req_pop_per_act_colg_school_30 = round(pop_per_act_colg_school_30_diff / top_pop_per_pred_colg_30)   //top_pop_per_pred_colg
 gen req_pop_per_act_hospl_30       = round(pop_per_act_hospl_30_diff       / top_pop_per_pred_hospl_30)   //top_pop_per_pred_hospl
 gen req_pop_per_act_makt_30        = round(pop_per_act_makt_30_diff        / top_pop_per_pred_makt_30)   // top_pop_per_pred_makt
 
  *****
