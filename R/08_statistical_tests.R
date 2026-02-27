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

# Metric definitions
metric_names <- c("AUC", "COR", "Kappa","PCC", "TSS", "PRG", "trueCor")

# ================================================================ #
# 2. Main Processing Loop ----
# ================================================================ #

for (nameRun in all_runs) {
  
  message(paste("\n>>> Starting Statistics for Run:", nameRun))
  
  input_path <- paste0("data/", nameRun, "/results.RDS")
  if(!file.exists(input_path)) next
  
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
  data$ID <- paste(data$species, data$size, data$testData, data$points, data$replicate, sep = "_")
  
  # Keep only complete blocks (IDs that have all 3 methods)
  df_clean <- data %>%
    group_by(ID) %>%
    filter(n() == 3) %>%
    ungroup()
  
  # Directories
  stats_dir <- paste0("images/", nameRun, "/statistics/")
  dir.create(stats_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Initialize Result Table
  resultsDF <- data.frame(
    metric          = paste0("AE_", metric_names,"_scaled"),
    Friedman_p      = NA,
    Nemenyi_CD      = NA,
    Mean_Rank_PA    = NA,
    Mean_Rank_PBG   = NA,
    Mean_Rank_PAA   = NA,
    Wilcox_p_AA_BG  = NA,
    Effect_Size_r   = NA,
    Improv_PAA_vs_PBG_pct = NA
  )
  
  # ================================================================ #
  # 3. Statistical Analysis per Metric ----
  # ================================================================ #
  
  metric_names <- c( "AUC_scaled", 
                     "COR_scaled", 
                     "PRG_scaled",  
                     "TSS_scaled", 
                     "Kappa_scaled", 
                     "PCC_scaled")
  
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
    nem_test <- scmamp::nemenyiTest(df_wide, alpha = 0.05)
    resultsDF[resultsDF$metric == m, ]$Nemenyi_CD <- nem_test$statistic
    
    # Save CD Plot
    png(paste0(stats_dir, "CD_Plot_", m, ".png"), width = 800, height = 400)
    plotCD(df_wide, alpha = 0.05, cex = 1.25)
    dev.off()
    
    # --- 3c. Ranks and Medians ---
    ranks <- colMeans(apply(df_wide, 1, rank)) # Lower is better for AE
    resultsDF[resultsDF$metric == m, ]$Mean_Rank_PA  <- ranks["PA"]
    resultsDF[resultsDF$metric == m, ]$Mean_Rank_PBG <- ranks["PBG"]
    resultsDF[resultsDF$metric == m, ]$Mean_Rank_PAA <- ranks["PAA"]
    
    mae_pbg <- median(df_wide$PBG, na.rm = TRUE)
    mae_paa <- median(df_wide$PAA, na.rm = TRUE)
    resultsDF[resultsDF$metric == m, ]$Improv_PAA_vs_PBG_pct <- (mae_pbg - mae_paa) / mae_pbg * 100
    
    # --- 3d. Paired Wilcoxon Test (PAA vs PBG) ---
    wilcox_res <- wilcox.test(df_wide$PAA, df_wide$PBG, paired = TRUE)
    resultsDF[resultsDF$metric == m, ]$Wilcox_p_AA_BG <- wilcox_res$p.value
    
    # Effect Size calculation using coin package
    # We use wide format converted back to long for coin's formula interface
    df_long_sub <- df_clean %>% 
      filter(method %in% c("PAA", "PBG")) %>%
      mutate(method = factor(method))
    
    wilcox_coin <- coin::wilcoxsign_test(as.formula(paste(m, "~ method")), data = df_long_sub)
    z_stat <- statistic(wilcox_coin)
    resultsDF[resultsDF$metric == m, ]$Effect_Size_r <- abs(z_stat) / sqrt(nrow(df_wide) * 2)
  }
  
  # Save final table
  write.csv(resultsDF, paste0(stats_dir, "Statistical_Results_Summary.csv"), row.names = FALSE)
  message(paste(">>> Statistics saved for", nameRun))
}