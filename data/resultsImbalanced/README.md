# README – Evaluation metrics calculated on imbalanced data

## Overview

This folder contains the secondary data output for this study. These results focus on the performance of evaluation metrics using imbalanced test datasets across three data types: **Presence-Absence (PA)**, **Presence-Background (PBG)**, and **Presence-Artificial-Absence (PAA)**. 

The dataset is designed to show the influence of calcualting evaluation metrics on imbalanced datasets. Evaluation metrics are calculated on the artificial distribution maps in `data/resultsMain/maps/`.

## Directory Structure

The directory is organized as follows:

```
resultsImbalanced/
├── results/         # Individual evaluation metric files (.RDS) 
├── `results.RDS`    # Compiled dataset of all evaluation metrics (from results folder) 
```

See the README files of the subdirectories for more information.

## File Descriptions

### `results.RDS`

The code used to create the results.RDS file is available in script `R/05_calculation_evaluation_metrics.R`. A dataframe in .RDS format with the following columns:

**Attributes**:

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

