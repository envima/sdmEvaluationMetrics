# README – Result files

## Overview

This folder contains 8,335 `.RDS` files. Each file is a serialized R data frame representing the performance evaluation of one artificial distirbution map with several evaluation metrics.

## File Structure

Each `.RDS` file contains a data frame with **3 observations** (rows) and **29 variables** (columns). The three rows represent the evaluation results for different data types used for model evaluation:
* **PA**: Presence-Absence (based on original sampled points).
* **PAA**: Presence-Artificial-Absence (sampled from environmentally distant regions).
* **PBG**: Presence-Background (sampled randomly over the study area).

### Detailed Descriptions

Each `.RDS` file contains a table with the following columns:

| Column Name | Description |
| :--- | :--- |
| **Fbp** | F-measure for presence-background data (Li & Guo, 2013) |
| **omissionRate** | The proportion of true presence points incorrectly predicted |
| **SBI_tp** | Smoothed Boyce Index thin plate regression splines (Liu et al. 2024)|
| **SBI_cr** | Smoothed Boyce Index cubic regression splines (Liu et al. 2024) |
| **SBI_bs** | Smoothed Boyce Index B-splines (Liu et al. 2024) |
| **SBI_ps** | Smoothed Boyce Index P-splines (Liu et al. 2024) |
| **SBI_ad** | Smoothed Boyce Index adaptive smoothers (Liu et al. 2024) |
| **SBI_m** |  Smoothed Boyce Index the mean of the predictions from the above five spline models (Liu et al. 2024) |
| **SEDI** | Symmetric Extremal Dependence Index (Wunderlich et al. 2019) |
| **ORSS** | Odds Ratio Skill Score  (Wunderlich et al. 2019) |
| **AUC** | Area Under the Receiver Operating Characteristic Curve |
| **COR** | Pearson's correlation |
| **Spec** | Specificity |
| **Sens** | Sensitivity |
| **Kappa** | Cohen’s Kappa |
| **PCC** | Percent Correct Classification|
| **TSS** | True Skill Statistic (Allouche et al. 2006) |
| **PRG** | Area Under the Precision-Recall Gain Curve |
| **MAE** | Mean Absolute Error |
| **BIAS** | Bias |
| **noPresencePoints** | The total number of presence points available in the specific test fold. |
| **trueCor** | Pearson correlation between the artificial distirbution map and the virtual species probability of occurrence |
| **model** | The modeling algorithm used (e.g., `NA` for artificial distirbution maps) |
| **size** | The data partitioning/fold strategy used (e.g., `block1`, `KNNDM`) |
| **testData** | The identifier for the specific spatial fold used as the test set. |
| **method** | The evaluation data type used (`PA` = Presence-Absence, `PAA` = Presence-Artificial-Absence, `PBG` = Presence-Background) |
| **replicate** | The iteration number of the random sampling process |
| **points** | The total number of points originally sampled |
| **species** | The identifier for the virtual species (VS01–VS10) |


## Naming Convention

Files follow a standardized naming convention to identify the specific simulation parameters. The structure is:

`VSXX_FOLDS_MODEL_testDataD_pointsYYY_replicatesZZ.RDS`

### Parameter Reference Table

| Component | Example | Description |
| :--- | :--- | :--- |
| **VSXX** | `VS01` | **Virtual Species ID**: Identifier for the species (VS01–VS10). |
| **FOLDS** | `block1` | **Partitioning Strategy**: The CV method used (`KNNDM`, `random`, `block1`, `block2`, `clusters`). |
| **MODEL** | `NA` | **Model Type**: Placeholder for the algorithm. `NA` indicates a artificial map. |
| **testDataD** | `testData1` | **Test Fold**: The specific fold ID (1–6) used as the independent testing set. |
| **pointsYYY** | `points40` | **Sample Size**: The number of presence points sampled. |
| **replicatesZZ** | `replicates1` | **Replicate**: The iteration number (1–5). |


## Data Generation

The evaluation metrics were calculated using the script `R/05_calculation_evaluation_metrics.R`. This script compares the spatial predictions in the `/maps` folder against the virtual species' true occurrence probability.

## References

Allouche, O., Tsoar, A., & Kadmon, R. (2006). Assessing the accuracy of species distribution models: Prevalence, kappa and the true skill statistic (TSS). Journal of Applied Ecology, 43(6), 1223–1232. https://doi.org/10.1111/j.1365-2664.2006.01214.x

Li, W., & Guo, Q. (2013). How to assess the prediction accuracy of species presence–absence models without absence data? Ecography, 36(7), 788–799. https://doi.org/10.1111/j.1600-0587.2013.07585.x 

Liu, C., Newell, G., White, M., & Machunter, J. (2024). Improving the estimation of the Boyce index using statistical smoothing methods for evaluating species distribution models with presence-only data. Ecography, 2025(1), e07218. https://doi.org/10.1111/ecog.07218 

Wunderlich, R. F., Lin, Y.-P., Anthony, J., & Petway, J. R. (2019). Two alternative evaluation metrics to replace the true skill statistic in the assessment of species distribution models. Nature Conservation, 35, 97–116. https://doi.org/10.3897/natureconservation.35.33918 


**Software used:**
poEvaluationMetrics 0.0.0.9000 
climateStability 0.1.4
terra 1.8-60                  
sf 1.0-21
dplyr 1.1.4  