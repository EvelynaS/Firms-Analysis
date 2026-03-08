*********************************
****** Informal enterprises: Figure 12 replication from Cunningham, Wendy; Newhouse, David; Ricaldi, Federica; Tchuisseu Seuyong, Feraud; Viollaz, Mariana; Edochie, Ifeanyi Nzegwu.
****Urban Informality in Sub-Saharan Africa : Profiling Workers and Firms in an Urban
* including 3 new countries Tazania, Somali and CAR
* minor changes in categories - explained in code
**********************************

clear all
set more off

ssc install winsor2

** Set root folder (project folder)
global root = "/Users/eves/Library/CloudStorage/Dropbox/LATAM_WorldBank/2023/2.Cities and Jobs/1. African cities/2. Data" // Change to directory of project folder
 cd "$root"
 
** Set standard globals
global data         = "${root}/1_Raw_Informal_micro" 
global inter		= "${root}/1_Raw_Informal_micro/Intermediate" 
global graphs 		= "${root}/Output/Graphs"
global tables 		= "${root}/Output/Tables" 


**** 

use "$inter/IE_allcities.dta", clear

*use "$data/ZimbabweInformal-2017-full-data-Long-Form.dta", clear

*** weights

* Create country-total of the original weights among informal firms
bys iso: egen _w_sum_inf = total(wmedian)

* Country=1 normalized weight (only defined on informal obs)
gen w_country_norm_inf = wmedian / _w_sum_inf 
label var w_country_norm_inf "Country=1 normalized weight (informal-only)"
table iso, statistic(sum w_country_norm_inf) nformat(%9.3f)


** #workers
gen paid_workers= l1a if l1a!=-9
gen unpaid_workers= l1b if l1b!=-9
egen workers = rowtotal(paid_workers unpaid_worker), m
gen prop_paid_workers= paid_workers/workers*100

egen num_worker_lastmonth=rowtotal(paid_workers unpaid_worker),m
	replace  paid_worker=1 if num_worker_lastmonth==0 // 3 obs
	replace num_worker_lastmonth=1 if num_worker_lastmonth==0 // 3 obs

** Education (7-complete senior secondary school) #changes from the original calculations, we consider completed education as b11= Complete senior secondary school from the IE Harmonized data from May 7, 2025
*** previous calcualtion of on Cunningham et. al. (2024) used individual IE surveys from Mozambique, Zambia and Zimbabwe, in which education catergories are not fully harmonized 
gen educat5=b11	
	
gen self_emp2=(num_worker_lastmonth==1 | paid_worker==0) if (!mi(num_worker_lastmonth) | !mi(paid_worker))
	lab val self_emp2 self_emp1
	gen Informal_owner_class2=.
	replace Informal_owner_class2=1 if self_emp2==1 & educat5<7 & !mi(educat5)
	replace Informal_owner_class2=2 if self_emp2==1 & educat5>=7 & !mi(educat5) & educat5!=-9
	replace Informal_owner_class2=3 if self_emp2==0 & !mi(educat5) & educat5!=-9
	lab var Informal_owner_class2 "Informal owner - classification 2 "
	lab val Informal_owner_class2 Informal_owner_class1

*loc iso "MOZ ZMB ZWE"
*foreach cc of local iso {
*	svyset idstd [pweight = wmedian], strata(strata)
*	svy: tab iso Informal_owner_class3, row percent if iso=="`cc'"
*}
* class 2
*foreach cc of local iso {
*	tab iso Informal_owner_class3 [aw=wmedian] if iso=="`cc'"
*}


* All weighted
*tab  Informal_owner_class1 [aw=weight] 

* All weighted with normalized weight
*tab Informal_owner_class2 [aw=w_country_norm_inf] if inlist(iso, "MOZ", "ZMB", "ZWE") | ///
        inlist(iso,"SDN","SOM","TZA")  
	
preserve
    // keep only what we need (optional filter to a few isos)
    keep iso Informal_owner_class2 wmedian
   keep if inlist(iso, "MOZ","ZMB","ZWE","CAF","GHA") | ///
        inlist(iso, "KHM","LAO","SDN","SOM","TZA")  
	
    // remember the value-label set so we can re-attach it later
    local vlab : value label Informal_owner_class2

    // 1) make one dummy per category
    tab Informal_owner_class2, gen(cls_)

    // 2) weighted means by iso = proportions
    collapse (mean) cls_* [aw = wmedian], by(iso)

    // 3) reshape to long, tidy format: one row per iso × category
    reshape long cls_, i(iso) j(class)

    // 4) attach original value labels to the category id
    label values class `vlab'

    // 5) nice names + formatting
    rename cls_ proportion
    format proportion %6.2f   // or %6.3f if you prefer

    // 6) export to Excel
    export excel using "proportions_by_iso_new.xlsx", firstrow(variables) replace
restore

