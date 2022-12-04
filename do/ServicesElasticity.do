

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
clonevar primary_schools = pri_schl_tot
clonevar hospitals = health_facilities
clonevar police_stat = police_stations

est clear

gen log_primary_schools = log(primary_schools)
gen log_WSF19POP17 = log(WSF19POP17)
gen log_WSF19_Pop_densitysqkm = log(WSF19_Pop_densitysqkm)

gen pop_gr2025  = ((WSF19_TehsilPop_2025 - WSF19POP17)/WSF19POP17)
gen log_Adm3_Area_sqkm = log(Adm3_Area_sqkm)

areg primary_schools log_WSF19POP17 c.log_WSF19POP17#c.NMDs  log_WSF19_Pop_densitysqkm, absorb(NMDs)    //Tobediscussed

*Education Facilities   (play with only primary etc)
*eststo PrimarySchools_PopDensity: reg edu_inst_tot log_WSF19_Pop_densitysqkm    //preferred    [settlement weighted] [aw=p1q10]
*outreg2 . using "$tables/elasticity_estimates_edu1.xls", replace

eststo PrimarySchools: reg primary_schools log_WSF19POP17 c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm i.NMDs  
eststo PrimarySchools: areg primary_schools log_WSF19POP17 c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm , absorb(NMDs)
outreg2 . using "$tables/elasticity_estimates_primary_all.xls", replace

*lvr2plot
*rvfplot
*rvpplot log_WSF19POP17
*gen log_WSF19_TehsilPop_2025 = log(WSF19_TehsilPop_2025)
*avplots 

*---
*Predict
predict primary_schools_pred, xb 
predict primary_delta, residuals

*gen delta_primary = primary_schools_pred - primary_schools   //errors

*gen log_WSF19_TehsilPop_2025 = log(WSF19_TehsilPop_2025)
gen primary_schools_new =  primary_schools_pred * (1+pop_gr2025)
gen primary_schools_needed2025 = round(primary_schools_new - primary_schools_pred) 

*gen schools  = primary_schools + (_b[log_WSF19POP17] * (1+pop_gr2025))
*gen new_schools = schools - primary_schools

*---

*replace  primary_schools = primary_schools + _b[log_WSF19POP17] * (1+pop_gr2025)
*predict primary_schools_p, xb 

*Health Facilities
*eststo Hospitals_PopDensity: reg health_facilities log_WSF19_Pop_densitysqkm  
*outreg2 . using "$tables/elasticity_estimates_hlth1.xls", replace

*eststo Hospitals: reg health_facilities log_WSF19POP17  c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm i.NMDs 
eststo Hospitals: areg health_facilities log_WSF19POP17  c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm , absorb(NMDs)
outreg2 . using "$tables/elasticity_estimates_hospitals.xls", replace

*replace hospitals  = hospitals + _b[log_WSF19POP17] * pop_gr2025
predict hospitals_pred, xb 
predict hospitals_delta, residuals

gen hospitals_new =  hospitals_pred * (1+pop_gr2025)
gen hospitals_needed2025 = round(hospitals_new - hospitals_pred) 

*POlice Stations
*eststo PoliceSt_PopDensity: reg police_stations log_WSF19_Pop_densitysqkm 
*outreg2 . using "$tables/elasticity_estimates_adm1.xls", replace

*eststo PoliceStations: reg police_stations log_WSF19POP17 c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm i.NMDs  
eststo PoliceStations: areg police_stations log_WSF19POP17 c.log_WSF19POP17#i.NMDs log_WSF19_Pop_densitysqkm , absorb(NMDs)
outreg2 . using "$tables/elasticity_estimates_policest.xls", replace

*replace  police_stat =  police_stat + _b[log_WSF19POP17] * pop_gr2025
predict policestat_pred, xb 
predict policestat_delta, residuals 

gen policestat_new =  policestat_pred * (1+pop_gr2025)  
gen police_stat_needed2025 = round(policestat_new - policestat_pred) 

est dir

coefplot PrimarySchools Hospitals PoliceStations , yline(0) vertical title("Elasticity Estimates (Log Linear)") subtitle("Controlling for NMDs Fixed Effect") ytitle("Change in basic services due to Population Growth (%)") drop(_cons) ///
		  recast(bar) ciopts(recast(rcap)) citop barwidt(0.1) ///  subtitle("Controlling for NMDs Fixed Effect") 
		  note("Source: Authors' calculations")
graph export "$figures/coefplot_FEs&PopDensity.png", replace
		 		 
*order edu_inst_tot primary_schools health_facilities hospitals police_stations police_stat, last 		

*gen Primary_schools_needed2025 = round(primary_schools - edu_inst_tot)
*gen Hospitals_needed2025 = round(hospitals- health_facilities)
*gen PoliceStations_needed2025 = round(police_stat - police_stations)

*graph hbar  Primary_schools_needed, over(ADM3_NAME)
 
*-------------------------------------------------------------------------------

*export excel using "$xlsx/facilities_needed_v1.xlsx" if NMDs == 1, first(variable) replace
