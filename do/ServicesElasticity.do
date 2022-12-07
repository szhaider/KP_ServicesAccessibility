

*Regressions

*-------------------------------------------------------------------------------

/*
*Population Data for regressions  (To upadte this data, first update the excel input)

import excel using "$xlsx/population/KP_WSF_adm3_Pop.xlsx", first clear
drop if _n == _N   //Dropping totals
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

*drop if ADM3_NAME == "Bar Chamarkand"     //outlier since number of schools < log pop and other services 0 (This is NMD tehsil!!!!!!!)

gen NMDs = 1 if ADM2_NAME == "Bajaur" | ADM2_NAME == "Khyber" | ADM2_NAME == "Kurram" | ADM2_NAME == "Mohmand" | ADM2_NAME == "North Waziristan" | ADM2_NAME == "Orakzai" | ADM2_NAME == "South Waziristan" 
replace NMDs = 0 if NMDs == .
tab NMDs,m             //39 NMD tehsils

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
gen log_WSF19POP17 = log(WSF19POP17)
gen log_WSF19_Pop_densitysqkm = log(WSF19_Pop_densitysqkm)

gen pop_gr2025  = ((WSF19_TehsilPop_2025 - WSF19POP17)/WSF19POP17)
gen pop_gr2030  = ((WSF19_TehsilPop_2030 - WSF19POP17)/WSF19POP17)

gen log_Adm3_Area_sqkm = log(Adm3_Area_sqkm)

*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
*Overall Elasticity estimates (KP Province)
est clear

global Models "PrimarySchools MiddleSchools SecondarySchools Colleges Hospitals WholesaleMarkets"

foreach var of varlist $Models {
	
	eststo `var' : reg `var' log_WSF19POP17 c.log_WSF19POP17#i.NMDs
	
	predict `var'_yhat, xb
	predict `var'_delta, residuals
	
	replace `var'_yhat = round(`var'_yhat)
	replace `var'_delta = round(`var'_delta)
	
	gen `var'_yhat_2025 = round(`var'_yhat * (1+pop_gr2025))   //delta prjection 2025
	gen `var'_yhat_2030 = round(`var'_yhat * (1+pop_gr2030))   //delta prjection 2030
	
	gen `var'_delta_2025 = round(`var'_delta * (1+pop_gr2025))   //delta prjection 2025
	gen `var'_delta_2030 = round(`var'_delta * (1+pop_gr2030))   //delta prjection 2030

	outreg2 . using "$tables/elasticity_estimates_`var'.xls", replace

}

est dir
*-------------------------------------------------------------------------------

*Deltas Visualization for NMD tehsils in KP

graph hbar PrimarySchools_delta PrimarySchools_delta_2025 PrimarySchools_delta_2030 if NMDs == 1, over(ADM3_NAME, sort(PrimarySchools_delta descending) lab(labsize(tiny))) ytitle("Predictions (number of primary schools)") title("Model Predictions: y-yhat") subtitle("Newly Merged Tehsils")  legend( label(1 "Primary Schools 2019") label(2 "Primary Schools 2025") label(3 "Primary Schools 2030") ) 
graph export "$figures/primary_tehsil_deltas.png", replace  

graph hbar MiddleSchools_delta MiddleSchools_delta_2025 MiddleSchools_delta_2030 if NMDs == 1, over(ADM3_NAME, sort(MiddleSchools_delta descending) lab(labsize(tiny))) ytitle("Predictions (number of middle schools)") title("Model Predictions: y-yhat") subtitle("Newly Merged Tehsils")  legend( label(1 "Middle Schools 2019") label(2 "Middle Schools 2025") label(3 "Midddle Schools 2030") ) 
graph export "$figures/middle_tehsil_deltas.png", replace  

graph hbar SecondarySchools_delta SecondarySchools_delta_2025 SecondarySchools_delta_2030 if NMDs == 1, over(ADM3_NAME, sort(SecondarySchools_delta descending) lab(labsize(tiny))) ytitle("Predictions (number of secondary schools)") title("Model Predictions: y-yhat") subtitle("Newly Merged Tehsils")  legend( label(1 "Secondary Schools 2019") label(2 "Secondary Schools 2025") label(3 "Secondary Schools 2030") ) 
graph export "$figures/Secondary_tehsil_deltas.png", replace  


graph hbar Hospitals_delta Hospitals_delta_2025 Hospitals_delta_2030 if NMDs == 1, over(ADM3_NAME, sort(Hospitals_delta descending) lab(labsize(tiny))) ytitle("Predictions (number of secondary schools)") title("Model Predictions: y-yhat") subtitle("Newly Merged Tehsils")  legend( label(1 "Hospitals 2019") label(2 "Hospitals 2025") label(3 "Hospitals 2030") ) 
graph export "$figures/hospitals_tehsil_deltas.png", replace  

*-------------------------------------------------------------------------------
*Coef plot for over all KP

coefplot $Models , yline(0) vertical title("Elasticity Estimates (Log Linear)") ///
ytitle("Change in basic services due to Population Growth (%)") drop(_cons) ///
		  recast(bar) ciopts(recast(rcap)) citop barwidt(0.07) ///  subtitle("Controlling for NMDs Fixed Effect") 
		  note("Source: Authors' calculations based on Mouza Census 2020 & WSF19")
graph export "$figures/coefplot_allcategories.png", replace	
*-------------------------------------------------------------------------------
*Elasticity Estimates KP :  with and without NMDs

est clear

global Models "PrimarySchools MiddleSchools SecondarySchools Colleges Hospitals WholesaleMarkets"

levelsof NMDs, local(NMD)

foreach var of varlist $Models {
	
	foreach num of local NMD {
	
	eststo `var'_`num' : reg `var' log_WSF19POP17 if NMDs == `num' 

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
