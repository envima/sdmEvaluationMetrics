# README – R Scripts

## Overview

This directory contains the complete analytical pipeline for this study.

## Workflow

### 1. Species and Data Preparation
* `01_virtual_species.R`: 
    * Utilizes the `virtualspecies` package to generate suitability rasters for **VS01–VS10**.
    * Samples presence-absence data points based on the underlying suitability.
* `02_data_partition.R`: 
    * Implements (spatial) cross-validation strategies to ensure independence between training and testing data.
    * Strategies include KNNDM (Nearest Neighbor Distance Matching), Random, Spatial Blocks (Square/Hexagonal), and Environmental Clusters.

### 2. Distribution Map Generation & Modeling
* `03_artificial_distribution_maps.R`: 
    * Generates artificial distribution maps. 
    * Blends ture probability of occurrence with Gaussian Random Fields to create maps with a pre-defined correlation.
* `002_modeling.R`: 
    * Actual modeling of species distributions. Trains and projects models using algorithms such as BRT, RF, GAM, Lasso, and Maxent.

### 3. Evaluation and Statistics
* `05_calculation_evaluation_metrics.R`: 
    * Calculates evaluation metrics for every distirbution maps (artificial or real distirbution maps).
    * Compares predictions against the probability of occurrence to derive real performance.
	* Estimates evaluation metrics for: 
		* PA (Presence-Absence)
		* PBG (Presence-Backgorund)
		* PAA (Presence-Artificial-Absence)
	on balanced (same number of presence and absence/background/artificial-absence points) or imbalanced datasets (more background/artificial-absence points than presence points)	
* `06_results_plots.R`:
	* Boxplots of absolute errors between scaled evaluation metrics and true probability of occurrence.
	* Scatterplots between scaled evaluation metrics and true probability of occurrence.
	* Density plots with tolerance limits.
* `07_presence_only_plots.R`:
	* Plots for presence-only performance metrics.
* `08_statistical_tests.R`: 
    * Final statistical analysis.
    * Executes Friedman Aligned Ranks, Nemenyi tests and Wilcoxon test to determine significant differences between PA, PBG and PAA.

---

## Helper Functions (`R/functions/`)

To maintain modularity, common tasks are stored as standalone functions:

| Function Script | Description |
| :--- | :--- |
| `brtModelTraining.R` |  Trains a Gradient Boosted Machine (GBM) model. |
| `gamModelTraining.R` | Fits a GAM with spline terms. |
| `lassoModelTraining.R` | Lasso penalty GLM. Quadratic feature expansion is performed on all predictor variables. |
| `maxentModelTraining.R` | Trains a Maxent model. |
| `plotting_functions.R` | Creates a standardized ggplot2. |
| `rfModelTraining.R` |  Random forest downwsampled, same amount of background points as presence points are used. |
| `scale_metric.R` | Normalizes metrics with different bounds (e.g., AUC 0-1, TSS -1–1) to a unified [0,1] range. |
| `trainSpeciesDistributionModel.R` | Wrapper around the individual functions for model training (BRT, GAM, Lasso, Maxent, RF). |


### Parallelization Note
Most scripts utilize `parallel::mclapply`. Note that `mclapply` is primarily designed for Unix-based systems (Linux/macOS). If running on Windows, the `nCores` variable should be set to `1` or adapted using the `future` package. The functions of the NLMR package to create the artificial distribution maps cannot be run in parallel, therefore the execution takes quite some time.