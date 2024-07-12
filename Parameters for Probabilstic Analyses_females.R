##############################################
            ## FEMALE SUBGROUP ##
##############################################

##############################################
        ## Number SARS-CoV-2 cases ##
        ## By provinvce ## 
##############################################
COVID_cases_BC = 502674
COVID_cases_BC_SE = 28003

COVID_cases_AB = 468568
COVID_cases_AB_SE = 26965

COVID_cases_MB = 119948
COVID_cases_MB_SE = 7627

COVID_cases_SK = 110284
COVID_cases_SK_SE = 6883

COVID_cases_ON = 1446879
COVID_cases_ON_SE = 63530

COVID_cases_QC = 899530
COVID_cases_QC_SE = 34726

COVID_cases_ATL = 204166
COVID_cases_ATL_SE = 7585

###################################################
## Proportion that reported PCC-related symptoms ##
###################################################
prevalence_PCC = 0.221
prevalence_PCC_SE = 0.012

###################################################
    ## Monthly emergency department rate per case ##
###################################################
pro_ED_L_bound = c(0.019, 0.029, 0.038, 0.057)
pro_ED_L_mode = c(0.026, 0.038, 0.051, 0.077)  
pro_ED_U_mode = c(0.038, 0.057, 0.077, 0.115) 
pro_ED_U_bound = c(0.045, 0.067, 0.089, 0.134)

###################################################
    ## Monthly inpatient hospitalization rate per case ##
###################################################
pro_Inpatient_L_bound = c(0.005, 0.008, 0.01, 0.015)  
pro_Inpatient_L_mode = c(0.007, 0.01, 0.014, 0.02)  
pro_Inpatient_U_mode = c(0.01, 0.015, 0.02, 0.031)
pro_Inpatient_U_bound = c(0.012, 0.018, 0.024, 0.036) 

###################################################
            ## Mean GP visits per case ##
###################################################
pro_Physician = 1
pro_Physician_SE = 0.00000001

nPhysician_L_bound = 0 
nPhysician_L_mode = 2
nPhysician_U_mode = 3 
nPhysician_U_bound = 15

###################################################
## Proportion that had an outpatient specialist  ##
###################################################
pro_Specialist = 1
pro_Specialist_SE = 0.00000001

###################################################
 ## Mean outpatient specialist visits per case ##
###################################################
nSpecialist_L_bound = 0
nSpecialist_U_bound = 2

###################################################
 ## Proportion that left work permanently ##
###################################################
pro_left_work_L_bound = 0.01 
pro_left_work_L_mode = 0.03 
pro_left_work_U_mode = 0.05
pro_left_work_U_bound = 0.13

###################################################
## Mean months with permanent employment loss ##
###################################################
pro_left_work_fu = 276
pro_left_work_fu_SE = 15

# pro_left_work_fu_L_bound = 4 
# pro_left_work_fu_L_mode = 6 
# pro_left_work_fu_U_mode = 10 
# pro_left_work_fu_U_bound = 16

#########################################################################
## Proportion of full-time equivalent work lost due to PCC symptoms, µ ##
#########################################################################
pro_loss_fte_L_bound = 0.00
pro_loss_fte_L_mode  = 0.05
pro_loss_fte_U_mode  = 0.10
pro_loss_fte_U_bound = 0.25

############################################################
## Proportion that missed at least one school or work day ##
############################################################
pro_loss = 0.754
pro_loss_SE = 0.028

###################################################
## Mean missed school or work days per case ##
###################################################
days_missed = 17.013
days_missed_SE = 3.071

###################################################
 ## National daily average income in 2021, £ ##
###################################################
income_dict_females <- list(
  "$0 to $4,999" = list(range = c(0, 4999), prob = 0.050),
  "$5,000 to $9999" = list(range = c(5000, 9999), prob = 0.046),
  "$10,000 to $14999" = list(range = c(10000, 14999), prob = 0.066),
  "$15,000 to $19999" = list(range = c(15000, 19999), prob = 0.071),
  "$20,000 to $24999" = list(range = c(20000, 24999), prob = 0.098),
  "$25,000 to $34999" = list(range = c(25000, 34999), prob = 0.144),
  "$35,000 to $49999" = list(range = c(35000, 49999), prob = 0.176),
  "$50,000 to $74999" = list(range = c(50000, 74999), prob = 0.180),
  "$75,000 to $99999" = list(range = c(75000, 99999), prob = 0.087),
  "$100,000 to $149999" = list(range = c(100000, 149999), prob = 0.058),
  "$150,000 to $199999" = list(range = c(150000, 199999), prob = 0.013),
  "$200,000 to $249999" = list(range = c(200000, 249999), prob = 0.005),
  "$250,000 to $1000000" = list(range = c(250000, 1000000), prob = 0.006)
)

# Set a base seed for reproducibility
set.seed(14424)
income_means <- replicate(1000, generate_income(n_samples = 100, income_dict = income_dict_females))
income_mean=mean(income_means)
income_SE=sd(income_means) / sqrt(length(income_means))

##############################################
## Inflation factor to convert the costs    ## 
## from 2021 to 2023 Canadian dollars.      ##
## https://www150.statcan.gc.ca/n1/daily-quotidien/240116/dq240116b-eng.htm
##############################################
inflation_factor = 1.0995

###################################################
    ## Cost of Emergency department visit ##
###################################################
c_PCC_ED_L_bound = 300 
c_PCC_ED_L_mode = 450 
c_PCC_ED_U_mode = 550 
c_PCC_ED_U_bound = 750 

##############################################
    ## Cost of Inpatient hospital visit ##
##############################################
c_PCC_Inpatient_L_bound = 5000 
c_PCC_Inpatient_L_mode = 5000 
c_PCC_Inpatient_U_mode = 7500 
c_PCC_Inpatient_U_bound = 50000 

##############################################
## Cost of General practitioner visit ##
##############################################
c_PCC_Physician_L_bound = 44 
c_PCC_Physician_U_bound = 64 

##############################################
        ## Cost of Specialist visit ##
##############################################
c_PCC_Specialist_L_bound = 70 
c_PCC_Specialist_U_bound = 90 