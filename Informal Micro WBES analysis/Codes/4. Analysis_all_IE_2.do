
************************************************************
* WBES survey Informal and Micro Enterprises analysis
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
* Weights 1:  Country-normalized weights (each country = 1)
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
*    Controls: income group, sector, city size, capital
*-----------------------------

* 3A) BASELINE (Paper 1): pweight = w_country_norm, cluster at city
regress workers informal ///
    i.income_level i.a41a ib2.size_class_epoch firm_age ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)


regress workers2 informal ///
    i.income_level i.a41a ib2.size_class_epoch  firm_age ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

	
*3B) INTERACTIONS – Example with city size (use medium as base to avoid small-cell issues)
regress workers i.informal##i.a41a  firm_age ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
*estimates store M1_inter_size

*regress workers i.informal##i.size_class_epoch ///
    i.income_level i.a41a i.CapitalFlag ///
    [pweight = w_country_norm], vce(cluster id_city)
*estimates store M1_inter_size

* Margins: informal–formal gap by city size (medium=2, large=3)
margins r.informal, at(a41a = (1 2 3)) 
*estimates store M1_inter_size_marg

*margins r.informal, at(CapitalFlag = (0 1)) 
*estimates store M1_inter_size_marg

* Predicted levels for plotting (two bars per city type)
margins informal, at(a41a = (1 2 3))
marginsplot, recast(bar) recastci(rcap) ///
    plot1opts(barwidth(0.7) color(navy%70)) /// main bars navy, 80% opaque
    plot2opts( barwidth(0.7) color(navy%95) lwidth(medium) lcolor(navy))  /// CI caps navy
    ytitle("Predicted # of workers") ///
    xtitle("") ///
    title("Firm size by informality and sector") ///
    xlabel(, labsize(small))
	caption("Baseline regression results")
	**/// shrink x-axis labels
    **scheme(s1color)
graph export "$graphs/margins_workers_by_sector_M1.png", replace width(2000)


regress workers i.informal##i.a41a firm_age ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster cluster_id)
*estimates store M1_inter_size

*regress workers i.informal##i.size_class_epoch ///
    i.income_level i.a41a i.CapitalFlag ///
    [pweight = w_country_norm], vce(cluster id_city)
*estimates store M1_inter_size

* Margins: informal–formal gap by city size (medium=2, large=3)
margins r.informal, at(a41a = (1 2 3)) 
*estimates store M1_inter_size_marg

*margins r.informal, at(CapitalFlag = (0 1)) 
*estimates store M1_inter_size_marg

* Predicted levels for plotting (two bars per city type)
margins informal, at(a41a = (1 2 3))
marginsplot, recast(bar) recastci(rcap) ///
    plot1opts(barwidth(0.7) color(navy%70)) /// main bars navy, 80% opaque
    plot2opts( barwidth(0.7) color(navy%95) lwidth(medium) lcolor(navy))  /// CI caps navy
    ytitle("Predicted # of workers") ///
    xtitle("") ///
    title("Firm size by informality and sector") ///
    xlabel(, labsize(small))         
	**/// shrink x-axis labels
    **scheme(s1color)
graph export "$graphs/margins_workers_by_sectorM4.png", replace width(2000)

*-----------------------------
* 4) Robustness models (SAME specification as baseline)
*    We show four columns: (weights × clustering)
*-----------------------------

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress workers informal i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress workers informal i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress workers informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

* Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_workers.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness: Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_workers2.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Informal vs Formal under Different Weights and Clustering") ///
     label

**************** ONE MEMBER FIRM ******************
regress one_member informal ///
    i.income_level i.a41a ib2.size_class_epoch firm_age ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

regress one_member informal i.income_level i.a41a ib2.size_class_epoch firm_age ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress one_member informal i.income_level i.a41a ib2.size_class_epoch  firm_age ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress one_member informal i.income_level i.a41a ib2.size_class_epoch  firm_age ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

* Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_one_member.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness: Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_one_member.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Informal vs Formal under Different Weights and Clustering") ///
     label



******** Logit
probit one_member1 informal ib2.size_class_epoch firm_age ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%60)) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of one-member firm") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Predicted probability of one-member firm by informality") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_one_member_M1.png", replace width(2000)


probit one_member1 informal ib2.size_class_epoch firm_age ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster cluster_id)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%60)) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of one-member firm") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Predicted probability of one-member firm by informality") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_one_member_M3.png", replace width(2000)

	 
	 
**************** YEARS OF THE FIRM ************
***********************************************

winsor2 firm_age, cuts(1 99) replace   // cap at 1st and 99th percentiles

* 3A) BASELINE (Paper 1): pweight = w_country_norm, cluster at city

regress firm_age informal ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* 4) Robustness models (SAME specification as baseline)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress firm_age  informal i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress firm_age  informal i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress firm_age  informal i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

* Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_firm_age.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness: Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_firm_age.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch  _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: #### Informal vs Formal under Different Weights and Clustering") ///
     label

	 
************* EXPERIENCE************

winsor2 experience, cuts(1 99) replace

regress experience informal ///
    i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

regress experience informal i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress experience informal i.income_level i.a41a ib2.size_class_epoch   ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress experience informal i.income_level i.a41a ib2.size_class_epoch   ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

* Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_experience.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness: Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_experience.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Owners experience Informal vs Formal under Different Weights and Clustering") ///
     label

	 	 
************* Main earner ************

regress primary_earner informal ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (2) Country=1 weights, cluster = country×size
regress primary_earner informal i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress primary_earner informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress primary_earner informal i.income_level i.a41a ib2.size_class_epoch   ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

* Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_primary_earner.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness: Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_primary_earner.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Primary Earner Informal vs Formal under Different Weights and Clustering") ///
     label

probit primary_earner informal ib2.size_class_epoch ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%60)) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of owner as primary earner") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Predicted probability of owner as primary earner by informality") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_one_member_M1.png", replace width(2000)	 
	 	 
	 
probit primary_earner informal ib2.size_class_epoch ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster cluster_id)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%60)) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of owner as primary earner") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Predicted probability of owner as primary earner by informality") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_one_member_M3.png", replace width(2000)

	 
******************PERCENTAGE OF PAID EMPLOYEES******

* Use tobit as FOR M1
gen share01 = prop_paid_workers/100
* 1) Tobit (two-limit 0–1), clustered at city, with country=1 weights
tobit share01 informal i.income_level i.a41a ib2.size_class_epoch firm_age  ///
    [pweight = w_country_norm], vce(cluster id_city) ll(0) ul(1)
estimates store Tobit_coef
estadd scalar N_clusters = e(N_clust)

* 2) Average Marginal Effect of 'informal' on the observed share (0–1)
margins, dydx(informal) predict(ystar(0,.)) post
estimates store Tobit_AME

esttab Tobit_AME using "$tables/tobit_share_AME_M1.rtf", replace ///
    keep(informal) coeflabels(informal "Informal (AME on share)") ///
    b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N, labels("Obs.")) ///
    title("Effect of Informality on Share of Paid Workers (Tobit AME)")
	
	* Use tobit as FOR M4
* 1) Tobit (two-limit 0–1), clustered at citysize x coyntry, with survey=1 weights
tobit share01 informal i.income_level i.a41a ib2.size_class_epoch firm_age ///
  [pweight = w_country_norm], vce(cluster cluster_id) ll(0) ul(1)
	
estimates store Tobit_coef
estadd scalar N_clusters = e(N_clust)

* 2) Average Marginal Effect of 'informal' on the observed share (0–1)
margins, dydx(informal) predict(ystar(0,.)) post
estimates store Tobit_AME

esttab Tobit_AME using "$tables/tobit_share_AME_M4.rtf", replace ///
    keep(informal) coeflabels(informal "Informal (AME on share)") ///
    b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N, labels("Obs.")) ///
    title("Effect of Informality on Share of Paid Workers (Tobit AME)")
	
**************** Hours of operation *******

* 3A) BASELINE (Paper 1): pweight = w_country_norm, cluster at city

regress time informal ///
    i.income_level i.a41a ib2.size_class_epoch firm_age ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress time informal i.income_level i.a41a ib2.size_class_epoch firm_age ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress time informal i.income_level i.a41a ib2.size_class_epoch firm_age   ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress time informal i.income_level i.a41a ib2.size_class_epoch firm_age ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_time.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness: Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_time.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch_cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Hours of Operation Informal vs Formal under Different Weights and Clustering") ///
     label
	 
********* secondary school ************
regress secondary1 informal ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress secondary1 informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress secondary1 informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress secondary1 informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_secondary.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness: Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_secondary.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Secondary school Informal vs Formal under Different Weights and Clustering") ///
     label

 	 
********** operates in HH ***************
	 
regress op_firm_hh informal ///
    i.income_level i.a41a ib2.size_class_epoch firm_age ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress op_firm_hh informal i.income_level i.a41a ib2.size_class_epoch firm_age ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress op_firm_hh informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress op_firm_hh informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_hh_operate.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness: Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_hh_operate.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Operates in HH Informal vs Formal under Different Weights and Clustering") ///
     label

******** Logit
probit op_firm_hh informal ib2.size_class_epoch firm_age ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city)

	margins
	
* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8)) plot2opts(barwidth(0.8)) ///
    ytitle("Predicted probability of bussiness in HH") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Firm operating in HH by informality") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_hh_M1.png", replace width(2000)


probit op_firm_hh informal ib2.size_class_epoch  firm_age ///
    i.income_level i.a41a ///
    [pweight = w_survey_norm], vce(cluster cluster_id)

margins
* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8)) plot2opts(barwidth(0.8)) ///
    ytitle("Predicted probability of bussiness in HH") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Firm operating in HH by informality") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_hh_M4.png", replace width(2000)

******** no fixed location ******

regress op_firm informal ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress op_firm informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress op_firm informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress op_firm informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_fixed_operate.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness: Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_fixed_operate.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Operates in HH Informal vs Formal under Different Weights and Clustering") ///
     label

	 
probit op_firm informal ib2.size_class_epoch ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8)) plot2opts(barwidth(0.8)) ///
    ytitle("Predicted probability of bussiness in fixed location") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Firm operating in fixed location by informality") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_fixed_M1.png", replace width(2000)

******* Bank account ******

regress bank_account informal firm_age ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress bank_account informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress bank_account informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress bank_account informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_bank_account.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness:Bank account Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_bank account.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Operates in HH Informal vs Formal under Different Weights and Clustering") ///
     label	 

	 
probit bank_account informal ib2.size_class_epoch firm_age ///
   i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city) 

margins, dydx(informal)
	 
	 
probit bank_account informal##ib2.size_class_epoch firm_age ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city)

* Average partial effect of informal at given city sizes
margins, dydx(informal) at(size_class_epoch = (2 3))

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1) size_class_epoch = (2 3))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(size_class_epoch) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%70)) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of firm" "having a bank account") ///
	 xtitle("") ///
    xlabel(2 "Medium City" 3 "Large city") ///
    title("Bank account by informality and city size") ///
    legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/probit_margins_bank_by_citysizeM1.png", replace width(2000)

probit bank_account informal##ib2.size_class_epoch firm_age ///
    i.income_level i.a41a ///
    [pweight = w_survey_norm], vce(cluster cluster_id)

* Average partial effect of informal at given city sizes
margins, dydx(informal) at(size_class_epoch = (2 3))



* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1) size_class_epoch = (2 3))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(size_class_epoch) plotdimension(informal) ///
    plot1opts(barwidth(0.8)) plot2opts(barwidth(0.8)) ///
    ytitle("Predicted probability of firm" "having a bank account") ///
	 xtitle("") ///
    xlabel(2 "Medium City" 3 "Large city") ///
    title("Bank account by informality and city size") ///
    legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/probit_margins_bank_by_citysizeM4.png", replace width(2000)

********* SEPARATE BANK ACCOUNT ****
regress separate_account informal ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress separate_account informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress bank_account informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress separate_account informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_separate_bank_account.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness:Bank account Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_separate_bank account.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Operates in HH Informal vs Formal under Different Weights and Clustering") ///
     label	 

probit separate_account informal ib2.size_class_epoch firm_age ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city)
	
* Average partial effect of informal at given city sizes
margins, dydx(informal) at(size_class_epoch = (2 3))

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1) size_class_epoch = (2 3))
marginsplot, recast(bar) recastci(rcap)	 
	 	 
	 
probit separate_account informal##ib2.size_class_epoch firm_age ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city)

* Average partial effect of informal at given city sizes
margins, dydx(informal) at(size_class_epoch = (2 3))

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1) size_class_epoch = (2 3))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(size_class_epoch) plotdimension(informal) ///
    plot1opts(barwidth(0.8)color(navy%70) ) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of firm" "having a bank account") ///
	 xtitle("") ///
    xlabel(2 "Medium City" 3 "Large city") ///
    title("Separate bank account by informality and city size") ///
    legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/probit_margins_separate_bank_by_citysizeM1.png", replace width(2000)

probit separate_account informal##ib2.size_class_epoch ///
    i.income_level i.a41a ///
    [pweight = w_survey_norm], vce(cluster cluster_id)

* Average partial effect of informal at given city sizes
margins, dydx(informal) at(size_class_epoch = (2 3))

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1) size_class_epoch = (2 3))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(size_class_epoch) plotdimension(informal) ///
    plot1opts(barwidth(0.8)color(navy%70) ) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of firm" "having a separate bank account") ///
	 xtitle("") ///
    xlabel(2 "Medium City" 3 "Large city") ///
    title("Bank account by informality and city size") ///
    legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/probit_margins_separeatebank_by_citysizeM4.png", replace width(2000)	 
	 
	 
	 
************ report profit ************

regress firm_profit informal firm_age ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress firm_profit informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress firm_profit informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress firm_profit informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_firm_profit.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness:Firm profit Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_firm_profit.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Firm profit Informal vs Formal under Different Weights and Clustering") ///
     label	
	 
	 
probit firm_profit informal ib2.size_class_epoch firm_age ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%70) ) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of bussiness reporting profits") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Bussiness reporting profits by informality") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_profits_M1.png", replace width(2000)


probit firm_profit informal ib2.size_class_epoch  firm_age ///
    i.income_level i.a41a ///
    [pweight = w_survey_norm], vce(cluster cluster_id)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8)color(navy%70) ) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of bussiness reporting profits") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Bussiness reporting profits by informality ") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_profits_M4.png", replace width(2000	 
	 
	 
	 
	 
	 
*************** report losses *************

regress firm_loss informal ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress firm_loss informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress firm_loss informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress firm_loss informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_firm_loss.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness:Firm loss profit Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_firm_loss.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Firm profit Informal vs Formal under Different Weights and Clustering") ///
     label		
	 
probit firm_loss informal ib2.size_class_epoch firm_age ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%70) ) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of bussiness reporting profits") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Bussiness reporting profits by informality") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_profits_M1.png", replace width(2000)


probit firm_loss informal ib2.size_class_epoch firm_age ///
    i.income_level i.a41a ///
    [pweight = w_survey_norm], vce(cluster cluster_id)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8)color(navy%70) ) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of bussiness reporting profits") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Bussiness reporting profits by informality ") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_profits_M4.png", replace width(2000	  
	 
	 

	 
 ******** zero profit ****** 
 
 regress firm_zeroprofit informal ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress firm_zeroprofit informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress firm_zeroprofit informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress firm_zeroprofit informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_firm_zeroprofit.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness:Firm zeroprofit,  Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_firm_zeroprofit.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Firm profit Informal vs Formal under Different Weights and Clustering") ///
     label	
	 
	 
probit firm_zeroprofit informal ib2.size_class_epoch firm_age ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%70) ) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of bussiness reporting profits") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Bussiness reporting profits by informality") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_zeroprofits_M1.png", replace width(2000)


probit firm_zeroprofit  informal ib2.size_class_epoch  firm_age ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster cluster_id)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8)color(navy%70) ) plot2opts(barwidth(0.8) color(navy%95)) ///
	ci1opts(lcolor(blue %70)) ci2opts(lcolor(navy%95)) ///
    ytitle("Predicted probability of bussiness reporting zero profits", size(small)) ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Bussiness reporting zero profits by informality ") ///
	note("Average predicted means from probit that control for sector, firms'age, location" "and country's income. Original sampling weights rescaled, so each country is weighted as one.")
	
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_zeroprofits_M2.png", replace width(2000)	  
	 
	 
********* informal financing ******

regress fin_informal informal ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress fin_informal informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress fin_informal informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress fin_informal informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_fin_informal.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness:Firm zeroprofit,  Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_fin_informal.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Financing informal Informal vs Formal under Different Weights and Clustering") ///
     label		 
	 
probit fin_informal informal ib2.size_class_epoch ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%70) ) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of bussiness using informal financing") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Bussiness using informal financing") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_informal_finance_M1.png", replace width(2000)


probit fin_informal  informal ib2.size_class_epoch ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster cluster_id)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8)color(navy%70) ) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of bussiness using informal financing") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Bussiness using informal financing by informality ") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_informal_finance_M2.png", replace width(2000)	  
	 	 
	 
	 
******* formal financing ********
regress fin_formal informal ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress fin_formal informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress fin_formal informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress fin_formal informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_fin_formal.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness  Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_fin_formal.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Financing Formal Informal vs Formal under Different Weights and Clustering") ///
     label		

probit fin_formal informal ib2.size_class_epoch ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster id_city)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%70) ) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of bussiness using formal financing") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Bussiness using formal financing") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_formal_finance_M1.png", replace width(2000)


probit fin_formal  informal ib2.size_class_epoch ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster cluster_id)

* Average partial effect of informal at given city sizes
margins, dydx(informal) 

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8)color(navy%70) ) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of bussiness using formal financing") ///
	 xtitle("") ///
    xlabel(0 "Micro" 1 "Informal") ///
    title("Bussiness using informal financing by informality ") 
    *legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_formal_finance_M2.png", replace width(2000)		 
	 
	 	 	 
*************** use of mobile money ********

regress mobile_money informal ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress mobile_money informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress mobile_money informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress mobile_money informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_mobile_money.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_mobile_money.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Financing Formal Informal vs Formal under Different Weights and Clustering") ///
     label	
	  
logit mobile_money informal ib2.size_class_epoch firm_age ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster cluster_id)

* Average partial effect of informal at given city sizes
margins, dydx(informal)

* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8)) plot2opts(barwidth(0.8)) ///
    ytitle("Predicted probability of firm" "using mobile money") ///
	 xtitle("") ///
    xlabel(0 "Formal" 1 "Informal") ///
    title("Bank account by informality and city size") ///
    legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_mobile_moneyM4.png", replace width(2000)


probit mobile_money informal##i.a41a ib2.size_class_epoch  firm_age ///
    i.income_level  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)

* Average partial effect of informal at given city sizes
margins, dydx(informal) at(a41a = (1 2 3))

* Predicted probabilities by setting informal to 0/1 explicitly

margins,  at( informal= (0 1) a41a = (1 2 3))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(a41a) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%70)) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of firm" "using mobile money") ///
	 xtitle("") ///
    title("Use of mobile money by informality and sector") ///
    legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/margins_use_mobil_sectorM4.png", replace width(2000)




******** use of devices **********

regress smartphones_devices informal ///
    i.income_level i.a41a ib2.size_class_epoch ///
    [pweight = w_country_norm], vce(cluster id_city)
estimates store M1_city_country
estadd scalar N_clusters = e(N_clust)

* (1) Country=1 weights, cluster = city   (already run above)
* (2) Country=1 weights, cluster = country×size
regress smartphones_devices informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_country_norm], vce(cluster cluster_id)
estimates store M2_csize_country

* (3) Survey=1 weights, cluster = city
regress smartphones_devices informal i.income_level i.a41a ib2.size_class_epoch    ///
    [pweight = w_survey_norm], vce(cluster id_city)
estimates store M3_city_survey
estadd scalar N_clusters = e(N_clust)

* (4) Survey=1 weights, cluster = country×size
regress smartphones_devices informal i.income_level i.a41a ib2.size_class_epoch  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)
estimates store M4_csize_survey
estadd scalar N_clusters = e(N_clust)

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey, se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) stats(N r2, labels("Obs." "R-squared")) label

esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/robustness_smartphones_devices.rtf", replace ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
    title("Robustness Informal vs Formal under Different Weights and Clustering") ///
	label	
	 
* Reduced: Side-by-side table (keep everything visible)
esttab M1_city_country M2_csize_country M3_city_survey M4_csize_survey using "$tables/Red_robustness_smartphones_devices.rtf", replace ///
	keep(informal 2.a41a  3.a41a 2.income_level 3.size_class_epoch _cons) ///
	se b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N N_clusters r2, labels("Obs." "Clusters" "R-squared")) ///
     title("Robustness: Formal Informal vs Formal under Different Weights and Clustering") ///
     label	

probit smartphones_devices informal ib2.size_class_epoch ///
    i.income_level i.a41a ///
    [pweight = w_survey_norm], vce(cluster cluster_id)

margins, dydx(informal)
* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%70)) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of firm" "using devices") ///
	 xtitle("") ///
    xlabel(0 "Formal" 1 "Informal") ///
    title("Use of devices by informality and city size") ///
    legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_device_moneyM4.png", replace width(2000)

probit smartphones_devices informal ib2.size_class_epoch ///
    i.income_level i.a41a ///
    [pweight = w_country_norm], vce(cluster cluster_id)

margins, dydx(informal)
scalar dydx_informal = r(table)[1,1]
scalar se_informal   = r(table)[2,1]
scalar p_value       = r(table)[4,1]

* ---- write result in a separate frame ----
frame create _res
frame _res: clear
frame _res: set obs 1
frame _res: gen outcome = "smartphone"
frame _res: gen dydx    = dydx_informal
frame _res: gen se      = se_informal
frame _res: gen pval    = p_value
frame _res: save "mobile_dydx.dta", replace


* Predicted probabilities by setting informal to 0/1 explicitly
margins, at(informal = (0 1))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(informal) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%70)) plot2opts(barwidth(0.8)(navy%95)) ///
    ytitle("Predicted probability of firm" "using devices") ///
	 xtitle("") ///
    xlabel(0 "Formal" 1 "Informal") ///
    title("Use of devices by informality") ///
    legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/logit_margins_device_moneyM2.png", replace width(2000)



probit smartphones_devices informal##i.a41a ib2.size_class_epoch ///
    i.income_level  ///
    [pweight = w_survey_norm], vce(cluster cluster_id)

* Average partial effect of informal at given city sizes
margins, dydx(informal) at(a41a = (1 2 3))

* Predicted probabilities by setting informal to 0/1 explicitly

margins,  at( informal= (0 1) a41a = (1 2 3))
marginsplot, recast(bar) recastci(rcap) ///
    xdimension(a41a) plotdimension(informal) ///
    plot1opts(barwidth(0.8) color(navy%70)) plot2opts(barwidth(0.8) color(navy%95)) ///
    ytitle("Predicted probability of firm" "using mobile money") ///
	 xtitle("") ///
    title("Use of mobile money by informality and sector") ///
    legend(order(1 "Formal" 2 "Informal") pos(6) col(1))
graph export "$graphs/margins_use_mobil_sectorM4.png", replace width(2000)



	
	
	
 *************************** Analysis only for informal *********************
 
 *keep if informal == 1
 
svyset id_city [pweight = w_country_norm], strata(stratificationregioncode)
svy, subpop(informal): mean workers

