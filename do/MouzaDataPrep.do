

*Cleaning and preparing Mouza Census 2020



import excel "$data/MICRO DATA OF MOUZA CENSUS - 2020.xlsx", sheet("Sheet1") firstrow case(lower) clear

*-------------------------------------------------------------------------------

*Labeling the data 
foreach var of varlist sr-p9q0227 {
    
	di `var'[1]
	global temp  = `var'[1]
    label variable `var' "$temp"
}


drop if _n == 1 | _n == 2
drop sr

foreach var of varlist p1q09-p9q0227{
    destring `var', replace
}
*-------------------------------------------------------------------------------

compress

replace tehsil = substr(tehsil,1,1)+lower(substr(tehsil,2,.))
/*
*merging mouza-shapefile mapping   (Use this file to map mouza census tehsils to map Pak shapefile 2022 tehsils)
merge m:1 tehsil using "$output/tehsil_mouzatoshp2022.dta"    //9645 matched   128 donot  match
keep if _m == 3
drop _m
order ADM3_NAME ADM3_CODE
*/

*Mouza Census Data to be used in the Analysis and further
save "$output/MouzaCensus_Cleaned.dta", replace

*-------------------------------------------------------------------------------






