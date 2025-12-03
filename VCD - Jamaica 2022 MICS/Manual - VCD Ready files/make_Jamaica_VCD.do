
* Program to make Jamaica 2022 MICS data compatible with the 
* Vaccination Coverage Quality Indicators (VCQI) software.
*


local input Q:\VCD - Jamaica 2022 MICS\Jamaica MICS6 SPSS Datasets
local output Q:\VCD - Jamaica 2022 MICS\Manual - VCD Ready files

cd "`output'"

*
*use "`input'/ch", clear
import spss using "`input'/ch.sav", case(lower) clear
********************************************************************************
********************************************************************************
* Start by removing records of those that did not give consent or complete the interview

* Only keep the respondents that gave consent for the interview
keep if uf10 == 1

* Confirm that everyone finished the survey 
assert uf17 == 1
drop if uf17 != 1

********************************************************************************
***************				Demographic information				****************
********************************************************************************

* Create the stratifer variables

* We will stratify the dataset by Parish first
clonevar RI01 = hh7
decode RI01, gen(RI02)

* Clean up any string names here
replace RI02 = proper(RI02)
replace RI02 = trim(RI02)

* Cluster variables
clonevar RI03 = hh1

* Confirm that the psu variable is equal to the cluster 
assert psu == RI03

* If there is a value label with the cluster id, then we we use the decode command
if "`:value label RI03'" != "" decode RI03, gen(RI04)
* If there is not we will simply add the word "Cluster" in front of the number
if "`:value label RI03'" == "" {
	gen RI04 = "Cluster " + string(RI03)
	label var RI04 "Cluster name"
}

* HH number variable
clonevar RI11 = uf2
* Note that the hhid (RI11) must be a string variable so confirm that is the case
capture tostring RI11, replace

* Child's line number variable
* There are two variables for child's line number, confirm they are the same
assert ln == uf3
clonevar RI12 = uf3

* Mother's line number
clonevar RI13 = uf4

* Urban rural area
clonevar urban_cluster = hh6

********************************************************************************
***************			Level Dataset information				****************
********************************************************************************

* Later on we will use what we call level1, level2 and level3 variables
* Create these as you wish to have the data nested 

* level1 is typically the Country level
gen level1id = 1
gen level1name = "Jamaica" 
label var level1id "Country"
label var level1name "Country"

* Level2 - Since we do not have any other demographic levels we will set this to the level1 information
clonevar level2id = level1id 
clonevar level2name = level1name

* Level3 - this is typically the same information used in RI01 & RI02
clonevar level3id = RI01
clonevar level3name = RI02

********************************************************************************
***************				Interview information				****************
********************************************************************************

* There are two variables with interviewer number, confirm they hold the same values
assert ufint == uf5
clonevar RI05 = uf5

* There are two varibles with supervisor number, confirm they hold the same values
assert uf6 == hh4
clonevar RI07 = uf6

* Interview date varibles
clonevar RI09_m = uf7m
clonevar RI09_d = uf7d
clonevar RI09_y = uf7y

* Create start time variables
gen double RI10 = hms(uf8h, uf8m, 0)
label var RI10 "Start time of interview"

* Create end time variables 
gen double RI143= hms(uf11h, uf11m, 0)
label var RI143 "End time of interview"

* Format the two time variables
format %tcHH:MM:SS RI10 RI143

********************************************************************************
***************					Child information				****************
********************************************************************************
* Child's sex
clonevar RI20 = hl4

* Child's dob per mother's recall 
clonevar dob_date_history_m = ub1m
clonevar dob_date_history_d = ub1d
clonevar dob_date_history_y = ub1y

* There is one date of birth day that has an invalid day component. 
* We will wipe that out
replace dob_date_history_d = . if ub1d == 98

* Child's age in years
clonevar RI24 = ub2

* Child's age in months
clonevar RI25 = cage

********************************************************************************
***************					Card information				****************
********************************************************************************

* There is not DOB on the card, so we will create these variables as missing
foreach c in m d y {
	gen dob_date_card_`c' = .
	label var dob_date_card_`c' "Empty variable - created for VCQI "
}
* Card ever received
clonevar RI26 = im3 // Ever received card
replace RI26 = 1 if inlist(im2,1,2,3) // has vx card for child - 1,2&3 = yes
replace RI26 = 1 if inlist(im5,1,2,3) // vx card seen for child - 1,2&3 = yes
replace RI26 = 2 if (im2 == 4 | im5 == 4) & RI26 != 1 // has not card from either source
replace RI26 = 99 if RI26 == 9 
replace RI26 = . if !inlist(RI26,1,2,99)

label define RI26 1 "Yes" 2 "No" 99 "Don't know", replace
label value RI26 RI26

* Card seen
clonevar RI27 = im5 
replace RI27 = 1 if inlist(im5,1,2,3) 
replace RI27 = 2 if im5 == 4
replace RI27 = 2 if im2 == 4 & RI27 != 1
replace RI27 = . if RI26 != 1
label define RI27 1 "Yes, card seen" 2 "No, card not seen", replace
label value RI27 RI27

********************************************************************************
***************					Dose information				****************
********************************************************************************
* Create dose specific VCQI variables

* establish a global with the RI dose list
global RI_LIST 		bcg polio1 polio2 polio3 penta1 penta2 penta3 mmr1 mmr2 dpt4 polio4 
global RI_LIST 		=lower("$RI_LIST")


* Set up locals that contain the variable base for card information for each dose
local bcg			im6b
local polio1		im6p1
local polio2		im6p2
local polio3		im6p3
local polio4		im6i
local penta1		im6penta1
local penta2		im6penta2
local penta3		im6penta3
local dpt4			im6td1
local mmr1			im6m1
local mmr2			im6m2

* Create values labels that will be applied to the history variables and tick mark variables
label define history 1 "Yes" 2 "No" 99 "Don't know", replace
label define tick 1 "Yes, tick mark on card" 0 "No", replace
* Loop through the dose list and use the card information to create 5 variables for each dose
* 1. Month of dose date from card  
* 2. Day of dose date from card
* 3. Year of dose date from card
* 4. Tick mark on card recorded in dose day with a value of 44 (marked on card)
* 5. Recall recorded in dose day variable witha value of 66 (mother reported)
* NOTE: we want to wipe out any 0 values in the dose day field (not given)

* Create a local that will be used to order the variables 
local order_list
foreach v in $RI_LIST {
	local uv = upper("`v'")
	gen `v'_tick_card = 1 if ``v''d == 44
	label var `v'_tick_card  "`uv' - received via tick mark on card"
	label value `v'_tick_card tick
	
	gen `v'_history = 1 if ``v''d == 66
	replace `v'_history = 2 if ``v''d == 0 & `v'_history != 1
	label var `v'_history  "`uv' - received via recall"
	label value `v'_history history
	
	foreach c in m d y {
		clonevar `v'_date_card_`c' = ``v''`c'
		
		* Wipe out the invalid values from the day field that represent tick (44), recall (66) or not given (0)
		if "`c'" != "d" assert !inlist(`v'_date_card_`c',0,44,66)
		replace `v'_date_card_`c' = . if inlist(``v''`c',0,44,66)
	}
	
	local order_list `order_list' `v'_date_card_m `v'_date_card_d `v'_date_card_y `v'_tick_card `v'_history
	
	di "`v'"
	* confirm that the date values are valid
	assert `v'_date_card_m <= 12 if !missing(`v'_date_card_m)
	assert `v'_date_card_d >= 1 & `v'_date_card_d <= 31 if !missing(`v'_date_card_d)
	assert `v'_date_card_y >= 2019 & `v'_date_card_y <= 2025 if !missing(`v'_date_card_y)
}

********************************************************************************
***************				Dose Recall information				****************
********************************************************************************
* Now replace the history variables based on the actual recall variables
* BCG 
replace bcg_history = im14 if missing(bcg_history)
replace bcg_history = 1 if im14 == 1

* we also need to create a bcg_scar_history variable.
* Since this is not in the dataset, we will leave it as blank
gen bcg_scar_history = . 
label var bcg_scar_history "Empty variable- created for VCQI"


* DPT booster
replace dpt4_history =  1 if im27a == 1
replace dpt4_history =  2 if im27a == 2 & dpt4_history != 1
replace dpt4_history = 99 if im27a == 8 & dpt4_history != 1
replace dpt4_history =  . if im27a == 9 & dpt4_history != 1


* Measles or MMR or MR
gen num_mmr = 0
replace num_mmr = im26a if im26a < 8

forvalues i = 1/2 {
	replace mmr`i'_history = 1 if im26 == 1 & num_mmr >= `i' 
	replace mmr`i'_history = 2 if im26 == 1 & num_mmr < `i' & mmr`i'_history != 1 
	replace mmr`i'_history = 2 if im26 == 2 & mmr`i'_history != 1
	replace mmr`i'_history = 99 if im26 == 8 & mmr`i'_history != 1
	replace mmr`i'_history = . if im26 == 9 & mmr`i'_history != 1
}
* If they say they got the dose but don't know how many doses they received (im26a == 8), give credit for the first dose
replace mmr1_history = 1 if im26 == 1


* PENTA doses 1-3
gen num_penta = 0
replace num_penta = im21 if im21 < 8
forvalues i = 1/3 {
	replace penta`i'_history = 1 if im20 == 1 & num_penta >= `i' 
	replace penta`i'_history = 2 if im20 == 1 & num_penta < `i' & penta`i'_history != 1 
	replace penta`i'_history = 2 if im20 == 2 & penta`i'_history != 1
	replace penta`i'_history = 99 if im20 == 8 & penta`i'_history != 1
	replace penta`i'_history = . if im20 == 9 & penta`i'_history != 1

}

* If they say they got the dose but don't know how many doses they received (im26a == 8), give credit for the first dose
replace penta1_history = 1 if im20 == 1

* POLIO
* The way that the recall for polio is used per the questionnaire and report is unique
* Polio1 - will ONLY use the IPV recall information
* Polio2-4 will use either IPV or OPV
replace polio1_history = 1 if im19a == 1
replace polio1_history = 2 if im19a == 2 & polio1_history != 1
replace polio1_history = 99 if im19a == 8 & polio1_history != 1
replace polio1_history = . if im19a == 9 & polio1_history != 1


gen num_polio = 0
replace num_polio = im19b if im19b < 8
replace num_polio = num_polio + im18 if im18 < 8

forvalues i = 2/4 {
	replace polio`i'_history = 1 if  num_polio >= `i' 
	replace polio`i'_history = 2 if im19a == 1 & num_polio < `i' & polio`i'_history != 1 
	replace polio`i'_history = 2 if im19a == 2 & polio`i'_history != 1
	replace polio`i'_history = 99 if im19a == 8 & polio`i'_history != 1
	replace polio`i'_history = . if im19a == 9 & polio`i'_history != 1
}


* Replace all history values to 2 if they have the value of 8 (Do not know)
foreach v of varlist *_history {
	assert inlist(`v',1,2,99,.)
}

********************************************************************************
***************				Additional information				****************
********************************************************************************

* List any other additional variables that you would like to pass through to the RI dataset analysis 
* e.g. religion, education etc
global RI_ADDITIONAL_VARS hh6 melevel ethnicity religion windex5  /// // These varialbles will be used to stratify the dataset
chweight /// // Child's weight 
im19b im19a im18 im16 /// // Polio history variables incase we want to take a closer look
im2 im3 im5 /// // Card availability varaibles
uf12 uf13 // Language of questionnaire and interview

********************************************************************************
***************					Save Datasets					****************
********************************************************************************
* Save an overall dataset 
sort RI01 RI02 RI03 RI04 RI11 RI12 RI09_m RI09_d RI09_y chweight, stable
save Full_dataset, replace 

********************************************************************************
***************					RI Datasets					****************
********************************************************************************

* Save the RI datasets
keep RI* *date* *history *tick* $RI_ADDITIONAL_VARS

order RI*  $RI_ADDITIONAL_VARS , sequential
order dob_date_history_m dob_date_history_d dob_date_history_y dob_date_card_m dob_date_card_d dob_date_card_y `order_list', after(RI27)

order bcg_scar_history, after(bcg_history)

order chweight
sort RI01 RI02 RI03 RI04 RI11 RI12 RI09_m RI09_d RI09_y chweight, stable

save RI_dataset, replace

preserve
* Create two separate datasets for each age group
keep if RI25 >=12 & RI25 <= 23
save RI_12_to_23m_dataset, replace
restore 

preserve
use RI_dataset, clear
keep if RI25 >=24 & RI25 <= 35
save RI_24_to_35m_dataset, replace
restore 

********************************************************************************
***************					CM Dataset						****************
********************************************************************************
use Full_dataset, clear 

* Bring in the hh dataset so we capture all households
merge m:1 hh7 hh1 hh2 hh6 using "`input'/hh", keepusing(hh7 hh1 hh2 hh6 hh12)

* confirm that the _merge is 3 (matched) or 2 (Not matched - from HH)
assert _merge != 1

* Rename clonevar variables to align with the CM dataset format
clonevar HH01 = hh7 
clonevar HH02 = RI02
clonevar HH03 = hh1
clonevar HH04 = RI04
clonevar HH14 = hh2

* Create the province_id to mirror the level2id
gen province_id = level2id

* Confirm that it is populated for all rows
capture assert !missing(province_id)
if _rc != 0 {
	sort HH01 HH03 province_id
	bysort HH01 HH03: replace province_id = province_id[1]
}

* Create the weight variable to mirror the child's survey weight
clonevar psweight_1year = chweight

* Create expected_hh_to_visit VCQI variable
bysort HH03 HH14: gen firsthm = _n == 1

bysort HH03 : egen expected_hh_to_visit = total(firsthm) // Double check to ensure this appropriately calculated.
drop firsthm
label variable expected_hh_to_visit "Number of HH survey team expects to visit in cluster (or cluster segment)"

* Drop if they did not give consent
drop if uf10 == 2 | hh12 == 2

* Only keep the CM variables
keep HH01 HH02 HH03 HH04 province_id urban_cluster psweight*
drop if missing(psweight_1year)

* Drop so that we only have 1 row per Strata-cluster combo
duplicates drop

* Confirm there is only 1 weight per cluster
bysort HH01 HH03: assert _N == 1

sort HH01 HH03 urban_cluster
bysort HH01 HH03: replace urban_cluster = urban_cluster[1]

* The weight can be missing for some observations; replace the weight with
* the maximum non-missing weight in each cluster 

bysort HH01 HH03: egen max_psweight_1year = max(psweight_1year)
replace psweight_1year = max_psweight_1year
drop max_psweight_1year

*Only keep one row per cluster and stratum
bysort HH01 HH03 : keep if _n==1

order HH*
sort HH01 HH03 province_id urban_cluster psweight_1year
save CM_dataset, replace

********************************************************************************
***************					Level 1-3 Datasets				****************
********************************************************************************

* Create the different level datasets 
forvalues i = 1/3 {
	use Full_dataset, clear
	
	* Keep the level# variables
	keep level`i'* 
	
	* Drop duplicates so we have 1 row per value
	duplicates drop 
	
	* Remove the label from the id variable
	label value level`i'id
	
	* use the level#id as order unless you would like to see the output in a different order
	clonevar level`i'order = level`i'id

	* If this is for level1 we only need the level1name dataset
	if `i' == 1 save level`i'name, replace
	
	* For levels2 & 3 we need level#names and level#order datasets
	if `i' > 1 {
		save level`i'names, replace
		save level`i'order, replace
	}
}

* Make two level1name datasets so the VCTC titles look nice
use level1name, clear
replace level1name = "Jamaica - Ages 12-23m"
save level1name_12_to_23m, replace
replace level1name = "Jamaica - Ages 24-35m"
save level1name_24_to_35m, replace

********************************************************************************
***************					Level 4 Dataset					****************
********************************************************************************

* If you wish to create a level4 dataset, you can do so by using the below code. 
* This will align with the Report output

* this can be tweaked to group things together that do not have enough respondents in a category.
* For example: At the end of this program we will group Primary or Less and Lower SEcondary education into one group 

use Full_dataset, clear
keep RI20 urban_cluster melevel ethnicity religion windex5

* Set a local to hold the label for each section
local RI20 			Sex
local urban_cluster Area 
local melevel 		Mother's education
local ethnicity 	Ethnicity of household head
local religion		Religion/Denomination of household head
local windex5		Wealth index quintile

local color0		vcqi_level1
local color1 		vcqi_level3
local color2 		vcqi_level4
local color3		sienna*.5
local color4		eltgreen*.5
local color5 		olive*.5
local color6 		orange*.5

capture postclose mkt
postfile mkt str250(label condition_stata rowtype fmtid_for_first_column_stata fmtid_for_other_columns_stata bar_fillcolor1_stata outlinecolor1_stata ) using Jamaica_level4_layout, replace

* The first row will show everyone in the country 
* We want this to be bolded and to show in a single row so the label will be in the same row as the data
post mkt ("Jamaica") ("1==1") ("DATA_ROW") ("bold_left") ("bold_right") ("`color0'") ("`color0'") 

* Put a line between the country data and the other stratifiers 
post mkt ("") ("") ("BLANK_ROW") ("bold_left") ("bold_right") ("") ("")

* Set a local that keeps count of the variables and will be used to set the colors for each new variable
local i 1
foreach v in RI20 urban_cluster melevel ethnicity religion windex5 {
	* Post a line that holds the label for each stratifier 
	* If we use the "shaded_left_italic" fmtid this will apply a light gray background to the row and show the text in italics. This formatid will need to be created in a separate .do file for Stata to read 
	post mkt ("``v''") ("") ("LABEL_ONLY") ("shaded_left_italic") ("shaded_left_italic") ("") ("") 
	
	* For the Area we want to also capture a row that holds both Urban groups
	if "`v'" == "urban_cluster" {
			post mkt ("Urban") ("inlist(`v',1,2)") ("DATA_ROW") ("italic_left_indented3") ("regular_right") ("`color`i''") ("`color`i''") 
	}
	* Grab the different levels of the variable
	qui levelsof `v', local(vlist)
	
	* Set a local with the value label for the variable 
	local lab `:value label `v''
	foreach val in `vlist' {
		
		* Check to see if category has more than 3 people, if not, it can be skipped
		qui count if `v' == `val'
		di "`r(N)'"
		if `r(N)' > 3 {
		
			local header `val'
			if "`lab'" != "" local header `:label `lab' `val''
			
			* Here is the breakdown of the different values for this section:
			* label : `header' (Value label)
			* condition_stata : `v' == `val' (Variable = Value)
			* rowtype : DATA_ROW 
			* fmtid_for_first_column_stata : italic_left_indented3 (Because we have nested information we want the value labels to be indented and italic)
			* fmtid_for_other_columns_stata : regular_right (We want the actual output numbers to be in regular font and format)
			* bar_fillcolor1_stata : color`i' (So that each variable has it's own color in charts)
			* outlinecolor1_stata : color`i' (So that each variable has it's own color in charts)

			local label_fmtid italic_left_indented3
			
			* For the 2 different Urban rows we want them nested under the total Urban row so we will use a special fmtid: italic_left_indented6. This will need to be created in the same .do file as shaded_left_italic 
			if "`v'"=="urban_cluster" & inlist(`val',1,2) local label_fmtid italic_left_indented6
			
			* We want these labels to be italic and indented so we are using: standard VCQI fmtid italic_left_indented3 
			post mkt ("`header'") ("`v'==`val'") ("DATA_ROW") ("`label_fmtid'") ("regular_right") ("`color`i''") ("`color`i''") 
		} // end count check if statement


	} // end value loop
	
	* Increase the color#
	local ++i
} // end variable loop

postclose mkt
use Jamaica_level4_layout, clear
compress


* Make the label proper if not a LABEL_ONLY
replace label = proper(label) if rowtype == "DATA_ROW"
* Make OF and OR in lower
replace label = subinstr(label," Of "," of ",.)
replace label = subinstr(label," Or "," or ",.)

* Clean up the two Urban labels
replace label = "GKMA" if label == "Greater Kingston Metropolitan Area (Gkma)"
replace label = "Other" if label == "Other Urban Centers (Ouc)"

* Combine primary and lower secondary into one group
replace condition_stata = "inlist(melevel,1,2)" if label == "Primary or Less"
replace label = "Lower Secondary Or Less" if label == "Primary or Less"
drop if label == "Lower Secondary"

* Drop the rows that have Missing/Dk labels 
drop if label == "Missing/Dk"

gen order = _n
order order
save, replace