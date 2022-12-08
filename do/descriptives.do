*Descriptive Analysis

*-------------------------------------------------------------------------------
graph drop _all
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

*-------------------------------------------------------------------------------

glo kppop WSF19POP17
gen WSF19POP17_th = $kppop/1000
glo pop WSF19POP17_th



gen NMDs = 1 if ADM2_NAME == "Bajaur" | ADM2_NAME == "Khyber" | ADM2_NAME == "Kurram" | ADM2_NAME == "Mohmand" | ADM2_NAME == "North Waziristan" | ADM2_NAME == "Orakzai" | ADM2_NAME == "South Waziristan" 
replace NMDs = 0 if NMDs == .
tab NMDs,m             
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
*Education Scatters

/*
Scatter with Tehsil population and  each of the service categories
*/

*--Primary schools

local f0 = "red"
local f1 = "blue"

*twoway (scatter  pri_schl_tot $pop , title("Primary Schools & Population") xtitle("Population (000s)") ytitle("Total Primary Schools (Boys + Girls)") name("graph_primary", replace) legend(off)) (lfit pri_schl_tot $pop) 

twoway (scatter pri_schl_tot $pop if NMDs==0, msymbol(Oh) mcolor(`f0') title("Primary Schools & Population") legend(label(1 "Other KP Tehsils") label(2 "Newly Merged Tehsils")) name("graph_primary", replace)) ///
       (scatter pri_schl_tot $pop  if NMDs==1, msymbol(Oh) mcolor(`f1')  legend( label(1 "Other KP Tehsils") label(2 "Newly Merged Tehsils") ) ///
	   ytitle("Total Primary Schools (Boys + Girls)") xtitle("Population (000s)")) ///
	   (lfit pri_schl_tot $pop ) 
	  graph export "$figures/primary_population_scatter.png", replace

*--Middle schools
*twoway (scatter  mid_schl_tot $pop , title("Middle Schools & Population")  xtitle("Population (000s)") ytitle("Total Middle Schools (Boys + Girls)")  name("graph_middle", replace) legend(off)) (lfit mid_schl_tot $pop) 
twoway (scatter mid_schl_tot $pop if NMDs==0, msymbol(Oh) mcolor(`f0') title("Middle Schools & Population") legend(label(1 "Other KP Tehsils") label(2 "Newly Merged Tehsils")) name("graph_middle", replace)) ///
       (scatter mid_schl_tot $pop  if NMDs==1, msymbol(Oh) mcolor(`f1')  legend( label(1 "Other KP Tehsils") label(2 "Newly Merged Tehsils") ) ///
	   ytitle("Total Middle Schools (Boys + Girls)") xtitle("Population (000s)")) ///
	   (lfit mid_schl_tot $pop ) 
graph export "$figures/middle_population_scatter.png", replace

*--Higher Secondary schools
*twoway (scatter  sec_schl_tot $pop , title("Higher Secondary Schools & Population")  xtitle("Population (000s)") ytitle("Total Higher Secondary Schools (Boys + Girls)")  name("graph_secondary", replace) legend(off)) (lfit sec_schl_tot $pop) 
twoway (scatter sec_schl_tot $pop if NMDs==0, msymbol(Oh) mcolor(`f0')  title("Higher Secondary Schools & Population") legend(label(1 "Other KP Tehsils") label(2 "Newly Merged Tehsils")) name("graph_secondary", replace)) ///
       (scatter sec_schl_tot $pop  if NMDs==1, msymbol(Oh) mcolor(`f1')  legend( label(1 "Other KP Tehsils") label(2 "Newly Merged Tehsils") ) ///
	   ytitle("Total Secondary Schools (Boys + Girls)") xtitle("Population (000s)")) ///
	   (lfit sec_schl_tot $pop ) 
graph export "$figures/secondary_population_scatter.png", replace

*--Colleges
*twoway (scatter col_tot  $pop , title("Colleges & Population") xtitle("Population (000s)") ytitle("Total Colleges (Boys + Girls)")  name("graph_colleges", replace) legend(off)) (lfit col_tot $pop) 
twoway (scatter col_tot $pop if NMDs==0, msymbol(Oh) mcolor(`f0') title("Colleges & Population")legend(label(1 "Other KP Tehsils") label(2 "Newly Merged Tehsils")) name("graph_colleges", replace)) ///
       (scatter col_tot $pop  if NMDs==1, msymbol(Oh) mcolor(`f1')  legend( label(1 "Other KP Tehsils") label(2 "Newly Merged Tehsils") ) ///
	   ytitle("Total Colleges (Boys + Girls)") xtitle("Population (000s)")) ///
	   (lfit col_tot $pop ) 
graph export "$figures/colleges_population_scatter.png", replace

graph combine graph_primary graph_middle graph_secondary graph_colleges, title("Correlation b/w Educational Institutions and Population") subtitle("Khyber Pakhtunkhwa: Tehsils (adm3)")  note("Source: Mouza Census 2020 & WSF19")
graph export "$figures/combined_edu_scatter.png", replace
*-------------------------------------------------------------------------------
*Health Services

*Hospitals and Dispenceries

*twoway (scatter health_facilities  $pop , title("Hospitals & Population")  xtitle("Population (000s)") ytitle("Total Hospitals/Dispenceries")  name("graph_hospitals", replace) legend(off)) (lfit health_facilities $pop) 

twoway (scatter health_facilities $pop if NMDs==0, msymbol(Oh) mcolor(`f0') title("Hospitals & Population") legend(label(1 "Other KP Tehsils") label(2 "Newly Merged Tehsils")) name("graph_hospitals", replace)) ///
       (scatter health_facilities $pop  if NMDs==1, msymbol(Oh) mcolor(`f1')  legend( label(1 "Other KP Tehsils") label(2 "Newly Merged Tehsils") ) ///
	   ytitle("Total Hospitals") xtitle("Population (000s)")) ///
	   (lfit health_facilities $pop ) 
graph export "$figures/health_facilities_population_scatter.png", replace
*-------------------------------------------------------------------------------
*Wholesale markets
*twoway (scatter  p6q1311_admin_fac $pop , title("Wholesale Markets & Population")  xtitle("Population (000s)") ytitle("Total Wholesale Markets")  name("graph_wholesalemkts", replace) legend(off)) (lfit p6q1311_admin_fac $pop) 

twoway (scatter p6q1311_admin_fac $pop if NMDs==0, msymbol(Oh) mcolor(`f0') title("Wholesale Markets & Population") legend(label(1 "Other KP Tehsils") label(2 "Newly Merged Tehsils")) name("graph_wholesalemkts", replace)) ///
       (scatter p6q1311_admin_fac $pop  if NMDs==1, msymbol(Oh) mcolor(`f1')  legend( label(1 "Other KP Tehsils") label(2 "Newly Merged Tehsils") ) ///
	   ytitle("Total Wholesale Markets") xtitle("Population (000s)")) ///
	   (lfit p6q1311_admin_fac $pop ) 
graph export "$figures/wholesalemkts_population_scatter.png", replace

*-------------------------------------------------------------------------------
*Admin graphs combined
graph combine graph_hospitals graph_wholesalemkts, title("Correlation b/w Admin Facilities and Population") subtitle("Khyber Pakhtunkhwa: Tehsils (adm3)")  note("Source: Mouza Census 2020 & WSF19")
graph export "$figures/combined_admin_scatter.png", replace
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
/*
Percentage of Mouza's with at least one of each education category (primary, middle, secondary, madrassa) and health category (dispensary, clinic, hospital)
*/
graph drop _all
use "$output/MouzaCensus_Cleaned.dta", clear

*merging mouza-shapefile mapping   (Use this file to map mouza census tehsils to map Pak shapefile 2022 tehsils)
merge m:1 tehsil using "$output/tehsil_mouzatoshp2022.dta"    //9645 mouzas matched
keep if _m == 3
drop _m

order ADM3_NAME ADM3_CODE

*Combining with Tehsil level Popualtion numbers
merge m:1 ADM3_NAME using  "$output/population_number.dta"   , force   //same 133 tehsils matched
keep if _m == 3
drop _m

order ADM2_NAME-DISP_AREA, before(ADM3_NAME)
destring WPOP20, replace force

gen NMDs = 1 if ADM2_NAME == "Bajaur" | ADM2_NAME == "Khyber" | ADM2_NAME == "Kurram" | ADM2_NAME == "Mohmand" | ADM2_NAME == "North Waziristan" | ADM2_NAME == "Orakzai" | ADM2_NAME == "South Waziristan" 
replace NMDs = 0 if NMDs == .

drop district tehsil

*save "output/clean_mouzacensus_shape_pop.dta", replace

glo educ_boys 	"p4q1111 p4q1121 p4q1131  p4q1161"   			 
glo educ_girls 	"p4q1211 p4q1221 p4q1231  p4q1261"  			 

*Boys
foreach var of varlist $educ_boys {
	recode `var' (1=1 "Yes") (2=0 "No"), gen(`var'_education_boys)
		tab `var'_education, m
}

egen education_male = rowmean(p4q1111_education_boys-p4q1131_education_boys)
label var education_male "Education Accessibility - Boys"

tab p4q1111_education_boys
tab p4q1121_education_boys
tab p4q1131_education_boys
tab p4q1161_education_boys

*Girls
foreach var of varlist $educ_girls {
	recode `var' (1=1 "Yes") (2=0 "No"), gen(`var'_education_girls)
		tab `var'_education, m
}

egen education_female = rowmean(p4q1211_education_girls-p4q1231_education_girls)
label var education_female "Education Accessibility - Girls"

tab p4q1211_education_girls
tab p4q1221_education_girls
tab p4q1231_education_girls
tab p4q1261_education_girls

*Primary (Boys and Girls : District)
graph hbar (mean) p4q1211_education_girls p4q1111_education_boys if NMDs == 1, over(ADM2_NAME, sort(p4q1111_education_boys) descending) ytitle("Percentage (%)") title("Mouzas with Primary Schools (%)") subtitle("Newly Merged Districts")  note("Source: Mouza Census 2020") legend( label(1 "Girls") label(2 "Boys") )  name(primary_district_percent)
graph export "$figures/primary_district_percent.png", replace

*Primary (Boys and Girls : Tehsils)
graph hbar (mean) p4q1211_education_girls p4q1111_education_boys if NMDs == 1, over(ADM3_NAME, sort(p4q1111_education_boys)  descending lab(labsize(tiny))) ytitle("Percentage (%)") title("Mouzas with Primary Schools (%)") subtitle("Newly Merged Tehsils")  legend( label(1 "Girls") label(2 "Boys") ) name(primary_tehsil_percent)  
graph export "$figures/primary_tehsil_percent.png", replace

*Middle (Boys and Girls : District)
graph hbar (mean) p4q1221_education_girls p4q1121_education_boys if NMDs == 1, over(ADM2_NAME, sort(p4q1121_education_boys) descending) ytitle("Percentage (%)") title("Mouzas with Middle Schools (%)") subtitle("Newly Merged Districts")  note("Source: Mouza Census 2020") legend( label(1 "Girls") label(2 "Boys") )  name(middle_district_percent)
graph export "$figures/middle_district_percent.png", replace

*Middle (Boys and Girls : Tehsils)
graph hbar (mean) p4q1221_education_girls p4q1121_education_boys if NMDs == 1, over(ADM3_NAME, sort(p4q1121_education_boys)  descending lab(labsize(tiny))) ytitle("Percentage (%)") title("Mouzas with Middle Schools (%)") subtitle("Newly Merged Tehsils")  legend( label(1 "Girls") label(2 "Boys") ) name(middle_tehsil_percent)  
graph export "$figures/middle_tehsil_percent.png", replace

*Higher Secondary (Boys and Girls : District)
graph hbar (mean) p4q1231_education_girls p4q1131_education_boys if NMDs == 1, over(ADM2_NAME, sort(p4q1131_education_boys) descending) ytitle("Percentage (%)") title("Mouzas with Higher Secondary Schools (%)") subtitle("Newly Merged Districts")  note("Source: Mouza Census 2020") legend( label(1 "Girls") label(2 "Boys") )  name(secondary_district_percent)
graph export "$figures/secondary_district_percent.png", replace

*Higer Secondary (Boys and Girls : Tehsils)
graph hbar (mean) p4q1231_education_girls p4q1131_education_boys if NMDs == 1, over(ADM3_NAME, sort(p4q1131_education_boys)  descending lab(labsize(tiny))) ytitle("Percentage (%)") title("Mouzas with Higher Secondary Schools (%)") subtitle("Newly Merged Tehsils")  legend( label(1 "Girls") label(2 "Boys") ) name(secondary_tehsil_percent)  
graph export "$figures/secondary_tehsil_percent.png", replace



*Higher Religious (Boys and Girls : District)
graph hbar (mean) p4q1261_education_girls p4q1161_education_boys if NMDs == 1, over(ADM2_NAME, sort(p4q1161_education_boys) descending) ytitle("Percentage (%)") title("Mouzas with Religious Schools (%)") subtitle("Newly Merged Districts")  note("Source: Mouza Census 2020") legend( label(1 "Girls") label(2 "Boys") )  name(Religious_district_percent)
graph export "$figures/Religious_tehsil_percent.png", replace

*Higer Religious (Boys and Girls : Tehsils)
graph hbar (mean) p4q1261_education_girls p4q1161_education_boys if NMDs == 1, over(ADM3_NAME, sort(p4q1161_education_boys)  descending lab(labsize(tiny))) ytitle("Percentage (%)") title("Mouzas with Religious Schools (%)") subtitle("Newly Merged Tehsils")  legend( label(1 "Girls") label(2 "Boys") ) name(Religious_tehsil_percent)  
graph export "$figures/Religious_tehsil_percent.png", replace

**Hospitals/Dispencaries: Tehsils)
glo health_fac "p3q0871"
recode $health_fac (1=1 "Yes") (2=0 "No"), gen(health_facilities)
label var health_facilities "Hospitals/Dispensary facility available"
tab health_facilities,m


graph hbar (mean) health_fac if NMDs == 1, over(ADM2_NAME, sort(health_fac)  descending lab(labsize(tiny))) ytitle("Percentage (%)") title("Mouzas with Hospitals/Dispencaries (%)") subtitle("Newly Merged Districts")  name(hospitals_district_percent)  
graph export "$figures/hospitals_district_percent.png", replace

graph hbar (mean) health_fac if NMDs == 1, over(ADM3_NAME, sort(health_fac)  descending lab(labsize(tiny))) ytitle("Percentage (%)") title("Mouzas with Hospitals/Dispencaries (%)") subtitle("Newly Merged Tehsils")  name(hospitals_tehsil_percent)  
graph export "$figures/hospitals_tehsil_percent.png", replace

*-------------------------------------------------------------------------------
