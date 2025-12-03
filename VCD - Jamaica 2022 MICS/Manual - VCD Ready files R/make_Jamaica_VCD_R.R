# Jamaica 2022 MICS - VCD in R 

# Notes: 
# - Once you load a package in R - with library(packagename) - all the functions
#   in that package are available to use. As long as a package is *installed* 
#   then the functions can also be accessed using packagename::functionname 
#   syntax. So if I want to use the read_dta function from the haven package, 
#   I could do EITHER: 

#        library(haven)                 # Load the package
#        dat <- read_dta("mydata.dta")  # Use read_dta
#   OR 
#        dat <- haven::read_dta("mydata.dta")  # Call haven::read_dta directly

#   It never hurts to use the verbose reference to a function name, so in this 
#   script I've tried to use packagename::functionname syntax so that you know 
#   which functions come from which packages. 

# - We need various workarounds for creating variables with names created from 
#   components in a loop - R doesn't have a clean alternative to something like 
#   gen `v'_history = 1 if ``v''d == 66

# Packages 
if (!requireNamespace("tidyverse")){install.packages("tidyverse")}

library(dplyr)     # Tidyverse functions for data manipulation 
library(haven)     # Tidyverse package for reading Stata/etc. datasets 
library(stringr)   # Tidyverse package for string manipulation 
library(rlang)     # Tidyverse package - lets us paste together commands/arguments

# Paths 
indir <- "Q:/VCD - Jamaica 2022 MICS/Jamaica MICS6 SPSS Datasets/"
outdir <- "Q:/VCD - Jamaica 2022 MICS/Manual - VCD Ready Files R/"
if (!dir.exists(outdir)){dir.create(outdir)}

setwd(outdir) # Equivalent to cd 

dat <- haven::read_dta(paste0(indir, "ch.dta")) # Equivalent to use input/ch

# Start by removing records of those that did not give consent or complete the
# interview

# Create a new version of the object "dat" by taking the current version of dat,
# then doing some things to that object
dat <- dat |> 
  # Only keep the respondents that gave consent for the interview
  dplyr::filter(uf10 == 1)

# ^ dplyr::filter is the main function to use when translating Stata logic to 
# drop if or keep if. 

# Confirm that everyone finished the survey 
all(dat$uf17 == 1) # Assertion - uf17 == 1
dat <- dat |> filter(uf17 == 1) # Equivalent to drop if uf17 != 1

# Demographic information ----

dat <- dat |> 
  dplyr::mutate(
    # Create a copy of hh7 called RI01 - equivalent to clonevar 
    RI01 = hh7,
    # Create a version of RI01 using labels instead of numeric values (first
    # using a haven function to convert labeled vectors to factor variables,
    # then converting the factor to a string) - equivalent to decode 
    RI02 = haven::as_factor(RI01) |> as.character(),
    # Clean up RI02 strings (str_squish works like trim, str_to_title like proper)
    RI02 = stringr::str_squish(RI02) |> stringr::str_to_title(),
    # Cluster variables: create a copy of hh1 called RI03
    RI03 = hh1
  )

# ^ dplyr::mutate is the main function to use when translating Stata logic for 
# clonevar, gen

# Confirm that the psu variable is equal to the cluster  
all(dat$psu == dat$RI03)

# If available, use value labels from RI03 to create RI04 - otherwise simply add
# the word 'Cluster' in front of the number
if (haven::is.labelled(dat$RI03)){
  dat <- dat |> 
    mutate(RI04 = haven::as_factor(RI03) |> as.character())
} else {
  dat <- dat |> 
    mutate(RI04 = paste0("Cluster ", RI03))
}

# Label RI04 
dat$RI04 <- haven::labelled(dat$RI04, label = "Cluster name")

# Confirm the two variables for child's line number are the same 
all(dat$ln == dat$uf3)

dat <- dat |> 
  mutate(
    RI11 = uf2 |> as.character(),
    RI12 = uf3,
    RI13 = uf4,
    urban_cluster = hh6
  )

# Level datasets ----
dat <- dat |> 
  mutate(level1id = 1,
         level1name = "Jamaica",
         # Level2 - Since we do not have any other demographic levels we will
         # set this to the level1 information
         level2id = level1id, 
         level2name = level1name,
         # Level3 - this is typically the same information used in RI01 & RI02
         level3id = RI01,
         level3name = RI02)

dat$level1id <- haven::labelled(dat$level1id, label = "Country")
dat$level1name <- haven::labelled(dat$level1name, label = "Country")

# Interview information ----

# There are two variables with interviewer number, confirm they hold the same
# values 
all(dat$ufint == dat$uf5)

# There are two variables with supervisor number, confirm they hold the same
# values
all(dat$uf6 == dat$hh4)

dat <- dat |> 
  mutate(
    RI05 = uf5,
    RI07 = uf6,
    
    # Interview date variables
    RI09_m = uf7m,
    RI09_d = uf7d,
    RI09_y = uf7y,
    
    # Create start time variable
    RI10 = format(
      strptime(paste(uf8h, uf8m, "00", sep = ":"), format = "%H:%M:%S"), 
      format = "%H:%M:%S"),
    
    RI143 = format(
      strptime(paste(uf11h, uf11m, "00", sep = ":"), format = "%H:%M:%S"), 
      format = "%H:%M:%S")
  )


dat$RI10 <- haven::labelled(dat$RI10, label = "Start time of interview")
dat$RI143 <- haven::labelled(dat$RI143, label = "End time of interview")

# Child information ----

dat <- dat |> 
  mutate(
    # Child's sex
    RI20 = hl4,
    
    # Child's DOB per mother's recall 
    dob_date_history_m = ub1m,
    dob_date_history_d = ub1d,
    dob_date_history_y = ub1y,
    
    # There is one date of birth day that has an invalid day component. 
    # We will wipe that out
    dob_date_history_d = ifelse(ub1d == 98, NA, dob_date_history_d),
    
    # Child's age in years
    RI24 = ub2,
    
    # Child's age in months
    RI25 = cage
  )

# Card information ----

temp_mdy <- c("m", "d", "y")
temp_mdy_word <- c("month", "day", "year")
for(c in seq_along(temp_mdy)){
  dat$tempvar <- haven::labelled(
    NA_integer_, label = "Empty variable - created for VCQI")
  dat <- dat |> rename_with(~paste0("dob_date_card_", temp_mdy[c]), tempvar)
}

dat <- dat |> 
  mutate(
    RI26 = im3, # Ever received card
    RI26 = case_when(
      im2 %in% c(1, 2, 3) ~ 1, # has vx card for child - 1, 2 & 3 = yes
      im5 %in% c(1, 2, 3) ~ 1, # vx card seen for child - 1, 2 & 3 = yes
      (im2 %in% 4 | im5 %in% 4) & RI26 != 1 ~ 2, # has no card from either source
      RI26 %in% 9 ~ 99, # replace DNK code 
      TRUE ~ RI26 # retain original value if none of the above conditions met 
    ),
    RI26 = ifelse(!RI26 %in% c(1, 2, 99), NA, RI26)
  )

dat$RI26 <- haven::labelled(
  dat$RI26, labels = c(Yes = 1, No = 2, "Don't know" = 99))

dat <- dat |> 
  mutate(
    RI27 = im5,
    RI27 = ifelse(im5 %in% c(1, 2, 3), 1, RI27),
    RI27 = ifelse(im5 %in% 4, 2, RI27),
    RI27 = ifelse(im2 %in% 4 & !RI27 %in% 1, 2, RI27),
    RI27 = ifelse(!RI26 %in% 1, NA, RI27)
  )

dat$RI27 <- haven::labelled(
  dat$RI27, labels = c("Yes, card seen" = 1, "No, card not seen" = 2))

# Dose information ----

RI_LIST <- data.frame(
  dose = c("bcg", "polio1", "polio2", "polio3", "penta1", "penta2", "penta3",
             "mmr1", "mmr2", "dpt4", "polio4") |> stringr::str_to_lower()
) |> 
  mutate(
    # Set up column with variable base for card information for each dose
    var = case_when(
      dose %in% "bcg" ~ "im6b",
      dose %in% "polio1" ~ "im6p1",
      dose %in% "polio2" ~ "im6p2",
      dose %in% "polio3" ~ "im6p3",
      dose %in% "polio4" ~ "im6i",
      dose %in% "penta1" ~ "im6penta1",
      dose %in% "penta2" ~ "im6penta2",
      dose %in% "penta3" ~ "im6penta3",
      dose %in% "dpt4" ~ "im6td1",
      dose %in% "mmr1" ~	"im6m1",
      dose %in% "mmr2" ~ "im6m2"
    )
  )

history_labels <- c("Yes" = 1, "No" = 2, "Don't know" = 99)
tick_labels <- c("Yes, tick mark on card" = 1, "No" = 0)

order_list <- NULL
for(i in 1:nrow(RI_LIST)){
  v <- RI_LIST$dose[i]
  uv <- stringr::str_to_upper(v)
  dv <- paste0(RI_LIST$var[i], "d")
  
  dat <- dat |> mutate(
    # copy of original dose day variable 
    temp0 = get(dv, dat),
    # tick variable with temporary name
    temp1 = ifelse(temp0 %in% 44, 1, NA_integer_),
    # history variable with temporary name 
    temp2 = ifelse(temp0 %in% 66, 1, NA_integer_),
    temp2 = ifelse(temp0 %in% 0 & !temp2 %in% 1, 2, temp2)
  )
  
  # Add variable and value labels - tick 
  dat$temp1 <- haven::labelled(
    dat$temp1, label = paste0(uv, " - received via tick mark on card"),
    labels = tick_labels)
  
  # Add variable and value labels - history 
  dat$temp2 <- haven::labelled(
    dat$temp2, label = paste0(uv, " - received via recall"),
    labels = history_labels)
  
  # Rename variables with placeholder names 
  dat <- dat |> 
    # Rename tick variable 
    rename_with(~paste0(v, "_tick_card"), temp1) |> 
    # Rename history variable 
    rename_with(~paste0(v, "_history"), temp2) |> 
    # Drop the temp0 variable 
    select(-temp0)
  
  for(c in seq_along(temp_mdy)){
    cv <- paste0(RI_LIST$var[i], temp_mdy[c])
    dat <- dat |> mutate(temp3 = get(cv, dat)) 
    
    if (temp_mdy[c] != "d"){
      test <- all(!dat$temp3 %in% c(0, 44, 66))
      if (test %in% FALSE){
        stop(paste0("Invalid values in ", uv, " ", 
                    temp_mdy_word[c], " (", cv , ")"))}
    } else {
      dat <- dat |> mutate(temp3 = ifelse(temp3 %in% c(0, 44, 66), NA, temp3))
    }
    
    dat <- dat |>
      rename_with(~paste0(v, "_date_card_", temp_mdy[c]), temp3)
  
  } # end mdy loop 
  
  order_list <- c(
    order_list, 
    paste0(v, "_date_card_m"), 
    paste0(v, "_date_card_d"), 
    paste0(v, "_date_card_y"),
    paste0(v, "_tick_card"),
    paste0(v, "_history")
  )
  
  # Confirm that the date values are valid 
  temp_check_m <- get(paste0(v, "_date_card_m"), dat)
  temp_check_m <- temp_check_m[!is.na(temp_check_m)]
  testval <- all(temp_check_m <= 12)
  message(paste0("All ", uv, " month values valid: ", testval))
  
  temp_check_d <- get(paste0(v, "_date_card_d"), dat)
  temp_check_d <- temp_check_d[!is.na(temp_check_d)]
  testval <- all(temp_check_d >= 1) & all(temp_check_d <= 31)
  message(paste0("All ", uv, " day values valid: ", testval))
  
  temp_check_y <- get(paste0(v, "_date_card_y"), dat)
  temp_check_y <- temp_check_y[!is.na(temp_check_y)]
  testval <- all(temp_check_y >= 2019) & all(temp_check_y <= 2025)
  message(paste0("All ", uv, " year values valid: ", testval))
  
} # end RI_LIST i loop 

# Dose recall information ----

dat <- dat |> 
  # Replace history variables based on original recall variables 
  mutate(
    # BCG 
    bcg_history = ifelse(is.na(bcg_history), im14, bcg_history),
    bcg_history = ifelse(im14 %in% 1, im14, bcg_history),
    bcg_scar_history = NA_integer_,
    # DPT booster
    dpt4_history = ifelse(im27a %in% 1, 1, dpt4_history),
    dpt4_history = ifelse(im27a %in% 2 & !dpt4_history %in% 1, 2, dpt4_history),
    dpt4_history = ifelse(im27a %in% 8 & !dpt4_history %in% 1, 99, dpt4_history),
    dpt4_history = ifelse(im27a %in% 9 & !dpt4_history %in% 1, NA, dpt4_history)
  )

dat$bcg_scar_history <- haven::labelled(
  dat$bcg_scar_history, label = "Empty variable - created for VCQI")

## Measles or MMR or MR ----
dat <- dat |> 
  mutate(num_mmr = ifelse(im26a < 8, im26a, 0))

for(i in 1:2){
  dose_var <- rlang::sym(paste0("mmr", i, "_history"))
  dat <- dat |> 
    mutate(
      !!dose_var := ifelse(im26 %in% 1 & num_mmr >= i, 1, !!dose_var),
      !!dose_var := ifelse(im26 %in% 1 & num_mmr < i & 
                            !(!!dose_var %in% 1), 2, !!dose_var),
      !!dose_var := ifelse(im26 %in% 2 & !(!!dose_var %in% 1), 2, !!dose_var),
      !!dose_var := ifelse(im26 %in% 8 & !(!!dose_var %in% 1), 99, !!dose_var),
      !!dose_var := ifelse(im26 %in% 9 & !(!!dose_var %in% 1), NA, !!dose_var)
    )
}

# If they say they got the dose but don't know how many doses they received
# (im26a == 8), give credit for the first dose
dat <- dat |> mutate(mmr1_history = ifelse(im26 %in% 1, 1, mmr1_history))

## Penta doses 1-3 ----
dat <- dat |> 
  mutate(num_penta = ifelse(im21 < 8, im21, 0))

for(i in 1:3){
  dose_var <- rlang::sym(paste0("penta", i, "_history"))
  dat <- dat |> 
    mutate(
      !!dose_var := ifelse(im20 %in% 1 & num_penta >= i, 1, !!dose_var),
      !!dose_var := ifelse(im20 %in% 1 & num_penta < i & 
                            !(!!dose_var %in% 1), 2, !!dose_var),
      !!dose_var := ifelse(im20 %in% 2 & !(!!dose_var %in% 1), 2, !!dose_var),
      !!dose_var := ifelse(im20 %in% 8 & !(!!dose_var %in% 1), 99, !!dose_var),
      !!dose_var := ifelse(im20 %in% 9 & !(!!dose_var %in% 1), NA, !!dose_var)
    )
}

# If they say they got the dose but don't know how many doses they received,
# give credit for the first dose
dat <- dat |> mutate(penta1_history = ifelse(im20 %in% 1, 1, penta1_history))

## Polio ----

# The way that recall for polio is used per the questionnaire & report is unique
# Polio1 - will ONLY use the IPV recall information
# Polio2-4 will use either IPV or OPV

dat <- dat |> 
  mutate(
    polio1_history = ifelse(im19a %in% 1, 1, polio1_history),
    polio1_history = ifelse(im19a %in% 2 & !polio1_history %in% 1, 2, polio1_history),
    polio1_history = ifelse(im19a %in% 8 & !polio1_history %in% 1, 99, polio1_history),
    polio1_history = ifelse(im19a %in% 9 & !polio1_history %in% 1, NA, polio1_history)
  )

dat <- dat |> 
  mutate(
    num_polio = ifelse((!is.na(im19b) & im19b < 8), im19b, 0)) |> 
  rowwise() |> 
  mutate(num_polio = ifelse((!is.na(im18) & im18 < 8), num_polio + im18, num_polio)) |> ungroup()

for(i in 2:4){

  dose_var <- rlang::sym(paste0("polio", i, "_history"))
  dat <- dat |> 
    mutate(
      !!dose_var := ifelse(num_polio >= i, 1, !!dose_var),
      !!dose_var := ifelse(im19a %in% 1 & num_polio < i & 
                             !(!!dose_var %in% 1), 2, !!dose_var),
      !!dose_var := ifelse(im19a %in% 2 & !(!!dose_var %in% 1), 2, !!dose_var),
      !!dose_var := ifelse(im19a %in% 8 & !(!!dose_var %in% 1), 99, !!dose_var),
      !!dose_var := ifelse(im19a %in% 9 & !(!!dose_var %in% 1), NA, !!dose_var)
    )
}

# Replace all history values to 2 if they have the value of 8 (Do not know)
histvars <- names(select(dat, ends_with("_history")))
for(v in seq_along(histvars)){
  tempvar <- rlang::sym(histvars[v])
  testval <- all(get(tempvar, dat) %in% c(1, 2, 99, NA))
  message(paste0("All ", histvars[v], " values valid: ", testval))
}

# Additional information ----

RI_ADDITIONAL_VARS <- c(
  # Stratifiers 
  "hh6", "melevel", "ethnicity", "religion", "windex5",
  # Child's weight 
  "chweight",
  # Polio history variables 
  "im19b", "im19a", "im18", "im16",
  # Card availability variables 
  "im2", "im3", "im5",
  # Language of questionnaire and interview 
  "uf12", "uf13"
)

# Save datasets ----

# Save an overall dataset 
dat <- dat |> 
  arrange(RI01, RI02, RI03, RI04, RI11, RI12, RI09_m, RI09_d, RI09_y, chweight)

saveRDS(dat, "Full_dataset.rds")

# Save the RI datasets ----
dat_ri <- dat |> 
  select(
    starts_with("RI"),
    contains("date"), contains("history"), contains("tick"),
    all_of(RI_ADDITIONAL_VARS)
  ) |> 
  relocate(RI143, .after = RI27) |> 
  relocate(
    all_of(c("dob_date_history_m", "dob_date_history_d", "dob_date_history_y",
             "dob_date_card_m", "dob_date_card_d", "dob_date_card_y", order_list)),
           .after = RI27
  ) |> 
  relocate(bcg_scar_history, .after = bcg_history) |> relocate(chweight)

saveRDS(dat_ri, "RI_dataset.rds")

dat_12_23 <- dat_ri |> filter(RI25 >= 12 & RI25 <= 23)
saveRDS(dat_12_23, "RI_12_to_23m_dataset.rds")

dat_24_35 <- dat_ri |> filter(RI25 >= 24 & RI25 <= 35)
saveRDS(dat_24_35, "RI_24_to_35m_dataset.rds")

# CM dataset ----

hh <- haven::read_dta(paste0(indir, "hh.dta")) |> select(hh1, hh2, hh6, hh7, hh12)
cm <- full_join(dat, hh) |> 
  rename(HH01 = hh7,
         HH02 = RI02,
         HH03 = hh1,
         HH04 = RI04,
         HH14 = hh2) |> 
  mutate(province_id = level2id) 

if (!all(!is.na(cm$province_id))){
  cm <- cm |> 
    arrange(HH01, HH03, province_id) |> 
    group_by(HH01, HH03) |> 
    mutate(province_id = first(province_id)) |> 
    ungroup()
}

cm <- cm |> 
  mutate(psweight_1year = chweight) |> 
  group_by(HH03, HH14) |> 
  mutate(firsthm = row_number() == 1) |> ungroup() |> 
  group_by(HH03) |> 
  mutate(expected_hh_to_visit = sum(firsthm)) |> 
  ungroup() |> select(-firsthm)


cm$expected_hh_to_visit <- haven::labelled(
  cm$expected_hh_to_visit, 
  label = "Number of HH survey team expects to visit in cluster (or cluster segment)")

cm <- cm |> 
  # Drop if they did not give consent
  filter(!uf10 %in% 2,
         !hh12 %in% 2) |> 
  # Keep CM variables
  select(HH01, HH02, HH03, HH04, province_id, urban_cluster,
         starts_with("psweight")) |> 
  filter(!is.na(psweight_1year)) |> 
  # Keep one row per stratum-cluster combo 
  unique()

# Confirm there is only one weight per cluster
test <- cm |> group_by(HH01, HH03) |> summarize(n = n())
max(test$n) == 1

# The weight can be missing for some observations; replace the weight with the
# maximum non-missing weight in each cluster
cm <- cm |> group_by(HH01, HH03) |> 
  mutate(psweight_1year = max(psweight_1year, na.rm = TRUE)) |> ungroup()

cm <- cm |> group_by(HH01, HH03) |> slice(1) |> ungroup()

cm <- cm |> select(starts_with("HH"), everything()) |> 
  arrange(HH01, HH03, province_id, urban_cluster, psweight_1year)

saveRDS(cm, "CM_dataset.rds")

# Level 1-3 datasets 

for(i in 1:3){
  
  idvar <- rlang::sym(paste0("level", i, "id"))
  ordervar <- rlang::sym(paste0("level", i, "order"))
  
  temp <- dat |> select(starts_with(paste0("level", i))) |> 
    select(contains("id"), everything()) |> 
    unique() |> 
    mutate(
      !!idvar := haven::zap_label(!!idvar),
      !!ordervar := !!idvar
    )
  
  if (i == 1){
    saveRDS(temp, paste0("level", i, "name.rds"))
    
    temp <- temp |> mutate(level1name = "Jamaica - Ages 12-23m")
    saveRDS(temp, "level1name_12_to_23m.rds")
    
    temp <- temp |> mutate(level1name = "Jamaica - Ages 24-35m")
    saveRDS(temp, "level1name_24_to_35m.rds")
    
    
  } else {
    saveRDS(temp, paste0("level", i, "names.rds"))
    saveRDS(temp, paste0("level", i, "order.rds"))
  }
  
}


