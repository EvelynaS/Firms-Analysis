************************************************************
* WBES survey Informal and Micro Enterprises analysis
* only analysis on firm size per city (rest of analysis on Analysis_all_IE_2)
************************************************************


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


use "$inter/Clean_IE_Micro.dta", clear

* -------------------------------------------------------------
*1)  Weights 1:  Country-normalized weights (each country = 1)
*    - Original survey weights inside each country
* -------------------------------------------------------------
by iso, sort: egen w_sum_country = total(woriginal)
gen double w_country_norm = woriginal / w_sum_country if !missing(woriginal)
label var w_country_norm "Country-normalized weight (sum=1 within iso)"

* -------------------------------------------------------------
* 2) Weights 1: ROBUSTNESS: Survey-normalized weights (each iso × informal_flag = 1)
*    - Equalizes informal vs micro surveys within a country
* -------------------------------------------------------------
bys iso informal: egen w_sum_survey = total(woriginal)
gen double w_survey_norm = woriginal / w_sum_survey if !missing(woriginal)
label var w_survey_norm "Survey-normalized weight (sum=1 within iso×informal_flag)"

*** cluster for robustness when city id is missing in some surveys
egen cluster_id = group(iso size_class_epoch)


*-----------------------------
* 3) Analysis 
*  Example outcome: firm size (workers)
*   regress workers on INFORMAL + controls
*    Controls: income group, sector, city size
*-----------------------------
set scheme s1color

** to winsor
winsor2 workers, cuts(1 99) replace 
winsor2 workers2, cuts(1 99) replace


* BASELINE (Paper 1): pweight = w_country_norm, cluster at city
regress workers2 informal ///
    i.income_level i.a41a ib2.size_class_epoch firm_age ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

margins a41a
marginsplot, recast(bar) recastci(rcap) 


*INTERACTIONS – Example with city size (use medium as base to avoid small-cell issues)
regress workers2 i.informal##i.a41a ///
    i.income_level i.a41a ib2.size_class_epoch firm_age ///
    [pweight = w_country_norm], vce(cluster id_city)
	
margins r.informal, at(a41a = (1 2 3)) 

label define informlbl 0 "Formal" 1 "Informal", replace
label values informal informlbl

* Predicted levels for plotting (two bars per city type)
margins informal, at(a41a = (1 2 3))
marginsplot, recast(bar) recastci(rcap) 
    plot1opts(barwidth(0.7) color(navy%70)) /// main bars navy, 80% opaque
    plot2opts(barwidth(0.7) color(navy%95) lwidth(medium) lcolor(navy))  /// 
	ci1opts(lcolor(blue %70)) ci2opts(lcolor(navy%95)) ///
    ytitle("Predicted number of workers") ///
    xtitle("") ///
    title("Firm size by informality and sector") ///
	xlabel(, labsize(small)) ///
	note("Average predicted means from linear regressions that control for sector," "firms'age, location and country's income. Original sampling weights rescaled," "so each country is weighted as one.")
graph export "$graphs/margins_workers_by_sector_M1.png", replace width(2000)

* Model (2) Country=1 weights, cluster = country×size
regress workers2 informal  ///
    i.income_level i.a41a ib2.size_class_epoch firm_age ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

margins a41a
marginsplot, recast(bar) recastci(rcap) 
title("Expected number of workers per sector") ///
    ytitle("Predicted workers") xtitle("Sector") ///
    xlabel(, valuelabel angle(30) labsize(small)) ///
    note("OLS with controls for informality, income, city size, firm age. Weights: w_country_norm. SEs clustered at city.")


*INTERACTIONS – Example with city size (use medium as base to avoid small-cell issues)
regress workers2 i.informal##i.a41a ///
    i.income_level i.a41a ib2.size_class_epoch firm_age ///
    [pweight = w_country_norm], vce(cluster cluster_id)
	
margins r.informal, at(a41a = (1 2 3)) 

label define informlbl 0 "Formal" 1 "Informal", replace
label values informal informlbl

* Predicted levels for plotting (two bars per city type)
margins informal, at(a41a = (1 2 3))
marginsplot, recast(bar) recastci(rcap) ///
    plot1opts(barwidth(0.7) color(navy%70)) /// main bars navy, 80% opaque
    plot2opts(barwidth(0.7) color(navy%95) lwidth(medium) lcolor(navy))  /// 
	ci1opts(lcolor(blue %70)) ci2opts(lcolor(navy%95)) ///
    ytitle("Predicted number of workers") ///
    xtitle("") ///
    title("Firm size by informality and sector") ///
	xlabel(, labsize(small)) ///
//	note("Average predicted means from linear regressions that control for sector," "firms'age, location and country's income. Original sampling weights rescaled," "so each country is weighted as one.")
graph export "$graphs/margins_workers_by_sector_M2.png", replace width(2000)



