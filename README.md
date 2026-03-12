# 🗺️ 📉 The accuracy of evaluation metrics in presence-only species distribution modelling.

[![R-Version](https://img.shields.io/badge/R-4.4.2-%23276DC3.svg?logo=r&logoColor=white)](https://www.r-project.org/)
[![Status](https://img.shields.io/badge/Status-Project%20Complete-green.svg)](#)

## Abstract

Species distribution modeling is one of the most popular tools in ecology and nature conservation, promising researchers and stakeholders rapid solutions that facilitate remote decision-making with minimal field-based effort. While presence-only data are the most common data used in species distribution modelling, the evaluation metrics calculated from them are biased to an unknown extent. Consequently, decisions are based on evaluation metrics whose actual accuracy are unknown, which creates a significant risk of issuing wrong scientific guidelines or misallocating conservation resources. To quantify this uncertainty, we utilized virtual species to generate over 8,000 species distribution maps, enabling a direct comparison between commonly used evaluation metrics and the true probability of occurrence. We assessed metrics calculated from three data types: presence-only, presence-background (sampled randomly), and presence-artificial-absence (sampled from environmentally distant regions). Our findings provide two reference points for the field: (1) evaluation metrics calculated using presence-artificial-absence data provide the best estimate of performance currently available, with median absolute errors between 0.10-0.18, compared to 0.14-0.29 for presence-background and 0.25-0.44 for presence-only data. (2) Without true absence data, evaluation metrics typically deviate from actual model performance by 39% to 42%, depending on the specific context, this error range likely renders conclusion unreliable. Acknowledging these errors is essential when interpreting evaluation metrics calculated without true absence data; thus, our findings provide a critical baseline for the contextualization of evaluation metrics in both research and conservation.

---

## Workflow

This repository holds all code for the study **"The accuracy of evaluation metrics in presence-only species distribution modelling."** for full reporducability. 

![](/images/Experimental_design.png)
**Figure : Workflow and experimental design.** The figure is structured in three columns: **Visualization (left column)**: Example maps and diagrams to illustrate each stage of the workflow. **Workflow (middle column)**: Flowchart with decision nodes represented by gears indicates the choices that must be made by the modeler at each stage. Each choice influences the subsequent analyses. **Experiments (right column)**: Summarizes the test parameters and the number of experiments conducted at each stage. The cumulative number of experiments increases across steps, resulting in a total of 9,000 experiments. The workflow progresses through four main stages: (i) **Species simulation**: Four bioclimatic variables (bio1, bio3, bio7, bio12) were used to generate 10 virtual species following Grimmett et al. (2020). Probability-of-occurrence maps were created and transformed into presence-absence rasters. (ii) **Sampling**: From the presence-absence rasters, occurrence points were sampled randomly at six different sample sizes (40, 80, 120, 160, 200, and 400 points). (iii) **Preprocessing**: Sampled points were partitioned into folds using five different fold-separation strategies: random partitioning, k-nearest neighbor distance matching (KNNDM), spatial blocking with hexagonal blocks (block1), spatial blocking with square tiles (block2), and environmental clustering. Each strategy generated six folds, with one fold withheld as test data in each iteration. Stages ii and iii were replicated 5 times. (iv) Evaluation: Artificial distribution maps were created by combining the true probability of occurrence with gaussian random fields (green). Evaluation metrics were calculated for each test dataset (purple; see Figure 2). Pearson's correlation between probability of occurrence and artificial distribution maps were calculated to assess true performance.

## Key results

![](/images/resultsMain/absolute_error_boxplot.png)
**Figure: Absolute errors of evaluation metrics.** Comparison of absolute errors calculated on presence-absence (PA; blue), presence-background (PBG; purple), and presence-artificial-absence (PAA; green) across six evaluation metrics (AUCROC, Pearson's correlation, AUCPRG, TSS, Cohen’s kappa and PCC). Each boxplot is based on 8,335 data points. Outliers in grey. Low absolute error indicates good assessment of the artificial distribution maps by the evaluation metric. Median absolute error is indicated in the boxplot.


![](/images/resultsMain/tolerance_limits.png)
**Figure: Density distributions and 95% tolerance limits of absolute errors for evaluation metrics.** The plots compare evaluation metrics calculated with three datasets: presence-absence (PA; blue), presence-background (PBG; purple), and presence-artificial-absence (PAA; green). Dashed vertical lines indicate the upper-bound tolerance limits, representing the threshold below which 95% of absolute errors fall with 95% confidence. 

---



## 📂 Repository Structure

```text
sdmEvaluationMetrics/
├── data/
│   ├── climate/               # Bioclimatic variables (Predictors)
│   ├── folds/                 #
│   ├── gadm/                  #
│   ├── PA/                    #
│   ├── paRaster/              # 
│   ├── resultsImbalanced/     # Evaluation results for datasets with skewed prevalence
│   ├── resultsMain/           # Benchmarking results using calibrated artificial maps
│   ├── resultsRealModels/     # Outputs from machine learning algorithms (RF, BRT, etc.)
│   ├── virtualSpecies/        # Ground-truth suitability and occurrence data
│   └── virtualSpeciesTrain/   #
├── R
├── images/                    # Figures and diagrams for the README
├── .gitignore                 # Rules to prevent uploading large data files (>50GB)
├── LICENSE                    # Repository license
└── README.md                  # Main project documentation
```
---

## ⚠️ Important Note on Data Size

The full study generates approximately **300GB** of data. To maintain repository functionality, **only a few example files are included in the repository**.

To reproduce the full dataset, please run the scripts in the `R/` folder sequentially.


## 📚 Key References

