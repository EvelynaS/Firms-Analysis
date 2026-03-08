***********************************************************
* WBES informal and micro
* Clean data 
************************************************************

clear all
set more off

** Set root folder (project folder)
global root = "/Users/eves/Library/CloudStorage/Dropbox/LATAM_WorldBank/2023/2.Cities and Jobs/1. African cities/2. Data" // Change to directory of project folder


** Set standard globals
global data         = "${root}/1_Raw_Informal_micro/Intermediate" 
*global codes		= "${root}\2_dofiles"  
global graphs 		= "${root}/Output/Graphs"
global tables 		= "${root}/Output/Tables" 


** Data Cleaning

* 1) Load data

use "$data/IE_Micro_SSA.dta", clear


************ DO FILE DESCRIPTION:  


** uniform survey weights

gen mweight2= wmedian if interview=="Informal"
gen mweight3= med_str_weights if interview=="Micro"
egen woriginal = rowtotal(mweight2 mweight3), missing
drop mweight2 mweight3
lab var woriginal "original survey weights" 

encode income, gen(income_level)

** create identifies for region 

lab var idstd "Firm unique identifier"
lab var SSA_flag "1 if SSA country"
lab var id_city "City unique identifier"
lab var size_class_epoch "City size category numeric"
label define size_class_epoch 3 "Large" 2 "Medium" 3 "Small"


* Owner's characteristics


** Owner's experience
*** Years of experience
gen experience=b10 if b10!=-9
lab var experience "Years of experience"
replace experience = . if experience == 2015 | experience==2020 | experience==2008

** Owner is the primary income earner in their household
gen primary_earner = .
replace primary_earner = 1 if b16 == 1
replace primary_earner = 0 if b16 != 1 & !missing(b16)
lab var primary_earner "Owner is primary income earner"


**** Single owner ******

** Owner's education (level completed)
*** Secondary school
*gen secondary2 = . 
gen secondary2 = (b11 >= 5) if b11 < .  
gen secondary3 = (secondary == 1) if secondary < .
egen secondary1 = rowtotal(secondary2 secondary3), missing
lab var secondary1 "Completed Secondary school"
drop secondary2 secondary3
* Firm characteristics

** #workers
gen paid_workers= l1a if l1a!=-9
gen unpaid_workers= l1b if l1b!=-9
egen workers = rowtotal(paid_workers unpaid_worker),m
gen prop_paid_workers= paid_workers/workers*100

*workers based on #ppl worked last month
gen workers2=sc2 if sc2!=-9


gen one_member=.
replace one_member=1 if workers==1 & !missing(workers)
replace one_member=0 if one_member!=1  & !missing(workers)

gen one_member1=.
replace one_member1=1 if workers2==1 & !missing(workers2)
replace one_member1=0 if one_member1!=1  & !missing(workers2)


** proportionofpaid
label var workers "Total workers (paid + unpaid)"
label var prop_paid_workers "Proportion of paid workers (%)"
label var unpaid_workers "Number of unpaid (family) workers"

** Age of business
gen firm_age=a14y-b3 if b3!=-9 & b3 != -7
replace firm_age=. if b3==-9 & b3 != -7
lab var firm_age "Age of business"

** Weekly hours of normal operation
gen time=d10 if d10!=-9
lab var time "Weekly hours of normal operation"

** Business sector
gen manufacture= a41a == 1 
gen retail = a41a == 2
gen service = a41a == 3
// Labels
lab var manufacture "Manufacturing"
lab var retail "Retail"
lab var service "Services"

** Informal flag
gen informal=0 
replace informal=1 if interview=="Informal"


** Business working location
*** Fixed premises
gen op_firm=.
replace op_firm= 1 if c1a==1 | c1a==2 | c1a==3  
replace op_firm=0 if op_firm!=1 & !missing(c1a)
*** Within household premises
gen op_firm_hh=.
replace op_firm_hh= 1 if c1a==1
replace op_firm_hh= 0 if c1a!=1 & !missing(c1a)
// Labels
lab var op_firm "Business operates in fixed premises"
lab var op_firm_hh "Business operates within household premises"

** Reasons why business is operated within household premises
*** Lower cost
gen nh_less_cost=c1a1==1 if c1a1!=.
*** Easy management of family responsibilities
gen nh_responsa=c1a2==1 if c1a2!=.
*** More security
gen nh_security=c1a4==1 if c1a4!=.
*** Less chance of being identified by tax authorities
gen nh_tax_autho=c1a5==1 if c1a5!=.  
// Labels
lab var nh_less_cost "Reason: Lower cost"
lab var nh_responsa "Reason: Managing household responsibilities"
lab var nh_security "Reason: More security"
lab var nh_tax_autho "Reason: Less identifiable by tax authorities"

*Own funds 




**Business profitability
gen firm_profit=.
replace firm_profit= 1 if n7==1 &  n7!=-9
replace firm_profit =0 if n7!=1 & !missing(n7) & n7!=-9
lab var firm_profit "Business reports profit"

gen firm_loss=.
replace firm_loss=1  if n7==2 & n7!=-9
replace firm_loss =0 if n7!=2 & !missing(n7) & n7!=-9
lab var firm_loss "Business reports loss"

gen firm_zeroprofit=.
replace firm_zeroprofit=1  if n7==3 & n7!=-9
replace firm_zeroprofit =0 if n7!=3 & !missing(n7) & n7!=-9
lab var firm_zeroprofit "Business reports zero profits"

** Business contract
gen sell_cont=.
replace sell_cont=1 if d11a==1 & d11a!=-9
replace sell_cont=0 if d11a!=1 & !missing(d11a) & d11a!=-9
lab var sell_cont "Business sell by contract"

gen buy_cont=.
replace buy_cont=1 if d13a==1 & d13a!=-9
replace buy_cont=0 if d13a!=1 & !missing(d13a) & d11a!=-9
lab var buy_cont "Business buy by contract"

** Bank account
gen bank_account=.
replace bank_account=1 if k10==1 & k10!=-9
replace bank_account=0 if k10!=1 & !missing(k10) & k10!=-9
lab var bank_account "Business has bank account"

gen separate_account=.
replace separate_account=1 if k11==1 & k11!=-9  
replace separate_account= 0 if k11!=1 & !missing(k11) & k11!=-9
lab var separate_account "Separete bank account for HH"

** Mobile money
gen mobile_money=.
replace mobile_money=1 if k11a==1 & k11a!=-9  
replace mobile_money= 0 if k11a!=1 & !missing(k11a) & k11a!=-9
lab var mobile_money "Use mobile money"

** Financing of daily operations (last year)
gen k4b_1=k4b==1 if k4b!=-9
gen k4c_1=k4c==1 if k4c!=-9
gen k4d_1=k4d==1 if k4d!=-9
gen k4e_1=k4e==1 if k4e!=-9 

*** Finance from day to day operations 
**** From informal sources
gen fin_informal = 1 if k4b==1 | k4e==1
replace fin_informal = 0 if fin_informal!=1 & (k4b_1!=. | k4e_1!=.)
**** From formal sources
gen fin_formal = 1 if k4c_1==1 | k4d_1==1
replace fin_formal = 0 if fin_formal!=1 & (k4c_1!=. | k4d_1!=.)
**** From banks
gen fin_bank = 1 if k4d_1==1
replace fin_bank = 0 if fin_bank!=1 & k4d_1!=.
**** From microfinance institutions
gen fin_microfin = 1 if k4c_1==1 
replace fin_microfin = 0 if fin_microfin!=1 & k4c_1!=.
**** From moneylenders or relatives
gen fin_fri_fam = 1 if k4b_1==1 | k4e_1==1
replace fin_fri_fam = 0 if fin_fri_fam!=1 & (k4b_1!=. | k4e_1!=.)
// Labels

lab var fin_informal "Finance for daily operations: Informal sources"
lab var fin_formal "Finance for daily operations: Formal sources"
lab var fin_bank "Finance for daily operations: From banks"
lab var fin_microfin "Finance for daily operations: From microfinance"
lab var fin_fri_fam "Finance for daily operations: Moneylenders/relatives"

** Use of computers and smartphones
*** Computers
gen devices=.
replace devices=1 if c42a == 1 & c42a !=-9
replace devices=0 if devices!=1 & c42a!=-9 & !missing(c42a)
lab var devices "Computers"

*** Computers or smartphones
gen smartphones_devices = .
replace smartphones_devices = 1 if c42a==1 | c42c==1
replace smartphones_devices = 0 if (c42a!=1 & c42c!=1) ///
    & !missing(c42a,c42c) & c42a!=-9 & c42c!=-9
replace smartphones_devices = . if c42a==-9 | c42c==-9 | missing(c42a) | missing(c42c)
// Labels
lab var smartphones_devices "Computers or smartphone"


save "${data}/Clean_IE_Micro.dta", replace





