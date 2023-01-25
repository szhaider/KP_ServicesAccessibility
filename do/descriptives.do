*Descriptive Analysis

*-------------------------------------------------------------------------------

*Population Census 2017 - Rural Urban disagg

*Census 2017 Data (Urban share to total population)

*import delimited "$xlsx/04_tehsil_aggregated_sex.csv", clear
import delimited "$xlsx/04_tehsil_disaggregated.csv", clear

split district, parse(" ") gen(district)
drop district2-district4 district
rename district1 district
order district
replace district = substr(district,1,1)+lower(substr(district,2,.))

split tehsil_subdiv, parse(" ") gen(tehsil) 
drop tehsil2-tehsil7 tehsil_subdiv
rename tehsil1 tehsil
order tehsil
replace tehsil = substr(tehsil, 1,1) + lower(substr(tehsil, 2, .))


replace age = "0" if age == "<1"

 encode(age), gen(age1)
 encode(sex), gen(sex1)
 encode(district), gen(district1)
 encode(tehsil), gen(tehsil1)
 
gen id = _n
gen id1 =  district1+tehsil1+sex1+age1


*reshape wide rural urban total, i(age sex) j(tehsil) s

collapse (sum) rural urban total ,by(age sex tehsil district)

total(total)

/*

preserve

use "$data/2017_censusblocks_prov", clear   //more tehsils in prov file than gender file , thats why we are left with 60 tehsils
*keep if province == "KP"
collapse (sum) pop hhs, by(province district tehsil urban)

replace district = substr(district,1,1)+lower(substr(district,2,.))
replace tehsil = substr(tehsil,1,1)+lower(substr(tehsil,2,.))

tempfile prov_pop
save `prov_pop', replace

restore

merge 1:m tehsil using `prov_pop'

keep if _m == 3
drop _m
drop pop

gen urban_ratio = urban / total

keep if province == "KP"
*/
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------

*Population Census 2017 - Rural Urban disagg

use "$data/2017_censusblocks_prov", clear

reshape wide pop hhs, i(block) j(urban)

collapse (sum) pop0 pop1 hhs0 hhs1, by(province district tehsil)

egen pop_total = rowtotal(pop0 pop1)

*egen popt= sum(pop_total)  //okay 2.08e+08


gen urban_ratio = pop1 / pop_total

keep if province == "KP"

gen pop = pop_total/1000

gen tribal = 1 if tehsil == "TRIBAL AREA ADJ. BANNU" | tehsil == "TRIBAL AREA ADJ. DERA ISMAIL KHAN" | tehsil == "TRIBAL AREA ADJ. KOHAT" | tehsil == "TRIBAL AREA ADJ. LAKKI MARWAT" | tehsil == "TRIBAL AREA ADJ. PESHAWAR" | tehsil == "TRIBAL AREA ADJ. TANK" 

replace tribal =0 if tribal == .

twoway (scatter  pop urban_ratio , msymbol(Oh) mcolor() title("Urban ratio vs. Total population") subtitle("Khyber Pakhtunkhwa (Tehsils)") note("Source: Population Census 2017, PBS") xtitle("Urban Ratio") ytitle("Total Population (000s)")) 
	  *(lfit  pop urban_ratio) 
	  
	  
graph export "$figures/primary_population_scatter.png", replace

*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------

graph drop _all
*Reading Tehsil level sums for services (Education + Health + admin)
use "$output/tehsillevel_services_sums.dta", clear

*merging mouza-shapefile mapping   (Use this file to map mouza census tehsils to map Pak shapefile 2022 tehsils)
merge 1:m tehsil using "$output/tehsil_mouzatoshp2022.dta"    //same 133 tehsils matched
keep if _m == 3
drop _m

keep if province == "KP"

order ADM3_NAME ADM3_CODE

/*
**** For Comparing Number of schools with GIS Data

drop health_facilities p8q051_admin_fac p6q061_admin_fac p6q1311_admin_fac pri_schl_tot mid_schl_tot sec_schl_tot col_tot rel_schl_tot

export excel "data/Number_of_Schools_Mouza.xls", first(variable) replace
****
*/

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

*Accessibility to energy

*global fuel_avaialbility "p6q031 p6q032 p6q033 p6q034 p6q035 p6q036"

recode p6q031 (1=1 "Yes") (.=0 "No"), gen(p6q031_fuelavailability)
recode p6q032 (2=1 "Yes") (.=0 "No"), gen(p6q032_fuelavailability)
recode p6q033 (3=1 "Yes") (.=0 "No"), gen(p6q033_fuelavailability)
recode p6q034 (4=1 "Yes") (.=0 "No"), gen(p6q034_fuelavailability)
recode p6q035 (5=1 "Yes") (.=0 "No"), gen(p6q035_fuelavailability)
recode p6q036 (6=1 "Yes") (.=0 "No"), gen(p6q036_fuelavailability)


egen fuel_score = rmean(p6q031_fuelavailability-p6q036_fuelavailability)

tab p6q031_fuelavailability, m

graph hbar (mean)  p6q032_fuelavailability    p6q036_fuelavailability if NMDs == 1, ///
over(ADM3_NAME, sort(p6q036_fuelavailability descending lab(labsize(tiny)))) ///
ytitle("Percentage (%)") title("Percentage of Mouzas with access to Sui Gas")

**# Bookmark #1
graph hbar (mean)  fuel_score  if NMDs == 1, ///
over(ADM3_NAME, sort(fuel_score descending lab(labsize(tiny)))) ///
ytitle("Percentage (%)") title("Percentage of Mouzas with access to Sui Gas")


********************************************************************************
