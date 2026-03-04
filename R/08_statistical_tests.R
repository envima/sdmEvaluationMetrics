#' @name 08_statistical_tests.R
#' @author Lisa Bald [bald@staff.uni-marburg.de]
#' @description 
#' Performs Friedman Aligned Ranks, Nemenyi Post-hoc, and paired Wilcoxon tests 
#' to compare method performance (PA, PBG, PAA) across multiple metrics.

# ================================================================ #
# 1. Setup ----
# ================================================================ #

library(tidyverse)
library(scmamp)  # For Friedman and Nemenyi
library(coin)    # For effect size
library(grid)

# Define project runs
all_runs <- c("resultsMain", "resultsImbalanced", "resultsRealModels")

# Source scaling function
source("R/functions/scale_metric.R")

# ================================================================ #
# 2. Main Processing Loop ----
# ================================================================ #

for (nameRun in all_runs) {
  
  message(paste("\n>>> Starting Statistics for Run:", nameRun))
  
  input_path <- paste0("data/", nameRun, "/results.RDS")
  if(!file.exists(input_path)) next
  
  # Metric definitions
  metric_names <- c("AUC", "COR", "Kappa","PCC", "TSS", "PRG", "trueCor")
  
  data <- readRDS(input_path)
  
  # --- 2a. Data Preparation ---
  # Apply scaling function to each metric and create new "_scaled" columns
  data <- data %>%
    mutate(across(all_of(metric_names),
                  .fns = ~ scale_metric(., cur_column()),
                  .names = "{.col}_scaled"))
  
  # Calculate Absolute Error
  for(m in metric_names){
    data[[paste0("AE_", m,"_scaled")]] <- abs(data[[paste0(m,"_scaled")]] - data$trueCor_scaled)
  }
  
  # Add ID for paired testing (ensures we compare same species/replicate across methods)
  data$ID <- paste(data$species, data$model, data$size, data$testData, data$points, data$replicate, sep = "_")
  
  # Keep only complete blocks (IDs that have all 3 methods)
  df_clean <- data %>%
    group_by(ID) %>%
    filter(n() == 3) %>%
    ungroup()
  
  # Directories
  stats_dir <- paste0("images/", nameRun, "/statistics/")
  dir.create(stats_dir, recursive = TRUE, showWarnings = FALSE)
  
  # ================================================================ #
  # 3. Statistical Analysis per Metric ----
  # ================================================================ #
  
  metric_names <- c( "AUC_scaled", 
                     "COR_scaled", 
                     "PRG_scaled",  
                     "TSS_scaled", 
                     "Kappa_scaled", 
                     "PCC_scaled")
  
  # Initialize Result Table
  resultsDF <- data.frame(
    metric          = paste0("AE_", metric_names),
    Friedman_p      = NA,
    Nemenyi_CD      = NA,
    Mean_Rank_PA    = NA,
    Mean_Rank_PBG   = NA,
    Mean_Rank_PAA   = NA,
    Wilcox_p_AA_BG  = NA,
    Effect_Size_r   = NA,
    Improv_PAA_vs_PBG_pct = NA,
    Non_Significant_Pairs=NA
  )
  
  
  for (m in paste0("AE_", metric_names)) {
    
    message(paste("Analyzing metric:", m))
    
    # Create wide format for scmamp and Wilcox tests
    df_wide <- df_clean %>%
      select(ID, method, !!sym(m)) %>%
      pivot_wider(names_from = method, values_from = !!sym(m)) %>%
      column_to_rownames("ID")
    
    # --- 3a. Friedman Aligned Ranks Test ---
    fried_test <- scmamp::friedmanAlignedRanksTest(df_wide)
    resultsDF[resultsDF$metric == m, ]$Friedman_p <- fried_test$p.value
    
    # --- 3b. Nemenyi Post-hoc Test & CD Plot ---
    
    # In @demsar2006 the author proposes the use of the Nemenyi test that compares all the algorithms pairwise. 
    # It is the non parametric equivalent to the Tukey _post hoc_ test for ANOVA (which is also available through the `tukeyPost` function), 
    # and is based on the absolute difference of the average rankings of the classifiers. For a significance level $\alpha$ the test determines the critical difference (CD); 
    # if the difference between the average ranking of two algorithms is grater than CD, then the null hypothesis that the algorithms have the same performance is rejected. 
    # The function `nemenyiTest` computes the critical difference and all the pairwise differences.
    
    nem_test <- scmamp::nemenyiTest(df_wide, alpha = 0.05)
    resultsDF[resultsDF$metric == m, ]$Nemenyi_CD <- nem_test$statistic
    
    # Save CD Plot
    png(paste0(stats_dir, "CD_Plot_", m, ".png"), width = 800, height = 400)
    plotCD(df_wide, alpha = 0.05, cex = 1.25)
    dev.off()
    
    
    #print( nem_test$diff.matrix)
    #print(abs( nem_test$diff.matrix) >  nem_test$statistic)
    
    # --- AUTOMATED CHECK ---
    check_mat <- abs(nem_test$diff.matrix) > nem_test$statistic
    
    # Identify indices where it's FALSE (not significant) and NOT on the diagonal
    # which(..., arr.ind = TRUE) gives us a matrix of row/column positions
    non_sig_indices <- which(!check_mat & row(check_mat) != col(check_mat), arr.ind = TRUE)
    
    if(nrow(non_sig_indices) > 0) {
      # Get the actual names (PA, PAA, PBG) from the matrix dimensions
      method_names <- colnames(check_mat)
      
      # Create strings like "PA-PBG"
      pairs <- apply(non_sig_indices, 1, function(x) {
        paste(sort(method_names[x]), collapse = "-")
      })
      resultsDF[resultsDF$metric == m, ]$Non_Significant_Pairs <- paste(unique(pairs), collapse = ", ")
    } else {
      resultsDF[resultsDF$metric == m, ]$Non_Significant_Pairs <- "NA"
    }
      
    # --- 3c. Ranks and Medians ---
    # Calculate average rank (Lower is better for Error)
    ranks <- aggregate(rank(data[[m]]) ~ method, 
                       data = data, 
                       FUN = mean)
    
    colnames(ranks) <- c("Method", "Mean_Rank")
    resultsDF[resultsDF$metric == m, ]$Mean_Rank_PA  <- ranks[ranks$Method == "PA",]$Mean_Rank
    resultsDF[resultsDF$metric == m, ]$Mean_Rank_PBG <- ranks[ranks$Method == "PBG",]$Mean_Rank
    resultsDF[resultsDF$metric == m, ]$Mean_Rank_PAA <- ranks[ranks$Method == "PAA",]$Mean_Rank
    
    mae_pbg <- median(df_wide$PBG, na.rm = TRUE)
    mae_paa <- median(df_wide$PAA, na.rm = TRUE)
    resultsDF[resultsDF$metric == m, ]$Improv_PAA_vs_PBG_pct <- (mae_pbg - mae_paa) / mae_pbg * 100
    
    # --- 3d. Paired Wilcoxon Test (PAA vs PBG) ---
    wilcox_res <- wilcox.test(df_wide$PAA, df_wide$PBG, paired = TRUE)
    resultsDF[resultsDF$metric == m, ]$Wilcox_p_AA_BG <- wilcox_res$p.value
    
    # Effect Size calculation using coin package
    # Calculating the Effect Size r With 16,000 points, even an unimportant difference 
    # can be "statistically significant." To see if the difference is meaningful, we calculate 
    # the effect size
    #r = \frac{|Z|}{\sqrt{N}}
    
    wilcox_coin <- coin:: wilcoxsign_test(PAA ~ PBG, data = df_wide)
    z_stat <- statistic(wilcox_coin)
    resultsDF[resultsDF$metric == m, ]$Effect_Size_r <- abs(z_stat) / sqrt(nrow(df_wide))
    rm(df_wide, fried_test, nem_test, ranks, wilcox_coin, wilcox_res, mae_paa, mae_pbg,z_stat)
  }
  
  # Save final table
  write.csv(resultsDF, paste0(stats_dir, "Statistical_Results_Summary.csv"), row.names = FALSE)
  message(paste(">>> Statistics saved for", nameRun))
  rm(data, df_clean, input_path, stats_dir,resultsDF)
}

