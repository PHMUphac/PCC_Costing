# set path of the parent directory of the current working directory
rm(list=ls()); cat("\014") 
path = dirname(rstudioapi::getSourceEditorContext()$path) 
setwd(dirname(rstudioapi::getSourceEditorContext()$path)) 

subgroups = c(".R", "_males.R", "_females.R", "_0 vaccine doses.R", "_2+ vaccine doses.R")

source (file = file.path(path, "Load Required Packages.R"))

## Please put the path to the output folder of the current working directory.
output_path <- "MY OUTPUT PATH"

assumptions =c(1,2,3,4)
start_time2 <- system.time({ 
  for (asmp in assumptions) {
  # Redirect all outputs to a text file saved in the working directory 
  sink(paste0("output - ",asmp,".txt"))
  
  
  for (group in subgroups) {
    cat("ED and Hosp Assumption #: ", asmp)
    cat("\nStarted Group: ", substr(group, 2, nchar(group) - 2))
    # Import required scripts and load needed libraries
    source (file = file.path(path, paste0("Parameters for Probabilstic Analyses", group)))
    
    Provinces = c("British Columbia", "Alberta", "Manitoba", "Saskatchewan", "Ontario", "Quebec", "Atlantic Provinces")
    Provinces_covid_cases= c(COVID_cases_BC, COVID_cases_AB, COVID_cases_MB, COVID_cases_SK, 
                             COVID_cases_ON, COVID_cases_QC, COVID_cases_ATL)
    Provinces_covid_cases_se= c(COVID_cases_BC_SE, COVID_cases_AB_SE, COVID_cases_MB_SE, COVID_cases_SK_SE, 
                                COVID_cases_ON_SE, COVID_cases_QC_SE, COVID_cases_ATL_SE)
    
    ## The model parameters were loaded in the import statements above 
    National=list()
    base_seed = 14424  # Choose a fixed base seed to maintain reproducibility
    for (j in seq_along(1:10000)) {
      set.seed(base_seed + j)
        
      for (i in seq_along(Provinces)) {
        Province = Provinces[i] # Province of interest
        Province_covid_cases = rnorm(1, mean = Provinces_covid_cases[i], sd = Provinces_covid_cases_se[i]) # Number of COVID Cases detected in the respective province
        Province_prevalence_PCC = rnorm(1, mean = prevalence_PCC, sd = prevalence_PCC_SE) ## Prevalence of PCC (national)
        pro_ED_r =  rtrapezoid(n = 1, min = pro_ED_L_bound[asmp], mode1 = pro_ED_L_mode[asmp], mode2 = pro_ED_U_mode[asmp], max = pro_ED_U_bound[asmp]) ## Rate of ED visits per person over 29 months
        c_PCC_ED_r = rtrapezoid(n = 1, min = c_PCC_ED_L_bound, mode1 = c_PCC_ED_L_mode, mode2 = c_PCC_ED_U_mode, max = c_PCC_ED_U_bound) ## Average Cost ED visits
        pro_Inpatient_r = rtrapezoid(n = 1, min = pro_Inpatient_L_bound[asmp], mode1 = pro_Inpatient_L_mode[asmp], mode2 = pro_Inpatient_U_mode[asmp], max = pro_Inpatient_U_bound[asmp]) ## Rate of inpatient hospitalizations per person over 29 months
        c_PCC_Inpatient_r = rtrapezoid(n = 1, min = c_PCC_Inpatient_L_bound, mode1 = c_PCC_Inpatient_L_mode, mode2 = c_PCC_Inpatient_U_mode, max = c_PCC_Inpatient_U_bound) ## Average cost of  hospitalizations
        pro_Physician_r = 1 # proportion that needed or visited GP
        nPhysician_r  = rtrapezoid(n = 1, min = nPhysician_L_bound, mode1 = nPhysician_L_mode, mode2 = nPhysician_U_mode, max = nPhysician_U_bound) # Average number of visits per person over 29 months
        c_PCC_Physician_r = generate_uniform(c_PCC_Physician_L_bound, c_PCC_Physician_U_bound, n_samples =1) # Average cost of GP visits, Main analysis
        pro_Specialist_r = rnorm(1, mean = pro_Specialist, sd = pro_Specialist_SE) # proportion that needed or visited a specialist
        nSpecialist_r = runif(1, min = nSpecialist_L_bound, max = nSpecialist_U_bound) # Average number of visits per person over 29 months
        c_PCC_Specialist_r = generate_uniform(c_PCC_Specialist_L_bound, c_PCC_Specialist_U_bound, n_samples =1) # Average cost of specialist visits, Main analysis
        pro_loss_r = rnorm(1, mean = pro_loss, sd = pro_loss_SE) ## Proportion that missed school or work due to PCC symptoms ##
        days_missed_r = rnorm(1, mean = days_missed, sd = days_missed_SE) ## Average days of missed school or work due to PCC symptoms ##
        n_samples = as.integer(Province_covid_cases*Province_prevalence_PCC)
         
        ## National average annual income in 2021
        ## Average and median gender pay ratio in annual wages, salaries and commissions
        ## Source: https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1410032401
        c_annual_income_r <- rnorm(1, mean = income_mean, sd = income_SE)
        
        c_daily_income_r =  c_annual_income_r/260 ## Note, we are assuming each calendar year has 260 work days
        c_PCC_loss_r = days_missed_r * c_daily_income_r
        pro_left_work_r = rtrapezoid(n = 1, min = pro_left_work_L_bound, mode1 = pro_left_work_L_mode, mode2 = pro_left_work_U_mode, max = pro_left_work_U_bound)
        pro_left_work_fu_r = rnorm(1, mean = pro_left_work_fu, sd = pro_left_work_fu_SE)
        pcc_fu_months_r = pro_left_work_fu_r/30 ## assuming 30 days per month
        pro_loss_fte_r = runif(1, min = pro_loss_fte_L_bound, max = pro_loss_fte_U_bound)
        
        Province_PCC_case = round(Province_covid_cases * Province_prevalence_PCC)
        Province_ED_visits = round(Province_PCC_case * pro_ED_r * pcc_fu_months_r * c_PCC_ED_r * inflation_factor)
        Province_Inpatient_stays = round(Province_PCC_case * pro_Inpatient_r * pcc_fu_months_r * c_PCC_Inpatient_r * inflation_factor)
        Province_Outpatient_GP_visits = round(Province_PCC_case * pro_Physician_r * nPhysician_r * c_PCC_Physician_r * inflation_factor)
        Province_Specialist_visits = round((Province_PCC_case * pro_Specialist_r * nSpecialist_r) * c_PCC_Specialist_r * inflation_factor)
        Province_Missed_SchoolWork = round(Province_PCC_case * pro_loss_r * c_PCC_loss_r * inflation_factor + 
                                                        Province_PCC_case * pro_left_work_r * (pcc_fu_months_r/12) * c_annual_income_r * inflation_factor)
        Province_Productivity_Loss = round(Province_PCC_case * (1-pro_left_work_r) * pro_loss_fte_r * c_annual_income_r * inflation_factor) 
        Province_Total = Province_ED_visits + Province_Inpatient_stays + Province_Outpatient_GP_visits + 
                                 Province_Specialist_visits + Province_Missed_SchoolWork + Province_Productivity_Loss
        
        # Define list_1 with all the computed variables
        Province_result <- list(
          Iteration = j,
          Province = Province,
          Province_PCC_case = Province_PCC_case,
          Province_ED_visits = Province_ED_visits,
          Province_Inpatient_stays = Province_Inpatient_stays,
          Province_Outpatient_GP_visits = Province_Outpatient_GP_visits,
          Province_Specialist_visits = Province_Specialist_visits,
          Province_Missed_SchoolWork = Province_Missed_SchoolWork,
          Province_Productivity_Loss = Province_Productivity_Loss,
          Province_Total = Province_Total
        )
        
        # Append list_1 to list_2
        National <- append(National, list(Province_result))
        
      }
    }
    
    Provincial_df <- bind_rows(National)
    National_df <- Provincial_df %>%
      group_by(Iteration) %>%
      summarise(
        National_PCC_case = sum(Province_PCC_case, na.rm = TRUE),
        National_ED_visits = sum(Province_ED_visits, na.rm = TRUE),
        National_Inpatient_stays = sum(Province_Inpatient_stays, na.rm = TRUE),
        National_Outpatient_GP_visits = sum(Province_Outpatient_GP_visits, na.rm = TRUE),
        National_Specialist_visits = sum(Province_Specialist_visits, na.rm = TRUE),
        National_Missed_SchoolWork = sum(Province_Missed_SchoolWork, na.rm = TRUE),
        National_Productivity_Loss = sum(Province_Productivity_Loss, na.rm = TRUE),
        National_Total = sum(Province_Total, na.rm = TRUE)
      )
    
    National_df$Cost_Healthcare=National_df$National_ED_visits + National_df$National_Inpatient_stays + National_df$National_Outpatient_GP_visits + National_df$National_Specialist_visits
    National_df$Cost_Labour=National_df$National_Missed_SchoolWork + National_df$National_Productivity_Loss
    National_df$Cost_Total=National_df$Cost_Labour + National_df$Cost_Healthcare
    National_df$Individual_Healthcare=National_df$Cost_Healthcare / National_df$National_PCC_case
    National_df$Individual_Labour= National_df$Cost_Labour / National_df$National_PCC_case
    National_df$Individual_Total= (National_df$Cost_Healthcare + National_df$Cost_Labour) / National_df$National_PCC_case
    
    extracted_string <- substr(group, 2, nchar(group) - 2)
    
    ## Define the full path and save CSV file
    full_csv_path_P <- file.path(output_path, paste0("PCC Provincial Level Costs - 10,000 iterations - ",extracted_string," - Assumption ", asmp,".csv"))
    write.csv(Provincial_df, full_csv_path_P, row.names = FALSE)
    
    full_csv_path_N <- file.path(output_path, paste0("PCC National Level Costs - ",extracted_string," - Assumption ", asmp,".csv"))
    write.csv(National_df, full_csv_path_N, row.names = FALSE)
    
    results_national2 <- bind_rows(
      calculate_stats(National_df$Cost_Healthcare, "Healthcare costs"),
      calculate_stats(National_df$Cost_Labour, "Labour Costs"),
      calculate_stats(National_df$Individual_Healthcare, "Individual Healthcare Costs"),
      calculate_stats(National_df$Individual_Labour, "Individual Labour Costs"),
      calculate_stats(National_df$Individual_Total, "Individual Total Costs"),
      calculate_stats(National_df$National_Total, "Total Costs")
    )
    
    one_billion=1000000000
    decimal_places=2
    
    cat("\n",
        "Analysis Group: ", group, "\n", 
        "Group Size: ", round(mean(National_df$National_PCC_case),0),"\n", 
        "Healthcare Costs: ", round(results_national2$mean[1]/one_billion,decimal_places), 
        " (95% SI: ", round(results_national2$percentile_2_5[1]/one_billion,decimal_places), ", ", 
        round(results_national2$percentile_97_5[1]/one_billion, decimal_places),")",
        
        "\nLabour Costs: ", round(results_national2$mean[2]/one_billion, decimal_places), 
        " (95% SI: ", round(results_national2$percentile_2_5[2]/one_billion, decimal_places), ", ", 
        round(results_national2$percentile_97_5[2]/one_billion, decimal_places),")",
        
        "\nTotal Costs: ", round(results_national2$mean[6]/one_billion, decimal_places), 
        " (95% SI: ", round(results_national2$percentile_2_5[6]/one_billion, decimal_places), ", ", 
        round(results_national2$percentile_97_5[6]/one_billion, decimal_places),")",
        
        "\nIndividual Healthcare Costs: ", round(results_national2$mean[3],0), 
        " (95% SI: ", round(results_national2$percentile_2_5[3],0), ", ", 
        round(results_national2$percentile_97_5[3],0),")",
        
        "\nIndividual Labour Costs: ", round(results_national2$mean[4],0), 
        " (95% SI: ", round(results_national2$percentile_2_5[4],0), ", ", 
        round(results_national2$percentile_97_5[4],0),")",
        
        "\nIndividual Total Costs: ", round(results_national2$mean[5],0), 
        " (95% SI: ", round(results_national2$percentile_2_5[5],0), ", ", 
        round(results_national2$percentile_97_5[5],0),")","\n\n",
        "Ended Group: ", substr(group, 2, nchar(group) - 2), "\n\n",
        
        sep="")
    
    if (group==".R") {
      ##################################################
      ##################################################
      ## Only run the provincial summary below for the 
      ## primary analysis.
      ##################################################
      ##################################################
      # Mean, 2.5th, and 97.5th percentile of the variable "National_PCC_case"
      # Apply the function to each variable and bind the rows
      results_national <- bind_rows(
        calculate_stats(National_df$National_PCC_case, "PCC Cases"),
        calculate_stats(National_df$National_ED_visits, "ED Visits"),
        calculate_stats(National_df$National_Inpatient_stays, "Inpatient Hospitalizations"),
        calculate_stats(National_df$National_Outpatient_GP_visits, "Outpatient GP Visits"),
        calculate_stats(National_df$National_Specialist_visits, "National Specialist Visits"),
        calculate_stats(National_df$National_Missed_SchoolWork, "National Missed School/Work"),
        calculate_stats(National_df$National_Productivity_Loss, "National Productivity Loss"),
        calculate_stats(National_df$National_Total, "National Total"))
        
        cat("\n",
            "Analysis Group: ", group, "\n", 
            "Group Size: ", round(mean(National_df$National_PCC_case),0),"\n", 
            "Healthcare Costs: ", round(results_national2$mean[1]/one_billion,decimal_places), 
            " (95% SI: ", round(results_national2$percentile_2_5[1]/one_billion,decimal_places), ", ", 
            round(results_national2$percentile_97_5[1]/one_billion, decimal_places),")",
            
            "\nLabour Costs: ", round(results_national2$mean[2]/one_billion, decimal_places), 
            " (95% SI: ", round(results_national2$percentile_2_5[2]/one_billion, decimal_places), ", ", 
            round(results_national2$percentile_97_5[2]/one_billion, decimal_places),")",
            
            "\nTotal Costs: ", round(results_national2$mean[6]/one_billion, decimal_places), 
            " (95% SI: ", round(results_national2$percentile_2_5[6]/one_billion, decimal_places), ", ", 
            round(results_national2$percentile_97_5[6]/one_billion, decimal_places),")",
            
            "\nIndividual Healthcare Costs: ", round(results_national2$mean[3],0), 
            " (95% SI: ", round(results_national2$percentile_2_5[3],0), ", ", 
            round(results_national2$percentile_97_5[3],0),")",
            
            "\nIndividual Labour Costs: ", round(results_national2$mean[4],0), 
            " (95% SI: ", round(results_national2$percentile_2_5[4],0), ", ", 
            round(results_national2$percentile_97_5[4],0),")",
            
            "\nIndividual Total Costs: ", round(results_national2$mean[5],0), 
            " (95% SI: ", round(results_national2$percentile_2_5[5],0), ", ", 
            round(results_national2$percentile_97_5[5],0),")","\n\n",
            "Ended Group: ", substr(group, 2, nchar(group) - 2), "\n\n",
            
            sep="")
      
      #####################################################
      #####################################################
      #####################################################
      ###       Outputting Results by Cost Category     ###
      ###                  and Province                 ###
      #####################################################
      #####################################################
      #####################################################
      Provincial_summary_fn(Provincial_df, Provinces)
    }
  }
    }
  })

print(start_time2)

# Stop redirecting output to the file
sink()

cat("###########################","\n",
    "###########################","\n",
    "CODE EXECUTED SUCCESSFULLY","\n",
    "###########################","\n",
    "###########################","\n", 
    sep=""
)


