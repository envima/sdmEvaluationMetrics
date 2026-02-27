#'@name 07_presence_only_plots.R
#'@date 16.01.2026
#'@author Lisa Bald [bald@staff.uni-marburg.de]
#' @description 
#' Visualizes the results of presence-only metrics.

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

nameRun <- "resultsMain"
data <- readRDS(paste0("data/", nameRun, "/results.RDS"))

# ================================================================ #
# 2. Prepare data for plotting ----
# ================================================================ #

# metric scaling
metric_names <- c("SEDI", "SBI_m", "trueCor")

# Apply scaling function to each metric and create new "_scaled" columns
data <- data %>%
  mutate(across(all_of(metric_names),
                .fns = ~ scale_metric(., cur_column()),
                .names = "{.col}_scaled"))

data <- data %>%
  mutate(omissionRate=1-omissionRate#,
         #SEDI_scaled= 1-SEDI_scaled
         )

# bring in right order:
data$method <- factor(data$method, levels = c("PA", "PBG", "PAA"), ordered = TRUE)

# ================================================================ #
# 3. Calculate Absolute Error (AE) ----
# ================================================================ #

metric_names <- c("SEDI_scaled", 
                  "SBI_m_scaled",
                  "omissionRate" )


for(m in metric_names){
  data[[paste0("AE_",m)]] = abs(data[[m]]- data$trueCor_scaled)
}

# Labels for LaTeX-style plot titles
plot_labels <- data.frame(
  metric = paste0("AE_", metric_names),
  label = c("SEDI", "'Smoothed boyce index mean'", "'Omission rate'")
)

# ================================================================ #
# 4. Generate & Save Figures ----
# ================================================================ #

dir.create(paste0("images/", nameRun), recursive = TRUE, showWarnings = FALSE)

all_scatters <- list()
scatter_labels <- plot_labels %>% select(metric_names = metric, label)

for (m in metric_names) {
  
  data_sub <- data %>% filter(method == "PA")
  
  p <- create_scatter_plot(data=data_sub, m_scaled=m, method_name="PO", labels_df=scatter_labels)
  
  # Achsenbeschriftung nur für die linke Spalte (PA)
  if (m != "SEDI_scaled") p <- p + theme(axis.title.y = element_blank(), 
                                   axis.text.y = element_blank())
  
  all_scatters[[m]] <- p
  
}

p_scat_final=egg::ggarrange(plots=all_scatters,
                            ncol=3, 
                            left=textGrob("Pearson correlation between\nprobability of occurrence and\nartificial distribution map",
                                          gp = gpar(fontsize = 24),
                                          rot = 90))
ggsave(p_scat_final, filename = paste0("images/",nameRun,"/po_scatterplot.png"), dpi = 300, width = 16, height = 5)
