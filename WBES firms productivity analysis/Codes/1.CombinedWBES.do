***************************
**** Combine all Enterprise survey data & TFP Firm leveL
****
****This dofile is based on the reproductible code from the presentation by Jorge Rodriguez Meza
****for the World Bank Enterprise Symposium on Global Business Environment and Firm Productivity
**** June 5, 2025


** Step 1: Setting up directories
clear  all
set more off

global root = "/Users/eves/Library/CloudStorage/Dropbox/LATAM_WorldBank/2023/2.Cities and Jobs/1. African cities/2. Data/1_Raw_Informal_micro/Harmonized/Test" /// Change to directory of project folder


cd "$root"

* Step 2: Download the following files from the Data Portal and put them all in the same folder with this dofile:
*	      File 1: New_Comprehensive_May_5_2025.dta
*         File 2: ES-Indicators-Database-Global-Methodology_May_5_2025.dta
*         File 3: Firm Level TFP Estimates and Factor Ratios_May_5_2025.dta
*==============================================================================================================================================================
 
global data         = "${root}/1_Raw_Informal_micro" 
global  raw_combined = "${root}/New_Comprehensive_July_21_2025copy.dta" // downloaded from Step 2 above
global 	indicators   = "${root}/ES-Indicators-Database-Global-Methodology_July_21_2025copy.dta" // downloaded from Step 2 above
global 	tfp_dta	     = "${root}/Firm Level TFP Estimates and Factor Ratios_July_21_2025.dta" // downloaded from Step 2 above
**global  tfp_hk       "Firm Level TFP HK.dta" // included with the dofile
global 	inc_class    "income_classificationcopy.dta" // included with the dofile
global  wdi          = "${root}/WDI_4-28-2025copy.dta" // included with the dofile
global  gdp_file     = "${root}/GDP_per capita_PPP_current international_2025copy.dta" // included with the dofile

** Step 4: Putting the data together
clear
clear matrix 
use "$raw_combined"
	gen year = substr(country,-4,4)
	destring year, replace
	drop if year < 2014 & country != "Bangladesh2022"& country != "Iraq2022"& country != "Madagascar2022"& country != "Pakistan2022"& country != "Timor-Leste2021"
	drop year 
gen data_103=1 // indicator for the data in the 103 countries
	
merge 1:1 idstd using  "$indicators" 
keep if data_103==1 
drop _merge //checked that all the previous merge is all OK.

gen original_year=year //to preserve the original year in the data
gen sector=sector_MS

drop income
merge 1:1 idstd using "$tfp_dta" 
keep if data_103==1 
drop _merge //checked that all the previous merge is all OK.

* Merging the World Bank income classification data:
sort wbcode year
merge wbcode year using "$inc_class" 
drop _merge 
keep if data_103==1 
label var income_WB "Income group from the income classification data" 

* Merging GDP per capita data:
drop year
gen year=original_year-1 //to be used for merging with 1 year lagged values of GDP 

sort wbcode year
merge wbcode year using "$wdi", keep(gdp gdp1) //WDI data is missing for Taiwan, China
drop _merge
keep if data_103==1 
rename gdp1 gdp2 //two year lagged (from year_original defined above) gdp data 
rename gdp gdp1 //one year lagged (from year_original defined above) gdp per capita 

label var gdp1 "GDP per capita, PPP (constant 2021 Int'l $), 1 year lagged" // Data on gdp1 is missing for some countries 
label var gdp2 "GDP per capita, PPP (constant 2021 Int'l $), 2 years lagged"  //missing for two countries.

*Generating the controls:
gen ln_size=ln(size_num)
gen ln_age=ln(car1)
gen ln_exp=ln(wk8) 
gen multi=cond(a7==1,1,0) if a7==1|a7==2 
 
label var gdp1 "GDP per capita (1 year lagged, PPP, 2021 Int'l $)"
label var gdp2 "GDP per capita (2 year lagged, PPP, 2021 Int'l $)"
label var multi "Multi establishment Y:1 N:0 (a7 variable)" // based on a7 
label var ln_size "Number of workers (log of size_num)" 
label var ln_age "Age of firm (log of car1)"
label var ln_exp "Manager experience (log of wk8)"
drop year 
rename original_year year

*Normalized wieghts: 
by country, sort: egen wtsum=sum(wt) 
gen wt1=wt/wtsum 
drop wtsum 
label var wt1 "Sampling weights normalized at the country-level"
** generate variables 

g lprYL = log(d2_gdp09/size_num)   // sales per worker  
lab var lprYL "Labor Productivity (sales per worker)2009 constant USD"   

g VA = d2_gdp09 - n2e_gdp09
replace VA =. if VA<0  // code negative value-added as missing

g lprVAL = log(VA/size_num)  // value-added per worker  
lab var lprVAL "Labor Productivity (value-added per worker) 2009 constant USD"

g capital_intensity = log(n7a_gdp09/size_num)
lab var capital_intensity "Capital Intensity 2009 constant USD"

g ln_wl = log(n2a_gdp09/size_num)

encode wbcode, gen(iso3)
gen ln_GDP_pc_PPP_ci = ln(gdp1)

save "combined_data_WBES_US_constant.dta", replace

