***** Filter WBES combined data: select variables of interest and latest WBES from each country*****

cd "$root"

clear  all
set more off

global root = "/Users/eves/Library/CloudStorage/Dropbox/LATAM_WorldBank/2023/2.Cities and Jobs/1. African cities/2. Data/1_Raw_Informal_micro/Harmonized/Test" /// Change to directory of project folder

use "combined_data_WBES_US_constant.dta", clear 


local want idstd wt wt_rs income_WB region country iso3 ccode country2  gdp1 gdp2  a3ax a7 a14y d2_l1_year_perf_indicators ///
    d2 sector_MS exrate_d2 wk14 car1 wk8 d2_l1 VA_l1 ln_size ln_age ln_exp multi wt1 lprYL VA lprVAL capital_intensity ///
    deflator_usd_adjust_d2 deflator_adjust_d2 d2_gdp09

local keep
foreach v of local want {
    capture confirm variable `v'
    if !_rc local keep `keep' `v'
}
keep `keep'


drop if region == 7
drop if region == 3

* See how many obs still have any whitespace
count if ustrregexm(country, "\s")

* Remove ALL whitespace (spaces, NBSP, tabs, newlines, etc.)
replace country = ustrregexra(country, "\s+", "")

 
local dropcountry "Cameroon2016 Chad2018 Chile2006 China2012  DRC2006 Colombia2023 Ecuador2006 Ecuador2024 Ecuador2017 Egypt2016 ElSalvador2006 Eswatini2006 Eswatini2016 Gambia2006 Gambia2018 Ghana2007 Guatemala2006 Guinea2006 GuineaBissau2006 Honduras2006 Indonesia2015 Israel2024 Jordan2019 Kenya2007 LaoPDR2009 LaoPDR2012 LaoPDR2016 LaoPDR2024 Lesotho2016 Madagascar2013 Malaysia2015 Malaysia2019 Mali2007 Mali2016 Malta2019 Malta2024 Mauritania2006 Mexico2006 Morocco2019 Mozambique2007 Namibia2006 Namibia2014 Nicaragua2006 Nigeria2007 Pakistan2007 Pakistan2013 Panama2006 PapuaNewGuinea2015 Paraguay2006 Paraguay2017 Peru2006 Philippines2023 Peru2017 Rwanda2006 Rwanda2019 Senegal2007 Senegal2014 SierraLeone2023 SouthAfrica2007 Tanzania2006 Timor-Leste2015 Togo2023 Tunisia2020 Uganda2006 Uruguay2006 Uruguay2024 Venezuela2006 VietNam2015 VietNam2023 WestBankAndGaza2019 WestBankAndGaza2023 Zambia2007 Benin2016 Bhutan2024 Cambodia2016 Cameroon2016 Cameroon2024 Chad2018 Colombia2023 Côted'Ivoire2016 Ecuador2024 Egypt2016 ElSalvador2016 Eswatini2016 Gambia2018 Gambia2023 India2014  Indonesia2015  Myanmar2014 SouthSudan2024 "


foreach c of local dropcountry {
    drop if country == "`c'"
}



tab country

save "combined_data_WBES_US_constant_filtered2.dta", replace
