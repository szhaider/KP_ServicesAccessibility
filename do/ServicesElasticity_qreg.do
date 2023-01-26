

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
		
	eststo `var' : qreg `var' logpop20 c.logpop20#i.NMDs log_Adm3_Area_sqkm, quantile(.8) vce(robust) // absorb(NMDs)  nocons   log_WSF19_Pop_densitysqkm
	
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

rename *_yhat *_20

*Tehsil where no additional facilities required = 0
foreach var of varlist $Models {
	foreach i of numlist 20 25 30 {
gen New`var'_`i'= `var'_`i'- `var'
replace New`var'_`i'=0 if New`var'_`i'<0

	}
}

*Marginal facilities needed
local NewModels "NewPrimarySchools NewMiddleSchools NewSecondarySchools NewColleges NewHospitals NewWholesaleMarkets"

foreach var of  local NewModels {

foreach i of numlist 25 30{
	gen marginal_`var'_`i' = `var'_`i' - `var'_20
	}

}

*-------------------------------------------------------------------------------
*Coef plot for over all KP

coefplot $Models , yline(0) vertical title("Elasticity Estimates (Log Linear)") ///
ytitle("Change in basic services due to Population Growth (%)") drop(_cons log_Adm3_Area_sqkm) ///  log_WSF19_Pop_densitysqkm
subtitle("Controlling for Tehsil Area (sq-km)")  ///
		  recast(bar) ciopts(recast(rcap)) citop barwidt(0.07) ///  
		  note("Source: Authors' calculations based on Mouza Census 2020 & WSF19")
graph export "$figures/coefplot_allcategories.png", replace	
*-------------------------------------------------------------------------------
 
 preserve
 
drop if NewPrimarySchools_20 == 0   & NMDs == 1
 
 graph hbar NewPrimarySchools_20  marginal_NewPrimarySchools_25 marginal_NewPrimarySchools_30 if NMDs == 1, stack over(ADM3_NAME, sort(NewPrimarySchools_20 descending) ///
 lab(labsize(vsmall))) ytitle("Additional primary schools required") ///
 title("NMAs: Based on Model Averages (yhats)") ///
 legend(label(1 "Base 2020") label(2 "Projected 2025") label(3 "Projected 2030"))
 
 graph export "$figures/primary_NMDs_additional.png", replace  
 
 restore
 
 *****
 
 preserve
 
 drop if NewMiddleSchools_20 == 0 & NMDs == 1
 
 graph hbar NewMiddleSchools_20 marginal_NewMiddleSchools_25 marginal_NewMiddleSchools_30   if NMDs == 1, stack over(ADM3_NAME, sort(NewMiddleSchools_20 descending) ///
 lab(labsize(vsmall))) ytitle("Additional middle schools required") ///
 title("NMAs: Based on Model Averages (yhat)") ///
 legend(label(1 "Base 2020") label(2 "Projected 2025") label(3 "Projected 2030"))
 
 graph export "$figures/middle_NMDs_additional.png", replace  
 
 restore

  *****
 preserve
 
 drop if  NewSecondarySchools_20 == 0 & NMDs == 1
 
 graph hbar  NewSecondarySchools_20 marginal_NewSecondarySchools_25 marginal_NewSecondarySchools_30  if NMDs == 1, stack over(ADM3_NAME, sort(NewSecondarySchools_20 descending) ///
 lab(labsize(vsmall))) ytitle("Additional Higher Secondary schools required") ///
 title("NMAs: Based on Model Averages (yhat)") ///
 legend(label(1 "Base 2020") label(2 "Projected 2025") label(3 "Projected 2030"))
 
 
 graph export "$figures/secondary_NMDs_additional.png", replace  
 
 restore
 
 ******
 preserve
 
drop if NewHospitals_20 == 0  & NMDs == 1
 
 graph hbar NewHospitals_20   marginal_NewHospitals_25 marginal_NewHospitals_30 if NMDs == 1, stack over(ADM3_NAME, sort(NewHospitals_20 descending) ///
 lab(labsize(vsmall))) ytitle("Additional Hospitals/Dispencaries required") ///
 title("NMAs: Based on Model Averages (yhat)") ///
 legend(label(1 "Base 2020") label(2 "Marginal 2025") label(3 "Marginal 2030"))
 
 graph export "$figures/hospitals_NMDs_additional.png", replace  
 
 restore
  
 
