/**************************************************************************************************************************************************************
----------------------------INTRO of the Analysis-------------------------------
Name: 					Master.do
Description: 			Master file for the KP Accessibility Analysis. 

Purpose:   				To prepare the datasets for final econometric/other analyses 

For:					Pakistan - Khyber Pakhtunkhwa	

Author: 				Zeeshan Haider
Email: 					szh223@nyu.edu / shaider7@worldbank.org

Last modified:			November, 2022

****************************************************************************************************************************************************************/

/*
----------------------------General Comments------------------------------------
1. 
*/

*-------------------------------------------------------------------------------
*A.1. SETTINGS AND VERSION CONTROL	
	clear all							
	version 17 							
	set more off 						
	set linesize 120					
	macro drop all 					
	cls
	pause off
	set maxvar 120000
*-------------------------------------------------------------------------------

*	A.2. Set the user and main paths:  (Plz adjust the paths according to the folder structure and your machine settings)

	local user wb578340
	
	cap cd "C:/Users/wb578340/OneDrive - WBG/Documents/WB_FY2023/KPK Population Growth Analysis/KP_Pop_ServiceAccessibility_Project"
	
	global root "C:/Users/wb578340/OneDrive - WBG/Documents/WB_FY2023/KPK Population Growth Analysis/KP_Pop_ServiceAccessibility_Project"
	global data "$root/data"        
	global do "$root/do"
	global xlsx "$root/xlsx"
	global temp "$root/temp"
	global logs "$root/log"
	
	global output "$root/output"
	global results "$root/results"
	global figures "$root/figures"
	global tables "$root/tables"

*-----------------
	dir "${root}"
	dir "${do}"
	dir "${rawdata}"
	dir "${xlsx}"
	dir "${output}"
	dir "${results}"	
*-------------------------------------------------------------------------------
*	A.3. Packages used in the project

	local packages 0   //Change to 1 to install packages, once per machine
	if `packages'{
		ssc install outreg2
		ssc install coefplot
	}
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------


*	A.5. Logs for the project

	capture log close
	
	log using "$logs/logfile", replace
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
	

* A.4. Calling required Do files 

*Data Preparation from Mouza Census 2020
	do 			"$do/MouzaDataPrep.do"
	
*Data Preparation for analytics
	do 			"$do/data_prep.do"	
	
*Elasticity of services to tehsil population projections 	
	do 			"$do/ServicesElasticity.do"

*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
	

	log close
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
