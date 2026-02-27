#'@name 06_results_plots.R
#'@date 16.01.2026
#'@author Lisa Bald [bald@staff.uni-marburg.de]
#' @description 
#' Visualizes the Absolute Error (AE) between estimated performance
#' by evaluation metrics and true species distribution using 
#' faceted boxplots.

# ================================================================ #
# 1. Setup & data loading ----
# ================================================================ #

library(ggplot2)
library(tidyverse)
library(hrbrthemes)
library(parallel)
library(grid)
library(egg)
library(patchwork)

if (Sys.info()[[4]]=="PC19674") {
  nCores=1
} else if (Sys.info()[[4]]=="pc19543") {
  nCores=60
}


# Load functions
source(paste0("R/functions/scale_metric.R"))
source(paste0("R/functions/plotting_functions.R"))

# create a unique name for different runs
all_runs <- c("resultsMain", "resultsImbalanced", "resultsRealModels")

for (nameRun in all_runs) {
  
  message(paste("--- Processing Run:", nameRun, "---"))
  
  data <- readRDS(paste0("data/", nameRun, "/results.RDS"))
  
  # ================================================================ #
  # 2. Prepare data for plotting ----
  # ================================================================ #
  
  # metric scaling
  metric_names <- c("AUC", "COR", "Kappa",
                    "PCC", "TSS", "PRG", "trueCor")
  
  # Apply scaling function to each metric and create new "_scaled" columns
  data <- data %>%
    mutate(across(all_of(metric_names),
                  .fns = ~ scale_metric(., cur_column()),
                  .names = "{.col}_scaled"))
  
  # bring in right order:
  data$method <- factor(data$method, levels = c("PA", "PBG", "PAA"), ordered = TRUE)
  
  # ================================================================ #
  # 3. Calculate Absolute Error (AE) ----
  # ================================================================ #
  
  metric_names <- c( "AUC_scaled", 
                     "COR_scaled", 
                     "PRG_scaled",  
                     "TSS_scaled", 
                     "Kappa_scaled", 
                     "PCC_scaled")
  
  for(m in metric_names){
    data[[paste0("AE_",m)]] = abs(data[[m]]- data$trueCor_scaled)
  }
  
  # Labels for LaTeX-style plot titles
  plot_labels <- data.frame(
    metric = paste0("AE_", metric_names),
    label = c("AUC[ROC]", "'Pearson correlation'", "AUC[PRG]", "TSS", "'Cohen kappa'", "PCC")
  )
  
  # ================================================================ #
  # 4. Generate & Save Figures ----
  # ================================================================ #
  
  message("Generating Boxplots...")
  dir.create(paste0("images/", nameRun), recursive = TRUE, showWarnings = FALSE)
  
  # Main Overview Plot (All metrics)
  main_plots <- lapply(paste0("AE_", metric_names), function(m) create_ae_boxplot(data, m))
  
  p_main <- egg::ggarrange(plots = main_plots, ncol = 3, nrow = 2, 
                           left = textGrob("Absolute Error", gp = gpar(fontsize = 13), rot = 90))
  
  ggsave(p_main, filename = paste0("images/", nameRun, "/absolute_error_boxplot.png"), 
         width=8,height=8, dpi = 300)
  
  rm(p_main,m)
  # ================================================================ #
  # 5. SCATTERPLOTS: Estimated vs. True ----
  # ================================================================ #
  
  message("Generating Scatterplots...")
  
  all_scatters <- list()
  scatter_labels <- plot_labels %>% select(metric_names = metric, label)
  
  for (m in metric_names) {
    for (meth in c("PA", "PBG", "PAA")) {
      data_sub <- data %>% filter(method == meth)
      
      p <- create_scatter_plot(data=data_sub, m_scaled=m, method_name=meth, labels_df=scatter_labels)
      
      # Achsenbeschriftung nur für die linke Spalte (PA)
      if (meth != "PA") p <- p + theme(axis.title.y = element_blank(), 
                                       axis.text.y = element_blank())
      
      all_scatters[[paste0(m, "_", meth)]] <- p
    }
  }
  
  p_scat_final=egg::ggarrange(plots=all_scatters,
                              nrow=6,ncol=3, 
                              left=textGrob("Pearson correlation between probability of occurrence and artificial distribution map",
                                            gp = gpar(fontsize = 24),
                                            rot = 90))
  ggsave(p_scat_final, filename = paste0("images/",nameRun,"/scatterplot.png"), dpi = 300, width = 16, height = 25)
  
  
  # ================================================================ #
  # 6. Tolerance plots: Density & 95% Limits ----
  # ================================================================ #
  
  message("Generating Tolerance Density Plots...")
  
  # Define the AE metrics to plot (matching your boxplot list)
  ae_metric_names <- paste0("AE_", metric_names)
  
  # Use the function to create a list of plots
  tol_plots <- lapply(ae_metric_names, function(m) {
    create_tolerance_plot(data, m, plot_labels)
  })
  
  # Wrap your plots together and use 'guides = "collect"'
  p <- patchwork::wrap_plots(tol_plots, ncol = 3) + 
    plot_layout(guides = "collect")
  
  ggsave(p, filename = paste0("images/",nameRun,"/tolerance_limits.png"), 
         width = 8, height = 8, dpi = 300)
  
  
  message(paste("Done:", nameRun))
  
}

