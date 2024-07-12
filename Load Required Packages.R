# Load necessary packages
required_packages <- c(
  "extraDistr",
  "trapezoid",
  "weights",
  "survey",
  "tidyr",
  "dplyr",
  "forestplot"
)

# Install and load missing packages
install_missing_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if (length(install_missing_packages) > 0) {
  install.packages(install_missing_packages, dependencies = TRUE)
}

# Load necessary packages quietly
loaded_packages <- suppressMessages(
  lapply(required_packages, library, character.only = TRUE)
)

# Output the number of packages loaded
cat("Number of packages loaded:", length(loaded_packages), "\n")

# Function to generate random integer income samples within specified income bands
generate_income <- function(n_samples = 10000, income_dict) {
  # Extract range and probabilities from the income dictionary
  ranges <- lapply(income_dict, function(x) x$range)
  probabilities <- sapply(income_dict, function(x) x$prob)
  
  # Generate random indices based on probabilities
  indices <- sample(seq_along(ranges), size = n_samples, replace = TRUE, prob = probabilities)
  
  # Generate random income values based on selected indices
  incomes <- mapply(function(idx) {
    range <- ranges[[idx]]
    runif(1, min = range[1], max = range[2])
  }, indices)
  
  # Compute the average income
  average_income <- round(mean(incomes),0)
  #median_income <- round(median(incomes),0)
  #return(c(average_income, median_income))
  return(average_income)
}

# Function to generate a random number from a uniform distribution
# A - lower bound, B - upper bound
generate_uniform <- function(L_bound, U_bound, n_samples =1) {
  random_samples = runif(n_samples, min = L_bound, max = U_bound)
  
  # Return the random samples and their mean as a list for further use or inspection
  return(list(mean = mean(random_samples)))
}

# Function to generate a random number from a normal distribution
# mu - mean, standard_deviation - standard deviation
generate_normal <- function(mu, standard_deviation, n_samples =1) {
  random_samples <- rnorm(n_samples, mean = mu, sd = standard_deviation)
    
  # Return the random samples and their mean as a list for further use or inspection
  return(list(mean = mean(random_samples)))
}

# reusable trapezoidal function 
generate_trapezoidal <- function(L_bound, L_mode, U_mode, U_bound, n_samples =1) {
  # Generate random numbers
  random_samples <- rtrapezoid(
    n = n_samples, 
    min = L_bound, 
    mode1 = L_mode, 
    mode2 = U_mode, 
    max = U_bound
  )
 
  # Return the random samples and their mean as a list for further use or inspection
  return(list(mean = mean(random_samples))) #samples = random_samples, 
}


# Define a function that calculates the mean and percentiles and returns a tidy format
calculate_stats <- function(x, name) {
  tibble(
    variable = name,
    mean = mean(x, na.rm = TRUE),
    percentile_2_5 = quantile(x, probs = 0.025, na.rm = TRUE),
    percentile_97_5 = quantile(x, probs = 0.975, na.rm = TRUE)
  )
}

Provincial_summary <- function(dataframe) {
  summary <- bind_rows(
    calculate_stats(dataframe$Province_PCC_case, "PCC Cases"),
    calculate_stats(dataframe$Province_ED_visits, "ED Visits"),
    calculate_stats(dataframe$Province_Inpatient_stays, "Inpatient Hospitalizations"),
    calculate_stats(dataframe$Province_Outpatient_GP_visits, "Outpatient GP Visits"),
    calculate_stats(dataframe$Province_Specialist_visits, "Specialist Visits"),
    calculate_stats(dataframe$Province_Missed_SchoolWork, "Missed School/Work"),
    calculate_stats(dataframe$Province_Productivity_Loss, "Productivity Loss"),
    calculate_stats(dataframe$Province_Total, "National Total")
    )
  return(summary) 
}

Provincial_summary_fn <- function(Provincial_df, Provinces) {
  for (Province_i in Provinces) {
    print(paste0("Province: ", Province_i))
    provincial_data <- subset(Provincial_df, Province %in% c(Province_i))
    print(Provincial_summary(provincial_data))
    print(" ")
    print(" ")
  }
}