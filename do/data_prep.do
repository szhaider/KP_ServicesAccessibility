

*Data prep for regressions
cap graph drop _all

use "$output/MouzaCensus_Cleaned.dta", clear

codebook tehsil     //We have 140 tehsils in mouza census

tab p1q09,m       //94% are rural mouzas

destring p4q1112 , replace force
codebook village     //8,982 unique mouzas

*collapse p1q09-p9q0227,  by(village tehsil district)     //Okay ..Different tehsils/districts have mouzas with same names. Common incidence
*Repeating villages within same tehsils fixed    >> 9680 mouzas available
*tab village,m

*Education (Boys + Girls) (Primary + Middle + HigherSecondary + College + VocationalInstitute + ReligiousInstitutes)
*Boys: p4q1111 p4q1121 p4q1131 p4q1141 p4q1151 p4q1161
*Girls: p4q1211 p4q1221 p4q1231 p4q1241 p4q1251 p4q1261

*glo educ_all "p4q1111 p4q1121 p4q1131 p4q1141 p4q1151 p4q1161 p4q1211 p4q1221 p4q1231 p4q1241 p4q1251 p4q1261"

glo educ_boys 	"p4q1111 p4q1121 p4q1131 p4q1141 p4q1161"   		 // p4q1151 
glo educ_girls 	"p4q1211 p4q1221 p4q1231 p4q1241 p4q1261"  			 // p4q1251 

*Boys
foreach var of varlist $educ_boys {
	recode `var' (1=1 "Yes") (2=0 "No"), gen(`var'_education_boys)
		tab `var'_education, m
}

egen education_male = rowmean(p4q1111_education_boys-p4q1131_education_boys)
label var education_male "Education Accessibility - Boys"

sum education_male, det
hist education_male, percent bin(3) ytitle("Percent") title("Boys: Education Accessibility Index") subtitle("Mouza level Averages") name(gr_11)
graph export "$figures/edu_access_boys.png", replace

*22% of the mouzas have only 1 facility available out of 6

*Girls
foreach var of varlist $educ_girls {
	recode `var' (1=1 "Yes") (2=0 "No"), gen(`var'_education_girls)
		tab `var'_education, m
}

egen education_female = rowmean(p4q1211_education_girls-p4q1231_education_girls)
label var education_female "Education Accessibility - Girls"

sum education_female, det
hist education_female, percent bin(3) ytitle("Percent") title("Girls: Education Accessibility Index") subtitle("Mouza level Averages") name(gr_12)
graph export "$figures/edu_access_girls.png", replace

* Disparity bw girls and boys
graph combine gr_11 gr_12, note("Educational Institutions: Primary, Secondary & Higher Secondary") name(comb_edu_index)
graph export "$figures/educ_gender.png", replace

*Gender disparity can be seen at mouza level in terms of education accessibility among boys and girls

*-------------------------------------------------------------------------------
*Health (Hospitals/Dispensary)   try other options too.
glo health_fac "p3q0871"

recode $health_fac (1=1 "Yes") (2=0 "No"), gen(health_facilities)
label var health_facilities "Hospitals/Dispensary facility available"

tab health_facilities,m


*-------------------------------------------------------------------------------
*Admin
*Police Stations + BAzzar +  wholesale markets

glo admin_fac "p8q051 p6q061 p6q1311"

foreach var of varlist $admin_fac{
recode `var' (1=1 "Yes") (2=0 "No"), gen(`var'_admin_fac)

tab `var'_admin_fac,m
}
*-------------------------------------------------------------------------------


*-------------------------------------------------------------------------------
*For Regression

collapse (sum) *_education_boys *_education_girls health_facilities *_admin_fac, by(tehsil)     //Settlement weighted   [aw=p1q10] 

*For regressions, taking tehsil level sums of boys and girls education institutions
*collapse (sum) *_education_boys *_education_girls , by(tehsil)
*Total educational institutions for boys and girls per tehsil - SInce we have total population without gender disaggregation

* edu_inst_tot = rowtotal(p4q1111_education_boys-p4q1261_education_girls)    //*coeff estimate is high due to high total

*Aggregating  Education institutions for boys and girls	
egen pri_schl_tot = rowtotal(p4q1111_education_boys p4q1211_education_girls)
egen mid_schl_tot = rowtotal(p4q1121_education_boys p4q1221_education_girls)
egen sec_schl_tot = rowtotal(p4q1131_education_boys p4q1231_education_girls)
egen col_tot	 =  rowtotal(p4q1141_education_boys  p4q1241_education_girls)	
egen rel_schl_tot = rowtotal(p4q1161_education_boys p4q1261_education_girls)


label var pri_schl_tot "Total of all Primary Schools for boys and girls - Tehsil level"
label var mid_schl_tot "Total of all Middle Schools for boys and girls - Tehsil level"
label var sec_schl_tot "Total of all Higher Secondary Schools for boys and girls - Tehsil level"
label var col_tot "Total of all Colleges for boys and girls - Tehsil level"
label var rel_schl_tot "Total of all Madrassahs for boys and girls - Tehsil level"


*For regressions, taking tehsil level sums of Hospitals/Dispensary in tehsils
*collapse (sum) health_facilities, by(tehsil)
label var health_facilities "Total hospitals/dispensaries - Tehsil level"

*For regressions, taking tehsil level sums of Police Stations in tehsils
*collapse (sum) police_stations, by(tehsil)
label var p8q051_admin_fac "Total police_stations - Tehsil level"
label var p6q1311_admin_fac "Total Whole sale markets - Tehsil level"
label var p6q061_admin_fac "Markets/Bazzars in mouzas - Tehsil level"

*sum police_stations    //A few tehsils with 0 police stations

*-------------------------------------------------------------------------------
*to create a matching for 2022 shapefiles tehsil names

replace tehsil = substr(tehsil,1,1)+lower(substr(tehsil,2,.))

*export excel "$xlsx/tehsilsdata.xls", first(variable) replace
save "$output/tehsillevel_services_sums.dta", replace
*-------------------------------------------------------------------------------



