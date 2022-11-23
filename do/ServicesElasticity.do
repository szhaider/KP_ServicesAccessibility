

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
*WE have 133 TEHSILS for regressions

import excel using "$xlsx/fuzzyjoin_adm3.xlsx", first clear
drop Similarity
drop ADM3_CODE
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

order ADM3_NAME

*Combining with Tehsil level Popualtion numbers
merge m:1 ADM3_NAME using  "$output/population_number.dta"      //same 133 tehsils matched
keep if _m == 3
drop _m

*-------------------------------------------------------------------------------

*Elasticities estimation
clonevar primary_schools = edu_inst_tot
clonevar hospitals = health_facilities
clonevar police_stat = police_stations

est clear

gen log_edu_inst_tot = log(edu_inst_tot)
gen log_WSF19POP17 = log(WSF19POP17)
gen log_WSF19_Pop_densitysqkm = log(WSF19_Pop_densitysqkm)

gen pop_gr2025  = ((WSF19_TehsilPop_2025 - WSF19POP17)/WSF19POP17) + 1


reg edu_inst_tot WSF19_Pop_densitysqkm

*Education Facilities   (play with only primary etc)
eststo PrimarySchools_PopDensity: reg edu_inst_tot log_WSF19_Pop_densitysqkm    //preferred    [settlement weighted] [aw=p1q10]
outreg2 . using "$tables/elasticity_estimates_edu1.xls", replace

eststo PrimarySchools_Population: reg edu_inst_tot log_WSF19POP17  
outreg2 . using "$tables/elasticity_estimates_edu2.xls", replace

replace  primary_schools = primary_schools + _b[log_WSF19POP17] * pop_gr2025
predict primary_schools_p, xb 


*Health Facilities
eststo Hospitals_PopDensity: reg health_facilities log_WSF19_Pop_densitysqkm  
outreg2 . using "$tables/elasticity_estimates_hlth1.xls", replace

eststo Hospitals_Population: reg health_facilities log_WSF19POP17  
outreg2 . using "$tables/elasticity_estimates_hlth2.xls", replace

replace hospitals  = hospitals + _b[log_WSF19POP17] * pop_gr2025
predict hospitals_p, xb 


*POlice Stations
eststo PoliceSt_PopDensity: reg police_stations log_WSF19_Pop_densitysqkm 
outreg2 . using "$tables/elasticity_estimates_adm1.xls", replace

eststo PoliceSt_Population: reg police_stations log_WSF19POP17 
outreg2 . using "$tables/elasticity_estimates_adm2.xls", replace

replace  police_stat =  police_stat + _b[log_WSF19POP17] * pop_gr2025
predict police_stat_p, xb 


est dir

coefplot PrimarySchools_Population Hospitals_Population PoliceSt_Population PrimarySchools_PopDensity  Hospitals_PopDensity  PoliceSt_PopDensity , yline(0) vertical title("Elasticity Estimates (Log Linear)")  ytitle("Change in services (sums) due to chnage in Population (%)") drop(_cons) ///
		  recast(bar) ciopts(recast(rcap)) citop barwidt(0.1) ///
		  note("Source: Authors' Calculations")
graph export "$figures/coefplot.png", replace
		 
		 
order edu_inst_tot primary_schools health_facilities hospitals police_stations police_stat, last 		

gen Primary_schools_needed2025 = round(primary_schools - edu_inst_tot)
gen Hospitals_needed2025 = round(hospitals- health_facilities)
gen PoliceStations_needed2025 = round(police_stat - police_stations)

*graph hbar  Primary_schools_needed, over(ADM3_NAME)


 
*-------------------------------------------------------------------------------
/*
*Predicting Services based on  Population growth

clonevar primary_schools = edu_inst_tot
clonevar hospitals = health_facilities
clonevar police_stat = police_stations

gen  primary_schools1 = primary_schools + _b[log_WSF19POP17]

*gen  primary_schools3 = primary_schools + (_b[log_WSF19POP17] * (Cen2017_AvgPopGrRates * 100) * 6)


gen pop_gr  = ((WSF19_TehsilPop_2025 - WSF19POP17)/WSF19POP17) + 1
gen  primary_schools4 = primary_schools + _b[log_WSF19POP17] * pop_gr



gen log_WSF19_TehsilPop_2025 = log(WSF19_TehsilPop_2025)
 reg edu_inst_tot log_WSF19_TehsilPop_2025 




