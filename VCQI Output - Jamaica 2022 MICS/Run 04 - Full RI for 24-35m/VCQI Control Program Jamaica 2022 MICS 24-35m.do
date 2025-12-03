*! - Users Guide RI Control Program version 1.12 - Biostat Global Consulting - 2025-08-21
********************************************************************************
* Vaccination Coverage Quality Indicators (VCQI) control program to analyze
* data from a routine immunization survey 
*
* This program is configured to analyze the VCQI demonstration datasets
* from a fictional coverage survey in the
* fictional country of Harmonia.  It serves as a template that users
* may copy to use with new datasets from real surveys.  
*
* After copying the program, make a set of edits in Blocks RI-B and RI-D and 
* RI-F below in accordance with guidance in the VCQI User's Guide.
*
* This program example is described in detail in Chapter 7 of the 
* VCQI User's Guide.
*
* You will find the latest versions of VCQI documentation and programs at the
* VCQI Resources Website:  http://www.biostatglobal.com/VCQI_RESOURCES.html
*
* Written by Biostat Global Consulting
*
* See comments at the bottom of program for log of program updates.
*
* IMPORTANT: The user may customize this program by changing items below in
* code blocks marked RI-B, RI-D, and RI-F below.  Those blocks are marked 
* "(User may change)".
* 
********************************************************************************
* Code Block: RI-A                                               (Do not change)
*-------------------------------------------------------------------------------
*                  Start with clear memory
*-------------------------------------------------------------------------------

set more off

clear all

macro drop _all

********************************************************************************
* Code Block: RI-B                                            (User may change)
*-------------------------------------------------------------------------------
*                  Specify input/output folders & analysis name
*-------------------------------------------------------------------------------

* Where have you saved the VCQI Stata source code?

* global S_VCQI_SOURCE_CODE_FOLDER      C:/Users/Dale/Dropbox (Biostat Global)/DAR GitHub Repos/vcqi-stata-bgc

* We recommend that VCQI Users establish the global S_VCQI_SOURCE_CODE_FOLDER
* in the profile.do program that lives in your Stata personal folder.
* (Type the command 'personal' to learn the location of what Stata calls 
*  your personal folder.)
*
* Alternatively, you may uncomment the line of code above and set the 
* global here.  Make its value the path to the folder that holds your 
* current VCQI source folders.

* Note that the S_VCQI_SOURCE_CODE_FOLDER global is used in the six 
* lines of code below

adopath + "${S_VCQI_SOURCE_CODE_FOLDER}/DESC"
adopath + "${S_VCQI_SOURCE_CODE_FOLDER}/DIFF"
adopath + "${S_VCQI_SOURCE_CODE_FOLDER}/LIBRARY"
adopath + "${S_VCQI_SOURCE_CODE_FOLDER}/PLOT"
adopath + "${S_VCQI_SOURCE_CODE_FOLDER}/RI"
adopath + "${S_VCQI_SOURCE_CODE_FOLDER}/SIA"
adopath + "${S_VCQI_SOURCE_CODE_FOLDER}/TT"

vcqi_adopath_check

* Where should the programs look for datasets?
global VCQI_DATA_FOLDER    	Q:/VCD - Jamaica 2022 MICS/VCD Ready files
* Where should the programs put output?
global VCQI_OUTPUT_FOLDER  Q:/VCQI Output - Jamaica 2022 MICS/Run 04 - Full RI for 24-35m

* Establish analysis name (used in log file name and Excel file name)

global VCQI_ANALYSIS_NAME Jamaica_24_to_35m

* Set this global to 1 to test all metadata and code that makes
* datasets and calculates derived variables...without running the
* indicators or generating output

global	VCQI_CHECK_INSTEAD_OF_RUN		0

********************************************************************************
* Code Block: RI-C                                               (Do not change)
*-------------------------------------------------------------------------------
*                  Put VCQI in the Stata Path and
*                CD to output folder & open VCQI log
*-------------------------------------------------------------------------------

* CD to the output folder and start the log 
cd "${VCQI_OUTPUT_FOLDER}"

* Start with a clean, empty Excel file for tabulated output (TO)
capture erase "${VCQI_OUTPUT_FOLDER}/${VCQI_ANALYSIS_NAME}_TO.xlsx"

* Give the current program a name, for logging purposes
global VCP RI_Control_Program

* Open the VCQI log and put a comment in it
vcqi_log_comment $VCP 3 Comment "Run begins...log opened..."
	
* Document the global macros that were defined before the log opened
vcqi_log_global VCQI_DATA_FOLDER
vcqi_log_global VCQI_OUTPUT_FOLDER
vcqi_log_global VCQI_ANALYSIS_NAME

* Write an entry in the log file for each program, noting its version number

vcqi_log_all_program_versions

********************************************************************************
* Code Block: RI-D                                             (User may change)
*-------------------------------------------------------------------------------
*                  Specify dataset names and important metadata
*-------------------------------------------------------------------------------

* Name of datasets that hold RI data
vcqi_global VCQI_RI_DATASET     MICS_6_to_VCQI_RI_24_to_35m
vcqi_global VCQI_RIHC_DATASET 	

* Name of dataset that holds cluster metadata
vcqi_global VCQI_CM_DATASET     MICS_6_to_VCQI_CM

* If you will describe the dataset using DESC_01 then you need to also specify
* the HH and HM datasets

vcqi_global VCQI_HH_DATASET     
vcqi_global VCQI_HM_DATASET     

* --------------------------------------------------------------------------
* Parameters to describe RI schedule 
* --------------------------------------------------------------------------
* These parameters may change from survey to survey

* See:
* http://www.who.int/immunization/policy/Immunization_routine_table2.pdf?ua=1 
* http://apps.who.int/immunization_monitoring/globalsummary/schedules
*
* Updated URL: https://immunizationdata.who.int/listing.html

* Single-dose antigens will use a parameter named <dose>_min_age_days (required)
* Single-dose antigens may  use a parameter named <dose>_max_age_days (optional)
* Note: If a dose is not considered valid *AFTER* a certain age, then specify
*       that maximum valid age using the _max_age_days parameter.
*       If the dose is considered late, but still valid, then do not specify
*       a maximum age.


*global RI_LIST 		bcg opv1 opv2 opv3 penta1 penta2 penta3 mmr1 mmr2 dpt opv4 

* THese are taken from the Questionnaire
vcqi_scalar bcg_min_age_days 			= 0  // birth dose

* Note: In this country, opv0 and hepb0 are only considered valid 
*       if given in the first two weeks of life

vcqi_scalar penta1_min_age_days 		= 42  // 6 weeks
vcqi_scalar penta2_min_age_days 		= 90  // 3 months
vcqi_scalar penta2_min_interval_days 	= 28  // 4 weeks
vcqi_scalar penta3_min_age_days 		= 180  // 6 months
vcqi_scalar penta3_min_interval_days 	= 28  // 4 weeks

vcqi_scalar polio1_min_age_days 		= 42  // 6 weeks
vcqi_scalar polio2_min_age_days 		= 90  // 3 months
vcqi_scalar polio2_min_interval_days 	= 28  // 4 weeks
vcqi_scalar polio3_min_age_days 		= 180  // 6 months
vcqi_scalar polio3_min_interval_days 	= 28  // 4 weeks
vcqi_scalar polio4_min_age_days 		= 540  //18 months

vcqi_scalar opv1_min_age_days 			= 42  // 6 weeks
vcqi_scalar opv2_min_age_days 			= 90  // 3 months
vcqi_scalar opv2_min_interval_days 		= 28  // 4 weeks
vcqi_scalar opv3_min_age_days 			= 180  // 6 months
vcqi_scalar opv3_min_interval_days 		= 28  // 4 weeks
vcqi_scalar opv4_min_age_days 			= 540  //18 months

vcqi_scalar dpt4_min_age_days 			= 540 // 18 months

vcqi_scalar mmr1_min_age_days 			= 365  // 12 months
vcqi_scalar mmr2_min_age_days 			= 540  // 18 months
vcqi_scalar mmr2_min_interval_days 		= 28  // 4 weeks


* --------------------------------------------------------------------------
* Parameters to describe survey
* --------------------------------------------------------------------------
* Specify the earliest and latest possible vaccination date for this survey.
*
* The software assumes this survey includes birth doses, so the earliest date
* is the first possible birthdate for RI survey respondents and the latest
* date is the last possible vaccination date for this dataset - the latest
* date might be the date of the final survey interview.
 
vcqi_global EARLIEST_SVY_VACC_DATE_M  	4
vcqi_global EARLIEST_SVY_VACC_DATE_D  	1
vcqi_global EARLIEST_SVY_VACC_DATE_Y  	2019 // First interview date 12apr2022
 
vcqi_global LATEST_SVY_VACC_DATE_M  	8
vcqi_global LATEST_SVY_VACC_DATE_D  	3
vcqi_global LATEST_SVY_VACC_DATE_Y  	2022 // last interview date 03aug2022

* These parameters indicate the eligible age range for survey respondents
* (age expressed in days)

vcqi_global VCQI_RI_MIN_AGE_OF_ELIGIBILITY  730
vcqi_global VCQI_RI_MAX_AGE_OF_ELIGIBILITY 1095

* These following parameters help describe the survey protocol
* with regard to whether they:
* a) skipped going to health centers to find RI records (RI_RECORDS_NOT_SOUGHT 1)
* b) looked for records for all respondents (RI_RECORDS_SOUGHT_FOR_ALL 1)
* c) looked for records for women who didn't present vaccination cards
*    during the household interview (RI_RECORDS_SOUGHT_IF_NO_CARD 1)
*
* These are mutually exclusive, so only one of them should be set to 1.
* 
vcqi_global RI_RECORDS_NOT_SOUGHT        1
vcqi_global RI_RECORDS_SOUGHT_FOR_ALL    0
vcqi_global RI_RECORDS_SOUGHT_IF_NO_CARD 0

* --------------------------------------------------------------------------
* Which doses should be included in the analysis?
* --------------------------------------------------------------------------

* Note that these abbreviations must correspond to those used in the
* names of the dose date and dose tick variables *AND* the names used 
* above in the schedule scalars (<dose>_min_age_days and 
* <dose>_min_interval_days and <dose>_max_days.  The variables are 
* named using lower-case acronyms.  The globals here may be upper or
* mixed case...they will be converted to lower case in the software.
* global RI_LIST 		bcg opv1 opv2 opv3 penta1 penta2 penta3 mmr1 mmr2 dpt4 opv4 

vcqi_global RI_SINGLE_DOSE_LIST  BCG dpt4 polio4
vcqi_global RI_MULTI_2_DOSE_LIST mmr
vcqi_global RI_MULTI_3_DOSE_LIST PENTA polio 

* But to align with the report we do not want to fill history holes
vcqi_global DO_NOT_FILL_HISTORY_HOLES 1
* --------------------------------------------------------------------------
* Do you want to shift doses?
* --------------------------------------------------------------------------

* This can be done with multi-dose vaccines and/or boosters.

vcqi_global NUM_DOSE_SHIFTS 0	// Number of dose series you would like to shift
					            // Wipe out or set to 0 if you do not wish to complete any shifts
								
vcqi_global SHIFTTO_1       penta1 penta2 penta3 // List of doses where evidence will be shifted *to*. Must be set if you want to shift.
vcqi_global SHIFTFROM_1     penta4 penta5	     // List of doses where evidence will be shifted *from*.  Defaults to empty list.
vcqi_global SHIFTWITHIN_1   0                    // Default is to *not* shift doses within the SHIFTTO list.  To do so, set this to 1. 
vcqi_global DROPDUP_1       0                    // Default is to *not* delete duplicate dates within a series.  To do so, set this to 1.

vcqi_global SHIFTTO_2       polio1 polio2 polio3 
vcqi_global SHIFTFROM_2     polio4 polio5	       

* --------------------------------------------------------------------------
* Parameters to describe the analysis being requested
* --------------------------------------------------------------------------

* Name the datasets that give geographic names of the various strata
* and list the order in which strata should appear in tabular output.
* See Annex B of the VCQI User's Guide

vcqi_global LEVEL2_ORDER_DATASET ${VCQI_DATA_FOLDER}/level2order
vcqi_global LEVEL3_ORDER_DATASET ${VCQI_DATA_FOLDER}/level3order

vcqi_global LEVEL1_NAME_DATASET ${VCQI_DATA_FOLDER}/level1name
vcqi_global LEVEL2_NAME_DATASET ${VCQI_DATA_FOLDER}/level2names
vcqi_global LEVEL3_NAME_DATASET ${VCQI_DATA_FOLDER}/level3names

* The LEVEL4 parameters allow the VCQI user to ask for results to be broken out 
* by levels of:
* a) a single demographic stratifier (like urban/rural), or
* b) a set of several stratifiers (like urban/rural and sex and household wealth)
*
* If the user requests a single stratifier then the stratifier will appear in 
* inchworm and unweighted proportion plots as well as VCQI tables.

* If the user requests two or more stratifiers, they will appear in inchworm and
* unweighted vaccination plots as long as the user *also* specifies that 
* VCQI should plot strata in the same order they appear in tables.
* (i.e., set PLOT_OUTCOMES_IN_TABLE_ORDER to 1).  If the user requests two or
* more stratifiers and wants strata plotted in order of outcome level, then 
* VCQI writes a warning message to the log and simply does not make inchworm 
* or unweighted proportion plots.

* List of demographic variables for stratified tables (can be left blank)
vcqi_global VCQI_LEVEL4_SET_VARLIST RI20 MICS_6_hh6 MICS_6_melevel MICS_6_ethnicity MICS_6_religion MICS_6_windex5 

* Name of dataset that documents the user's preferred order and 
* row labels for LEVEL4 strata
* (VCQI will generate a layout file if one is not specified; you may
*  copy VCQI's file, edit it, move it to the input dataset folder and
*  then point to it here during later VCQI runs.)

vcqi_global VCQI_LEVEL4_SET_LAYOUT  ${VCQI_DATA_FOLDER}/report_level4_stratifiers_v3

* Name of an optional .do file that holds user-defined Stata Excel format IDS 
* to use when formatting Excel tables.  If this is omitted, VCQI will use some 
* sensible defaults, but the user has the option to specify what they want.
*
* The do-file should take inspiration from the file in the VCQI source folder
* LIBRARY/vcqi_basic_fmtids.do
*
* Specify the folder and name of the file, like: ${VCQI_DATA_FOLDER}/custom_fmtids.do
* or ${VCQI_OUTPUT_FOLDER}/xxx_project_VCQI_custom_Excel_fmtids.do

vcqi_global FMTIDS Q:/VCQI Output - Jamaica 2022 MICS/create_level4_fmtids.do

* These globals control how the output looks in the tabulated dataset 
* from the 05TO programs; see Annex B in the VCQI User's Guide.

vcqi_global SHOW_LEVEL_1_ALONE         0
vcqi_global SHOW_LEVEL_2_ALONE         0
vcqi_global SHOW_LEVEL_3_ALONE         0 
vcqi_global SHOW_LEVEL_4_ALONE         1
vcqi_global SHOW_LEVELS_2_3_TOGETHER   0

vcqi_global SHOW_LEVELS_1_4_TOGETHER   0
vcqi_global SHOW_LEVELS_2_4_TOGETHER   0
vcqi_global SHOW_LEVELS_3_4_TOGETHER   0
vcqi_global SHOW_LEVELS_2_3_4_TOGETHER 0

vcqi_global SHOW_BLANKS_BETWEEN_LEVELS 1

* User specifies the Stata svyset syntax to describe the complex sample
vcqi_global VCQI_SVYSET_SYNTAX svyset clusterid, strata(stratumid) weight(psweight) singleunit(scaled)

* List any additional covariates that should be passed thru from the survey 
* dataset into all indicator datasets.  i.e., any extra variables that are 
* part of the svyset syntax besides clusterid, stratumid, psweight.
* This option is rarely used.
vcqi_global VCQI_PASS_THRU_VARLIST 

* User specifies the method for calculating confidence intervals
* Valid choices are LOGIT, WILSON, JEFFREYS or CLOPPER; our default 
* recommendation is WILSON.

vcqi_global VCQI_CI_METHOD WILSON

* Specify whether the code should export to excel, or not (usually 1)

vcqi_global EXPORT_TO_EXCEL 				1

* Specify whether to write tables as strings (usually yes)

vcqi_global VCQI_MAKE_STRING_TABLES         1

* Specify if you would like the excel columns to be narrow in tabulated output
* Set to 1 for yes 
vcqi_global MAKE_EXCEL_COLUMNS_NARROW 		1

* User specifies the number of digits after the decimal place in coverage
* outcomes

vcqi_global VCQI_NUM_DECIMAL_DIGITS			1

* Specify whether the code should make plots, or not (usually 1)

* MAKE_PLOTS must be 1 for any plots to be made
vcqi_global MAKE_PLOTS      				1

* Set PLOT_OUTCOMES_IN_TABLE_ORDER to 1 if you want inchworm and 
* unweighted plots to list strata in the same order as the tables;
* otherwise the strata will be sorted by the outcome and shown in
* bottom-to-top order of increasing indicator performance
vcqi_global PLOT_OUTCOMES_IN_TABLE_ORDER 	1

* Make inchworm plots? Set to 1 for yes.
vcqi_global VCQI_MAKE_IW_PLOTS				1

* If there are a lot of level2 strata with a lot of level3 strata nested
* within, you might consider (or need to) suppress the overall iwplots
* (the plots that show every level2 and level3 stratum)
* and focus only on the several level2 iwplots 
* (one plot per outcome per level2 stratum that shows the level2 outcome
*  along with outcomes for all the level3 strata within that level2 stratum)
vcqi_global VCQI_SUPPRESS_OVERALL_IWPLOTS   0
vcqi_global VCQI_MAKE_LEVEL2_IWPLOTS		0

* Suppress showing LCB and UCB tick marks on inchworm and bar plots
vcqi_global IWPLOT_SUPPRESS_TICKS 			1

* Text at right side of inchworm plots
* 1 1-sided 95% LCB | Point Estimate | 1-sided 95% UCB
* 2 Point Estimate (2-sided 95% Confidence Interval)  [THIS IS THE DEFAULT]
* 3 Point Estimate (2-sided 95% Confidence Interval) (0, 1-sided 95% UCB]
* 4 Point Estimate (2-sided 95% Confidence Interval) [1-sided 95% UCB, 100)
* 5 Point Estimate (2-sided 95% CI) (0, 1-sided 95% UCB] [1-sided 95% LCB, 100)
vcqi_global VCQI_IWPLOT_CITEXT 				2

* Text at right side of double inchworm plots
* 1 (default) means show both point estimates
* 2 means show both point estimates and both 2-sided 95% CIs
* 3 means do not show any text
vcqi_global VCQI_DOUBLE_IWPLOT_CITEXT 		1

* IWPLOT_SHOWBARS = 0 means show inchworm distributions
* IWPLOT_SHOWBARS = 1 means show horizontal bars instead of inchworms
vcqi_global IWPLOT_SHOWBARS					1

* Make unweighted sample proportion plots? Set to 1 for yes.
vcqi_global VCQI_MAKE_UW_PLOTS				1

* If there are a lot of level2 strata with a lot of level3 strata nested
* within, you might consider (or need to) suppress the overall uwplots
* (the plots that show every level2 and level3 stratum)
* and focus only on the several level2 uwplots 
* (one plot per outcome per level2 stratum that shows the level2 outcome
*  along with outcomes for all the level3 strata within that level2 stratum)
vcqi_global VCQI_SUPPRESS_OVERALL_UWPLOTS   0
vcqi_global VCQI_MAKE_LEVEL2_UWPLOTS		0

* These two inputs control the aspect ratio of inchworm plots, bar charts,
* and unweighted proportion plots.  Sometimes the default plot
* ratio clips text at the right side of the plot.  If that happens
* to you, experiment with XSIZE and YSIZE values until you find a combination
* that works well.  Theses parameters take values from 1 to 20 (to be compatible
* with Stata v14.1).  The aspect ratio of the figures will be YSIZE:XSIZE.
* These two inputs are rarely used.  
vcqi_global IW_UW_XSIZE
vcqi_global IW_UW_YSIZE

* Make organ pipe plots? Set to 1 for yes.
vcqi_global VCQI_MAKE_OP_PLOTS				0

* Save the data underlying each organ pipe plot?  Set to 1 for yes.
*
* Recall that organ pipe plots do not include many quantitative details
* and do not list the cluster id for any of the bars.
*
* If this option is turned on, (set to 1) then the organ pipe plot program 
* will save a dataset in the Plots_OP folder for each plot.  The dataset will 
* list the cluster id for each bar in the plot along with its height and width.
* This makes it possible to identify which cluster id goes with which bar in
* the plot and to understand the quantitative details of each bar.

vcqi_global VCQI_SAVE_OP_PLOT_DATA			0

* Specify whether the code should save Stata .gph files when making plots.
* Usually 0.  These files are only made if MAKE_PLOTS is 1.  
* Set to 1 if you want to be able to edit plots in the Stata Graph Editor
* or re-export them in a different size or graphic file format.

vcqi_global SAVE_VCQI_GPH_FILES				1

* Specify whether to save the dataset that is in memory at the time each and
* every figure is produced.  It only makes sense to do this if you also set
* SAVE_VCQI_GPH_FILES to 1.  This is a rare option that is used to debug Stata
* graphics issues between operating systems and Stata versions; it saves a lot
* of datasets in the PLOTS_* folders.  This option should usually be set to 0.

vcqi_global VCQI_EXPORT_GPH_DATASETS 		1

* Specify whether the code should save VCQI output databases
*
* WARNING!! If this macro is set to 1, VCQI will delete ALL files that
* end in _database.dta in the VCQI_OUTPUT_FOLDER at the end of the run
* If you want to delete the databases, change the value to 1. (Usually 0)
*
* If you wish to keep the databases and aggregate them into a single dataset, 
* set the DELETE option to 0 and set the AGGREGATE option to 1.

vcqi_global DELETE_VCQI_DATABASES_AT_END	0
vcqi_global AGGREGATE_VCQI_DATABASES		1

* If you want to save indivdiual databases for a special purpose - without
* having them be aggregated together, then un-comment this line of code:
* vcqi_global AGGREGATE_VCQI_DATABASES        0

* Specify whether the code should delete intermediate datasets 
* at the end of the analysis (Usually 1)
* If you wish to keep them for additional analysis or debugging,
* set the option to 0. 

vcqi_global DELETE_TEMP_VCQI_DATASETS		0

* For RI analysis, there is an optional report on data quality
* Set this global to 1 to generate that report
* It appears in its own separate Excel file.

vcqi_global VCQI_REPORT_DATA_QUALITY		1

* Set this global to 0 if you do not wish to create an augmented dataset
* that merges survey dataset with derived variables calculated by VCQI.
* Default value is 1 (yes)

vcqi_global VCQI_MAKE_AUGMENTED_DATASET		1

* Specify the language for table and figure text. 
* Current options are ENGLISH, SPANISH, FRENCH, or PORTUGUESE

vcqi_global OUTPUT_LANGUAGE English

* Specify the row character cut off length for plot Title
* meaning if a Title is > ### characters it will be split onto the next line(s)  
vcqi_global TITLE_CUTOFF

* Specify the row character cut off length for plot Footnotes
* meaning if a Footnotes is > ### characters it will be split onto the next line(s)  
vcqi_global FOOTNOTE_CUTOFF

********************************************************************************
* Code Block: RI-E                                               (Do not change)
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
* Use figure appearance consistent with Stata v14 and use Lato font
*-------------------------------------------------------------------------------
set scheme s2color
graph set window fontface Lato

*-------------------------------------------------------------------------------
* Format the VCQI dose list and pre-process survey data
*-------------------------------------------------------------------------------

* Construct the global RI_DOSE_LIST from what the user specified above
* VCQI currently handles single-dose, two-dose, & three-dose vaccines. 

* First, list single dose vaccines 
global RI_DOSE_LIST `=ustrlower("$RI_SINGLE_DOSE_LIST")'

* Then list each dose for two-dose vaccines 
foreach i in $RI_MULTI_2_DOSE_LIST {
	global RI_DOSE_LIST "$RI_DOSE_LIST `=ustrlower("`i'")'1 `=ustrlower("`i'")'2"
}

* Finally, list each dose for three-dose vaccines 
foreach i in $RI_MULTI_3_DOSE_LIST {
	global RI_DOSE_LIST "$RI_DOSE_LIST `=ustrlower("`i'")'1 `=ustrlower("`i'")'2 `=ustrlower("`i'")'3"
}


global RI_DOSE_LIST bcg polio1 polio2 polio3 penta1 penta2 penta3 mmr1 polio4 dpt4 mmr2

* Put a copy of the dose list in the log
vcqi_log_global RI_DOSE_LIST

* --------------------------------------------------------------------------
* Check the user's metadata for completeness and correctness
* --------------------------------------------------------------------------

check_RI_schedule_metadata
check_RI_survey_metadata
check_RI_analysis_metadata

* Run the program to look at date of birth (from history, card, and register)
* and look at dates of vaccination from cards and register.  This program 
* evaluates each date and checks to see that it occurred in the period
* allowed for respondents eligible for this survey.  It also checks to see 
* that doses in a sequence were given in order.  If any vaccination date 
* seems to be outside the right range or recorded out of sequence, the date
* is stripped off and replaced with a simple yes/no tick mark.  This step
* means less date-checking is necessary in subsequent programs.

cleanup_RI_dates_and_ticks

* The name of the datasets coming out of these cleanup steps are:
* "${VCQI_OUTPUT_FOLDER}/${VCQI_DATASET}_clean" &
* "${VCQI_OUTPUT_FOLDER}/${VCQI_RIHC_DATASET}_clean"

* --------------------------------------------------------------------------
* Establish unique IDs
* --------------------------------------------------------------------------

* The name of the dataset coming out of the ID step is RI_with_ids
establish_unique_RI_ids

* If the user requests a check instead of a run, then turn off
* flags that result in databases, excel output, and plots

if "$VCQI_CHECK_INSTEAD_OF_RUN" == "1" {
	vcqi_log_comment $VCP 3 Comment "The user has requested a check instead of a run."
	vcqi_global VCQI_PREPROCESS_DATA	0
	vcqi_global VCQI_GENERATE_DVS		0
	vcqi_global VCQI_GENERATE_DATABASES 0
	vcqi_global EXPORT_TO_EXCEL			0
	vcqi_global	MAKE_PLOTS				0
}


********************************************************************************
* Code Block: RI-F                                             (User may change)
*-------------------------------------------------------------------------------
*                  Calculate VCQI indicators requested by the user
*-------------------------------------------------------------------------------

* This is a counter that is used to name datasets...it is usually set to 1 but
* the user might change it if requesting repeat analyses with differing 
* parameters - see the User's Guide

vcqi_global ANALYSIS_COUNTER 1

* Most indicators may be run in any order the user wishes, although there are 
* are some restrictions...see the table in the section of Chapter 6 entitled 
* Analysis Counter.
* 
* We recommend running DESC indicators first, 

* --------------------------------------------------------------------------
* Summarize vaccination coverage
* --------------------------------------------------------------------------
		
* Estimate crude dose coverage for all the doses in the RI_DOSE_LIST
vcqi_global RI_COVG_01_TO_TITLE    	  `=ustrtitle("${OS_390}")' //Crude Coverage
vcqi_global RI_COVG_01_TO_SUBTITLE
vcqi_global RI_COVG_01_TO_FOOTNOTE_1  ${OS_337}  //Abbreviations: CI = Confidence Interval; LCB = Lower Confidence Bound; UCB = Upper Confidence Bound; DEFF = Design Effect; ICC = Intracluster Correlation Coefficient
vcqi_global RI_COVG_01_TO_FOOTNOTE_2  ${OS_338} //Note: This measure is a population estimate that incorporates survey weights. The CI, LCB and UCB are calculated with software that takes the complex survey design into account.
vcqi_global SORT_PLOT_LOW_TO_HIGH 1 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_COVG_01
* Estimate valid dose coverage 
	
vcqi_global RI_COVG_02_TO_TITLE       `=ustrtitle("${OS_396}")' //Valid Coverage
vcqi_global RI_COVG_02_TO_SUBTITLE
vcqi_global RI_COVG_02_TO_FOOTNOTE_1  ${OS_337}  //Abbreviations: CI = Confidence Interval; LCB = Lower Confidence Bound; UCB = Upper Confidence Bound; DEFF = Design Effect; ICC = Intracluster Correlation Coefficient
vcqi_global RI_COVG_02_TO_FOOTNOTE_2  ${OS_338} //Note: This measure is a population estimate that incorporates survey weights. The CI, LCB and UCB are calculated with software that takes the complex survey design into account.
vcqi_global SORT_PLOT_LOW_TO_HIGH 1 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_COVG_02

* Estimate proportion of respondents fully vaccinated
vcqi_global RI_DOSES_TO_BE_FULLY_VACCINATED bcg polio1 polio2 polio3 penta1 penta2 penta3 mmr1

vcqi_global RI_COVG_03_TO_TITLE       `=ustrtitle("${OS_217}")' - Basic doses //Fully Vaccinated
vcqi_global RI_COVG_03_TO_SUBTITLE
vcqi_global RI_COVG_03_TO_FOOTNOTE_1  ${OS_337}  //Abbreviations: CI = Confidence Interval; LCB = Lower Confidence Bound; UCB = Upper Confidence Bound; DEFF = Design Effect; ICC = Intracluster Correlation Coefficient
vcqi_global RI_COVG_03_TO_FOOTNOTE_2  ${OS_338} //Note: This measure is a population estimate that incorporates survey weights. The CI, LCB and UCB are calculated with software that takes the complex survey design into account.	
vcqi_global RI_COVG_03_TO_FOOTNOTE_3  ${OS_108} $RI_DOSES_TO_BE_FULLY_VACCINATED //Note: To be fully vaccinated, the child must have received: $RI_DOSES_TO_BE_FULLY_VACCINATED
vcqi_global SORT_PLOT_LOW_TO_HIGH 1 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_COVG_03

* Estimate proportion of respondents not vaccinated
* (This measure also uses the global macro RI_DOSES_TO_BE_FULLY_VACCINATED)
	
vcqi_global RI_COVG_04_TO_TITLE       `=ustrtitle("${OS_403}")' //Not Vaccinated
vcqi_global RI_COVG_04_TO_SUBTITLE
vcqi_global RI_COVG_04_TO_FOOTNOTE_1  ${OS_337}  //Abbreviations: CI = Confidence Interval; LCB = Lower Confidence Bound; UCB = Upper Confidence Bound; DEFF = Design Effect; ICC = Intracluster Correlation Coefficient
vcqi_global RI_COVG_04_TO_FOOTNOTE_2  ${OS_338} //Note: This measure is a population estimate that incorporates survey weights. The CI, LCB and UCB are calculated with software that takes the complex survey design into account.
vcqi_global RI_COVG_04_TO_FOOTNOTE_3  ${OS_431} $RI_DOSES_TO_BE_FULLY_VACCINATED //Note: To be counted as not vaccinated, the child must not have received any of these doses: $RI_DOSES_TO_BE_FULLY_VACCINATED
vcqi_global SORT_PLOT_LOW_TO_HIGH 0 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_COVG_04


* --------------------------------------------------------------------------
* Identify clusters with alarmingly low coverage of BCG MCV1 OPV1 or PENTA1

vcqi_global RI_COVG_05_DOSE_LIST BCG MMR1 POLIO1 PENTA1

* Specify whether to make one table listing only the clusters with low 
* coverage (ONLY_LOW_CLUSTERS)
* or to make one table per stratum, listing all clusters and highlighting
* those with low coverage (ALL_CLUSTERS)
vcqi_global RI_COVG_05_TABLES ONLY_LOW_CLUSTERS

* Specify whether alarmingly low coverage is defined by an absolute
* number of respondents vaccinated (COUNT) or by percent of respondents
* in the cluster (PERCENT)
vcqi_global RI_COVG_05_THRESHOLD_TYPE COUNT

* Specify the threshold that defines alarmingly low 
* A count, like 0, 1, 2 if the THRESHOLD_TYPE is COUNT
* A percent 0 up to 100 if the THRESHOLD_TYPE is PERCENT

* Clusters whose coverage is <= the threshold will be flagged 
* as having alarmingly low coverage.
vcqi_global RI_COVG_05_THRESHOLD 2

* Establish FOOTNOTE_1 and _2, depending on the values of the global macros 
* RI_COVG_05_TABLES and THRESHOLD_TYPE
*
* Note that we use these two globals here without checking for valid values.
* If their values are not valid, the program RI_COVG_05 below will stop with
* an error *before* these footnotes are used in any tables.

if "`=ustrupper("$RI_COVG_05_TABLES")'" == "ALL_CLUSTERS" ///
	vcqi_global RI_COVG_05_TO_FOOTNOTE_1 ${OS_432}. //Note: Shaded rows have alarmingly low coverage for at least one dose.

if "`=ustrupper("$RI_COVG_05_TABLES")'" == "ONLY_LOW_CLUSTERS" ///
	vcqi_global RI_COVG_05_TO_FOOTNOTE_1 ${OS_433}. //Note: Each row has alarmingly low coverage for at least one dose.

if "`=ustrupper("$RI_COVG_05_THRESHOLD_TYPE")'" == "COUNT" ///
	local criterion_string ${OS_434} ${OS_435} ${RI_COVG_05_THRESHOLD} //N who received at least one dose in the list <= ${RI_COVG_05_THRESHOLD}

if "`=ustrupper("$RI_COVG_05_THRESHOLD_TYPE")'" == "PERCENT" ///
	local criterion_string ${OS_436} ${OS_435} ${RI_COVG_05_THRESHOLD}% //the weighted % who received at least one dose in the list <= ${RI_COVG_05_THRESHOLD}%

vcqi_global RI_COVG_05_TO_FOOTNOTE_2 ${OS_293}: `criterion_string'. // In this table, alarmingly low means: `criterion_string'.


* Note that the worksheet title is built by the indicator and not specified 
* by the user.
* Note also the indicator builds footnotes 1 and 2, so the first 
* user-specified footnote would be #3. 
vcqi_global RI_COVG_05_TO_FOOTNOTE_3

*RI_COVG_05

* --------------------------------------------------------------------------
* Characterize access to services using the crude coverage of PENTA1
* --------------------------------------------------------------------------
vcqi_global RI_ACC_01_DOSE_NAME PENTA1
	
vcqi_global RI_ACC_01_TO_TITLE       ${OS_286} `=ustrupper("$RI_ACC_01_DOSE_NAME")' - ${OS_14} //Received `=ustrupper("$RI_ACC_01_DOSE_NAME")' - Crude
vcqi_global RI_ACC_01_TO_SUBTITLE
vcqi_global RI_ACC_01_TO_FOOTNOTE_1  ${OS_337}  //Abbreviations: CI = Confidence Interval; LCB = Lower Confidence Bound; UCB = Upper Confidence Bound; DEFF = Design Effect; ICC = Intracluster Correlation Coefficient
vcqi_global RI_ACC_01_TO_FOOTNOTE_2  ${OS_338} //Note: This measure is a population estimate that incorporates survey weights. The CI, LCB and UCB are calculated with software that takes the complex survey design into account.
vcqi_global SORT_PLOT_LOW_TO_HIGH 1 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_ACC_01

* --------------------------------------------------------------------------
* Calculate issues with continuity (dropout) for three dose pairs:
* 1. Dropout from Penta1 to Penta3
* 2. Dropout from OPV1 to OPV3
* 3. Dropout from Penta3 to MCV1
* --------------------------------------------------------------------------

* Calculate a *weighted* version of dropout  
* which gives output that corresponds to the common formula: 
* dropout % = (% who rec'd early dose - % who received later dose) / (% who received early dose)

vcqi_global RI_CONT_01B_DROPOUT_LIST PENTA1 PENTA3 polio1 polio3 PENTA3 mmr1 bcg mmr1 mmr1 mmr2

vcqi_global RI_CONT_01B_TO_TITLE       ${OS_384} //Dropout
vcqi_global RI_CONT_01B_TO_SUBTITLE	
vcqi_global RI_CONT_01B_TO_FOOTNOTE_1  ${OS_337}  //Abbreviations: CI = Confidence Interval; LCB = Lower Confidence Bound; UCB = Upper Confidence Bound; DEFF = Design Effect; ICC = Intracluster Correlation Coefficient
vcqi_global RI_CONT_01B_TO_FOOTNOTE_2  ${OS_338} //Note: This measure is a population estimate that incorporates survey weights. The CI, LCB and UCB are calculated with software that takes the complex survey design into account.
vcqi_global SORT_PLOT_LOW_TO_HIGH 0 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_CONT_01B
*/
* --------------------------------------------------------------------------
* Indicators characterizing the quality of the vaccination program
* --------------------------------------------------------------------------

* Estimate proportion who have a card with vaccination dates on it
	
vcqi_global RI_QUAL_01_TO_TITLE       ${OS_416} `=ustrtitle("${OS_414}")' ${OS_417} //RI Card Availability
vcqi_global RI_QUAL_01_TO_SUBTITLE
vcqi_global RI_QUAL_01_TO_FOOTNOTE_1  ${OS_337}  //Abbreviations: CI = Confidence Interval; LCB = Lower Confidence Bound; UCB = Upper Confidence Bound; DEFF = Design Effect; ICC = Intracluster Correlation Coefficient
vcqi_global RI_QUAL_01_TO_FOOTNOTE_2  ${OS_338} //Note: This measure is a population estimate that incorporates survey weights. The CI, LCB and UCB are calculated with software that takes the complex survey design into account..
vcqi_global SORT_PLOT_LOW_TO_HIGH 1 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_QUAL_01

* Estimate proportion who ever had a vaccination card

vcqi_global RI_QUAL_02_TO_TITLE       ${OS_411} //Ever Received RI Card
vcqi_global RI_QUAL_02_TO_SUBTITLE
vcqi_global RI_QUAL_02_TO_FOOTNOTE_1  ${OS_337}  //Abbreviations: CI = Confidence Interval; LCB = Lower Confidence Bound; UCB = Upper Confidence Bound; DEFF = Design Effect; ICC = Intracluster Correlation Coefficient
vcqi_global RI_QUAL_02_TO_FOOTNOTE_2  ${OS_338} //Note: This measure is a population estimate that incorporates survey weights. The CI, LCB and UCB are calculated with software that takes the complex survey design into account.
vcqi_global SORT_PLOT_LOW_TO_HIGH 1 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_QUAL_02

/*
* Estimate proportion of PENTA1 doses administered that were invalid

vcqi_global RI_QUAL_04_DOSE_NAME PENTA1
vcqi_global RI_QUAL_04_AGE_THRESHOLD 42

vcqi_global RI_QUAL_04_TO_TITLE      `=ustrupper("$RI_QUAL_04_DOSE_NAME")' ${OS_286} ${OS_409} $RI_QUAL_04_AGE_THRESHOLD ${OS_408} // `=ustrupper("$RI_QUAL_04_DOSE_NAME")' Received Before Age $RI_QUAL_04_AGE_THRESHOLD Days
vcqi_global RI_QUAL_04_TO_SUBTITLE
vcqi_global RI_QUAL_04_TO_FOOTNOTE_1  ${OS_347} //Note: This measure is an unweighted summary of a proportion from the survey sample. 
												  
vcqi_global SORT_PLOT_LOW_TO_HIGH 0 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_QUAL_04

* We're going to run RI_QUAL_04 again, so we increment the analysis counter so
* VCQI will not over-write the files from the earlier PENTA1 analysis
vcqi_global ANALYSIS_COUNTER 2

* Run RI_QUAL_04 again to estimate proportion of MCV doses administered before 39 weeks of age
vcqi_global RI_QUAL_04_DOSE_NAME MCV1
vcqi_global RI_QUAL_04_AGE_THRESHOLD `=(39*7)'

vcqi_global RI_QUAL_04_TO_TITLE        `=ustrupper("$RI_QUAL_04_DOSE_NAME")' ${OS_286} ${OS_409} $RI_QUAL_04_AGE_THRESHOLD ${OS_408} //`=ustrupper("$RI_QUAL_04_DOSE_NAME")' Received Before Age $RI_QUAL_04_AGE_THRESHOLD Days
vcqi_global RI_QUAL_04_TO_SUBTITLE
vcqi_global RI_QUAL_04_TO_FOOTNOTE_1  ${OS_347} //Note: This measure is an unweighted summary of a proportion from the survey sample. 
vcqi_global SORT_PLOT_LOW_TO_HIGH 0 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_QUAL_04

* Increment ANALYSIS_COUNTER again so VCQI doesn't over-write the files
* from the MCV1 analysis
vcqi_global ANALYSIS_COUNTER 3

* Run RI_QUAL_04 again to estimate proportion of PENTA3 doses administered before 6 months of age
vcqi_global RI_QUAL_04_DOSE_NAME PENTA3
vcqi_global RI_QUAL_04_AGE_THRESHOLD `=(26*7)'

vcqi_global RI_QUAL_04_TO_TITLE       `=ustrupper("$RI_QUAL_04_DOSE_NAME")' ${OS_286} ${OS_409} ${OS_437} //`=ustrupper("$RI_QUAL_04_DOSE_NAME")' Received Before Age 6 Months
vcqi_global RI_QUAL_04_TO_SUBTITLE
vcqi_global RI_QUAL_04_TO_FOOTNOTE_1  ${OS_347} //Note: This measure is an unweighted summary of a proportion from the survey sample. 
vcqi_global SORT_PLOT_LOW_TO_HIGH 1 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_QUAL_04

* Set ANALYSIS_COUNTER back to 1
vcqi_global ANALYSIS_COUNTER 1
*/

* Estimate proportion of PENTA intra-dose intervals that were shorter than 28 days

vcqi_global RI_QUAL_05_DOSE_NAME PENTA
vcqi_global RI_QUAL_05_INTERVAL_THRESHOLD 28

vcqi_global RI_QUAL_05_TO_TITLE       `=ustrupper("$RI_QUAL_05_DOSE_NAME")' ${OS_407} $RI_QUAL_05_INTERVAL_THRESHOLD ${OS_408} //`=ustrupper("$RI_QUAL_05_DOSE_NAME")' Interval < $RI_QUAL_05_INTERVAL_THRESHOLD Days
vcqi_global RI_QUAL_05_TO_SUBTITLE
vcqi_global RI_QUAL_05_TO_FOOTNOTE_1  ${OS_347} //Note: This measure is an unweighted summary of a proportion from the survey sample. 
vcqi_global RI_QUAL_05_TO_FOOTNOTE_2  ${OS_438} //For this indicator, N is the number of Dose 1 to Dose 2 intervals plus the number of Dose 2 to Dose 3 intervals for which respondents had vaccination dates. Some respondents will have contributed data for no intervals, some for one interval, and some for two intervals.
vcqi_global SORT_PLOT_LOW_TO_HIGH 0 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_QUAL_05

* Estimate proportion of POLIO intra-dose intervals that were shorter than 28 days

vcqi_global ANALYSIS_COUNTER 2

vcqi_global RI_QUAL_05_DOSE_NAME POLIO
vcqi_global RI_QUAL_05_INTERVAL_THRESHOLD 28

vcqi_global RI_QUAL_05_TO_TITLE       `=ustrupper("$RI_QUAL_05_DOSE_NAME")' ${OS_407} $RI_QUAL_05_INTERVAL_THRESHOLD ${OS_408} //`=ustrupper("$RI_QUAL_05_DOSE_NAME")' Interval < $RI_QUAL_05_INTERVAL_THRESHOLD Days
vcqi_global RI_QUAL_05_TO_SUBTITLE
vcqi_global RI_QUAL_05_TO_FOOTNOTE_1  ${OS_347} //Note: This measure is an unweighted summary of a proportion from the survey sample. 
vcqi_global RI_QUAL_05_TO_FOOTNOTE_2  ${OS_438} //For this indicator, N is the number of Dose 1 to Dose 2 intervals plus the number of Dose 2 to Dose 3 intervals for which respondents had vaccination dates. Some respondents will have contributed data for no intervals, some for one interval, and some for two intervals.
vcqi_global SORT_PLOT_LOW_TO_HIGH 0 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_QUAL_05

vcqi_global ANALYSIS_COUNTER 1


* The next three indicators are concerned with Missed Opportunities for Simultaneous Vaccination (MOSV)

* Usually the user will want to see MOSV output for all the doses in the RI_DOSE_LIST
* but sometimes they may want to omit some doses.  Either specify the list of doses
* clearly here, or simply copy the RI_DOSE_LIST into the global MOV_OUTPUT_DOSE_LIST
*
* e.g., to generate MOSV output for only the basic eight EPI doses, we might say:
* vcqi_global MOV_OUTPUT_DOSE_LIST bcg opv1 opv2 opv3 dpt1 dpt2 dpt3 mcv

vcqi_global MOV_OUTPUT_DOSE_LIST $RI_DOSE_LIST

*
* Run the program to establish which dates the child was vaccinated on and
* whether they received every dose for which they were age-eligible (or 
* interval-eligible).  Put the results in a dataset that is ready to be 
* merged in later for MOSV indicators 
*

calculate_MOV_flags

* Estimate what valid coverage would have been if there had been no MOSVs

vcqi_global RI_QUAL_07B_TO_TITLE       ${OS_442} //Coverage if no MOSVs and no early doses
vcqi_global RI_QUAL_07B_TO_SUBTITLE
vcqi_global RI_QUAL_07B_TO_FOOTNOTE_1  ${OS_344} //Abbreviations: CI=Confidence Interval
vcqi_global RI_QUAL_07B_TO_FOOTNOTE_2  ${OS_51} // Note: This measure is a population estimate that incorporates survey weights. The CI is calculated with software that takes the complex survey design into account.
									  
vcqi_global SORT_PLOT_LOW_TO_HIGH 1 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_QUAL_07B

* Estimate the proportion of visits that had MOSVs
vcqi_global RI_QUAL_08_VALID_OR_CRUDE CRUDE

vcqi_global RI_QUAL_08_TO_TITLE       ${OS_164} //Percent of Visits with MOSVs
vcqi_global RI_QUAL_08_TO_SUBTITLE
vcqi_global RI_QUAL_08_TO_FOOTNOTE_1  ${OS_165} //Percent of visits where children were eligible for the dose and did not receive it.
if "`=ustrupper("$RI_QUAL_08_VALID_OR_CRUDE")'" == "VALID" vcqi_global RI_QUAL_08_TO_FOOTNOTE_2 ${OS_90} //Note: Early doses are ignored in this analysis; the respondent is considered to have not received them.
if "`=ustrupper("$RI_QUAL_08_VALID_OR_CRUDE")'" == "CRUDE" vcqi_global RI_QUAL_08_TO_FOOTNOTE_2 ${OS_106} //Note: Early doses are accepted in this analysis; all doses are considered valid doses.
vcqi_global RI_QUAL_08_TO_FOOTNOTE_3 ${OS_166} //Note: The final measure on this sheet, MOSVs per Visit, is not a percent.  It is a ratio.  
vcqi_global SORT_PLOT_LOW_TO_HIGH 0 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_QUAL_08

* Estimate the proportion of children who experienced 1+ MOSVs
vcqi_global RI_QUAL_09_VALID_OR_CRUDE CRUDE

vcqi_global RI_QUAL_09_TO_TITLE       ${OS_167} //Percent of Respondents with MOSVs
vcqi_global RI_QUAL_09_TO_SUBTITLE
vcqi_global RI_QUAL_09_TO_FOOTNOTE_1  ${OS_168} //Percent of respondents who had date of birth and visit date data who failed to receive a vaccination for which they were eligible on an occasion when they received another vaccination.
vcqi_global RI_QUAL_09_TO_FOOTNOTE_2  ${OS_169} //An uncorrected MOSV means that the respondent had still not received a valid dose at the time of the survey.
vcqi_global RI_QUAL_09_TO_FOOTNOTE_3  ${OS_170} //A corrected MOSV means that the respondent had received a valid dose by the time of the survey.
vcqi_global RI_QUAL_09_TO_FOOTNOTE_4  ${OS_171} //The denominator for Had MOSV (%) is the number of respondents who had visits eligible.
vcqi_global RI_QUAL_09_TO_FOOTNOTE_5  ${OS_172} //The denominator for MOSV uncorrected and corrected (%) is the number of MOSVs.  
vcqi_global RI_QUAL_09_TO_FOOTNOTE_6  ${OS_173} //Note that for individual doses, the % MOSV uncorrected + % MOSV corrected adds up to 100%.
if "`=ustrupper("$RI_QUAL_09_VALID_OR_CRUDE")'" == "VALID" vcqi_global RI_QUAL_09_TO_FOOTNOTE_7 ${OS_90} //Note: Early doses are ignored in this analysis; the respondent is considered to have not received them.
if "`=ustrupper("$RI_QUAL_09_VALID_OR_CRUDE")'" == "CRUDE" vcqi_global RI_QUAL_09_TO_FOOTNOTE_7 ${OS_106} //Note: Early doses are accepted in this analysis; all doses are considered valid doses.

* This indicator makes plots (1) if any MOSV and (2) if corrected. These are sorted in opposite directions, so global SORT_PLOT_LOW_TO_HIGH is set inside RI_QUAL_09_06PO.ado rather than here by the user.

RI_QUAL_09

* Estimate the proportion of intervals that are longer
* than the specified thresholds
* 1. Penta1 to Penta2 longer than 76 days (ditto Polio)
* 2. Penta2 to Penta3 longer than 76 days (ditto Polio)

vcqi_global RI_QUAL_12_DOSE_PAIR_LIST PENTA1 PENTA2 PENTA2 PENTA3 POLIO1 POLIO2 POLIO2 POLIO3 
vcqi_global RI_QUAL_12_THRESHOLD_LIST 76 76 76 76 

vcqi_global RI_QUAL_12_TO_TITLE       ${OS_443} //Dose Intervals Exceed Thresholds
vcqi_global RI_QUAL_12_TO_SUBTITLE
vcqi_global RI_QUAL_12_TO_FOOTNOTE_1  ${OS_347} //Note: This measure is an unweighted summary of a proportion from the survey sample. 
vcqi_global SORT_PLOT_LOW_TO_HIGH 0 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_QUAL_12

* ------------------------------------------------------------------------------
* Indicators that plot cumulative coverage curves and cumulative interval curves
* ------------------------------------------------------------------------------

*
* RI_CCC_02 and RI_CIC_02 make WEIGHTED plots
*

* Make Weighted Cumulative Coverage Curve (CCC) Plots
vcqi_global RI_CCC_02_PLOT_TITLE "Jamaica 2022 MICS - Ages 24-35m"
vcqi_global RI_CCC_02_PLOT_LEVELS 1  // List which level(s) you want CCC (1=nation, 2=zone, 3=stratum)
vcqi_global RI_CCC_02_XMAX_INTERVAL 50  // units is age in days...round up to the nearest xmax_interval (default is 50)
vcqi_global RI_CCC_02_GRAPHREGION_COLOR white
vcqi_global RI_CCC_02_NUM_LEGEND_ROWS 2

* If want to over-ride automated x-labels on plot, fill in global here, otherwise leave the global empty
vcqi_global RI_CCC_02_XLABELS 

* If want to change the font size of the xlabels (usually make them smaller so they don't overlap)
* e.g., vsmall, small, or medsmall
vcqi_global RI_CCC_02_XLABEL_SIZE medsmall

* Alternate labels on x-axis? (0=No; 1=Yes)
vcqi_global RI_CCC_02_XLABEL_ALTERNATE	1

* Cumulative coverage curve details 
* The vectors of colors/patterns/widths must be *at least* as long as the number of antigens
vcqi_global RI_CCC_02_COLOR    gs3 red blue gold gs8 purple green magenta sand cyan
vcqi_global RI_CCC_02_PATTERN  solid dash longdash solid solid dash solid dash solid dash
vcqi_global RI_CCC_02_WIDTH    medthin medthin medthin medthin medthin medthin medthin medthin medthin medthin

* Vertical lines denoting vaccination schedule
vcqi_global RI_CCC_02_VLINE_COLOR    gs10
vcqi_global RI_CCC_02_VLINE_PATTERN  longdash
vcqi_global RI_CCC_02_VLINE_WIDTH    medthin

* CCC are made for dates according to card. If register dates were sought, then
*  CCC are also made for dates according to register. If user wants to over-ride 
*  this default, then type the data source (either card or register) user wants
*  CCC plots, otherwise, leave blank. (e.g., if both card and register dates
*  available but user only wants card CCC, then type card here; or if dataset only
*  has register dates, then type register here)
vcqi_global RI_CCC_02_CARD_REGISTER card

* Note that the y-axis goes from 0% to 100% and the denominator for these curves
* is the number of respondents with a card with a birthdate and at least one
* vaccination date. (For register plots, the denominator is the number of 
* respondents with register records with a birthdate and at least one vx date.)
vcqi_global RI_CCC_02_XLABEL_INCLUDE 180 365		

* If card availability or coverage are low, you might not want the y-axis to
* go all the way up to 100.  If you set this ZOOM parameter to 1, the plots
* will go from 0 up to 20%, 40%, 60%, 80%, or 100% - whichever is required
* to show all your data.

vcqi_global RI_CCC_02_ZOOM_Y_AXIS 1	

vcqi_global CCC_XMAX = 720

RI_CCC_02

* Make Weighted Cumulative Interval Curves (CIC)
*
* These locals are very similar to those described above under the CCC curves.

* Note that the y-axis goes from 0% to 100% and the denominator for these curves
* is the number of respondents with a date for dose1 and a date for dose2.
*
* The code automatically makes interval plots for every antigen with doses 
* named with numbers 1+ at the end, e.g., opv1 opv2, etc.  This code IGNORES
* doses with a zero at the end of the name.  That is to say that it does NOT
* generate a plot for the interval between opv0 and opv1, but does generate
* plots for intervals between opv1 and opv2, opv2 and opv3, etc.

vcqi_global RI_CIC_02_XMAX_INTERVAL 10
vcqi_global RI_CIC_02_PLOT_LEVELS 1 
vcqi_global RI_CIC_02_CARD_REGISTER
vcqi_global RI_CIC_02_XLABELS
vcqi_global RI_CIC_02_PLOT_TITLE "Jamaica 2022 MICS - 24-35m"

vcqi_global RI_CIC_02_COLOR    navy
vcqi_global RI_CIC_02_PATTERN  solid
vcqi_global RI_CIC_02_WIDTH    medium

vcqi_global RI_CIC_02_VLINE_COLOR   gs10 gs10
vcqi_global RI_CIC_02_VLINE_PATTERN longdash solid
vcqi_global RI_CIC_02_VLINE_WIDTH   medthin medthin
vcqi_global RI_CIC_02_GRAPHREGION_COLOR white
vcqi_global RI_CIC_02_XLABEL_SIZE	medsmall

* Alternate labels on x-axis? (0=No; 1=Yes)
vcqi_global RI_CIC_02_XLABEL_ALTERNATE	0 

vcqi_global RI_CIC_02_CARD_REGISTER card

vcqi_global RI_CIC_02_ZOOM_Y_AXIS 0

RI_CIC_02

********************************************************************************
* Make Coverage and Timeliness Charts

* Specify 1 or 2 or 3 here to make charts for every level 1, 2 or 3 stratum.
* You may also specify a combination like 1 3
global RI_VCTC_01_LEVELS 1 

* Specify which doses to show in the chart and the order, from bottom to top
* In this example, we group them by scheduled age: birth, 6-week, 10-week, 14-week, 9m
global TIMELY_DOSE_ORDER bcg  polio1 penta1   polio2 penta2   polio3 penta3   mmr1   polio4 dpt4 mmr2

* Specify the y-coordinates for the bars.  If you want them to be spaced evenly, you may omit this global (leave it empty)
* In this example, we use irregular spacing to group the different dose series.
global TIMELY_Y_COORDS    10    20 27             37 44          54 61         71       81 88 95

* Specify the y-coordinates for a set of light reference horizonatal lines between dose groups
* These are just for the purpose of aiding the viewer's eye in grouping doses visually.
* The lines are sometimes skipped if you have already used the TIMELY_Y_COORDS to group the doses.
* To omit these lines altogether, leave this global empty or omit it.
global TIMELY_YLINE_LIST  

* Run the .do file that defines the default parameters.
* VCQI first runs the program that lists default parameter values.
* Then it runs a copy that has any user changes.  You may customize the 
* entries in the .do file itself or you may re-specify them in code 
* below the include statements.

* Include the default parameters 
* (You may want to skip this if you have customized the parameters)
* In many cases one of the four following files will give you what you want.

capture include "${S_VCQI_SOURCE_CODE_FOLDER}/RI/globals_for_timeliness_plots - modified_legend_for_bcg.do"
*capture include "${S_VCQI_SOURCE_CODE_FOLDER}/RI/globals_for_timeliness_plots - modified_legend_for_bcg_and_hepb.do"
*capture include "${S_VCQI_SOURCE_CODE_FOLDER}/RI/globals_for_timeliness_plots - modified_legend_for_bcg_and_hepb0.do"
*capture include "${S_VCQI_SOURCE_CODE_FOLDER}/RI/globals_for_timeliness_plots - same_legend_for_all_doses.do"

* But if not, you can include user-specified parameters, if present
capture include "${VCQI_OUTPUT_FOLDER}/globals_for_timeliness_plots.do"

* If you wish to over-ride default parameters, do it here:

* Do the calculations and make the charts
RI_VCTC_01

vcqi_global ANALYSIS_COUNTER 2

* Estimate proportion of respondents fully vaccinated
vcqi_global RI_DOSES_TO_BE_FULLY_VACCINATED bcg polio1 polio2 polio3 penta1 penta2 penta3 mmr1 mmr2 dpt4 polio4

vcqi_global RI_COVG_03_TO_TITLE       `=ustrtitle("${OS_217}")' - All doses //Fully Vaccinated
vcqi_global RI_COVG_03_TO_SUBTITLE
vcqi_global RI_COVG_03_TO_FOOTNOTE_1  ${OS_337}  //Abbreviations: CI = Confidence Interval; LCB = Lower Confidence Bound; UCB = Upper Confidence Bound; DEFF = Design Effect; ICC = Intracluster Correlation Coefficient
vcqi_global RI_COVG_03_TO_FOOTNOTE_2  ${OS_338} //Note: This measure is a population estimate that incorporates survey weights. The CI, LCB and UCB are calculated with software that takes the complex survey design into account.	
vcqi_global RI_COVG_03_TO_FOOTNOTE_3  ${OS_108} $RI_DOSES_TO_BE_FULLY_VACCINATED //Note: To be fully vaccinated, the child must have received: $RI_DOSES_TO_BE_FULLY_VACCINATED
vcqi_global SORT_PLOT_LOW_TO_HIGH 1 // 1 means show strata w/ low outcomes at bottom and high at top
                                    // 0 is the opposite

RI_COVG_03

********************************************************************************/
* Code Block: RI-G                                               (Do not change)
*-------------------------------------------------------------------------------
*                  Exit gracefully
*-------------------------------------------------------------------------------
*
* Make RI augmented dataset for additional analysis purposes if user requests it.

if "$VCQI_MAKE_AUGMENTED_DATASET"=="1" & "$VCQI_CHECK_INSTEAD_OF_RUN" != "1" make_RI_augmented_dataset_v2

* Close the datasets that hold the results of 
* hypothesis tests, and put them into the output spreadsheet
*
* Close the log file and put it into the output spreadsheet
*
* Clean up extra files
* 
* Send a message to the screen if there are warnings or errors in the log

vcqi_cleanup

********************************************************************************

$VCQI____END_OF_PROGRAM

* Output to the log window is suppressed by the command $VCQI____END_OF_PROGRAM
* (which is an alias for "set output error")

* So this change log in block H will not appear when the user runs VCQI

********************************************************************************
* Code Block: RI-H                                               (Do not change)
*-------------------------------------------------------------------------------
* Change log 
******************************************************************************** 

* turn on normal output to the log window again
set output proc
